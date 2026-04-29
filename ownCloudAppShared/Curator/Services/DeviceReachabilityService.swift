import Foundation
import Network
import Combine
import ownCloudSDK
import UIKit

public final actor DeviceReachabilityService {
	public let urlProvider: DeviceReachabilityURLProvider

	/// Owns the remote/local/probes/static state and all path-selection logic. The service
	/// is reachability-aware (it knows the current `wifiAvailable` flag) and threads that
	/// flag into every catalog call.
	private let catalog: DeviceCatalog
	/// Algorithm A pipeline (full reload + reprobe + recalc + availability + mDNS).
	/// Wraps `DirectPathResolver` (Algorithm B) and exposes it via
	/// `attemptDirectResolution(...)`. The facade delegates all probing/discovery
	/// work to this pipeline.
	private let pipeline: DetectionPipeline
	/// Algorithm D — the network-change FSM, foreground gate, cooldown timer and
	/// `detectionsInFlight` reference count. The facade forwards reachability and
	/// app-lifecycle events to it via `coordinator.handle(_:)`.
	private let coordinator: NetworkChangeCoordinator
	/// Backing subject for `events`. `PassthroughSubject` is thread-safe, so we expose it
	/// `nonisolated` and call `send(_:)` directly from any context (actor-isolated or not).
	private nonisolated let eventsSubject = PassthroughSubject<DeviceReachabilityEvent, Never>()

	/// Single typed event channel — see `DeviceReachabilityEvent`. Subscribers should
	/// `.receive(on:)` their preferred queue before touching UI.
	public nonisolated var events: AnyPublisher<DeviceReachabilityEvent, Never> {
		eventsSubject.eraseToAnyPublisher()
	}

	private nonisolated func emit(_ event: DeviceReachabilityEvent) {
		eventsSubject.send(event)
	}
	private var triggersCancellable: AnyCancellable?
	private var reachabilityStatusCancellable: AnyCancellable?
	private var networkChangeCancellable: AnyCancellable?
	private var foregroundCancellable: AnyCancellable?
	private var staticDeviceAddressCancellable: AnyCancellable?
	/// Spec: connection paths cached with a timestamp; expire after 1 hour.
	/// Owned by `PathCacheStore`; persistence (1h TTL → `HCPreferences`) lives there.
	private let pathCacheStore: PathCacheStore
	/// Throttles automatic reprobe (timeout, cannot connect, status.php poll failures, …).
	private var lastTimeoutSwitchAttemptAt: Date?
	private let timeoutSwitchThrottleSeconds: TimeInterval = 60

	private let reachability: ReachabilityObserving
	private let remoteAccessService: RemoteAccessService
	private let mdnsService: MDNSService
	private let preferences: HCPreferences
	private let availabilityMonitor: NetworkAvailabilityMonitor

	public init(
		reachability: ReachabilityObserving,
		remoteAccessService: RemoteAccessService,
		mdnsService: MDNSService,
		preferences: HCPreferences,
		availabilityMonitor: NetworkAvailabilityMonitor = .shared,
		pathProber: PathProber = PathProber()
	) {
		self.reachability = reachability
		self.remoteAccessService = remoteAccessService
		self.mdnsService = mdnsService
		self.preferences = preferences
		self.availabilityMonitor = availabilityMonitor
		let pathCacheStore = PathCacheStore(preferences: preferences)
		let catalog = DeviceCatalog()
		self.pathCacheStore = pathCacheStore
		self.catalog = catalog

		urlProvider = DeviceReachabilityURLProvider(preferences: preferences)

		// `eventsSubject` is `nonisolated` so it is safe to reach from any context.
		let subject = self.eventsSubject
		let pipeline = DetectionPipeline(
			pathProber: pathProber,
			pathCacheStore: pathCacheStore,
			catalog: catalog,
			urlProvider: urlProvider,
			mdnsService: mdnsService,
			remoteAccessService: remoteAccessService,
			preferences: preferences,
			availabilityMonitor: availabilityMonitor,
			reachability: reachability,
			emit: { event in subject.send(event) }
		)
		self.pipeline = pipeline
		self.coordinator = NetworkChangeCoordinator(
			pipeline: pipeline,
			remoteAccessService: remoteAccessService,
			preferences: preferences,
			availabilityMonitor: availabilityMonitor,
			emit: { event in subject.send(event) }
		)

		// MARK: catalog seeding
		let initialStatic = DetectionPipeline.buildStaticRemoteDevice(from: preferences.staticDeviceAddress)
		Task { [catalog] in await catalog.setStaticRemoteDevice(initialStatic) }

		staticDeviceAddressCancellable = preferences.staticDeviceAddressPublisher
			.removeDuplicates()
			.sink { [pipeline] address in
				Task { await pipeline.handleStaticDeviceAddressChange(address) }
			}

		mdnsService.onUpdate = { [pipeline] locals in
			Task { await pipeline.handleMDNSUpdate(locals) }
		}
		Task { await forceReloadDevices() }
	}

	private func installReloadTriggers() {
		// Cancel previous subscriptions
		triggersCancellable?.cancel()
		reachabilityStatusCancellable?.cancel()
		networkChangeCancellable?.cancel()
		foregroundCancellable?.cancel()

		// Track foreground/background without UIApplication.shared (unavailable in extensions).
		// Spec: process any deferred network change when the app returns to foreground.
		foregroundCancellable = Publishers.Merge(
			NotificationCenter.default
				.publisher(for: UIApplication.didBecomeActiveNotification)
				.map { _ in true },
			NotificationCenter.default
				.publisher(for: UIApplication.willResignActiveNotification)
				.map { _ in false }
		)
		.sink { [coordinator] isActive in
			Task { await coordinator.handle(isActive ? .appBecameActive : .appResignedActive) }
		}

		// Immediate reactions: clear local devices on WiFi loss and forward reachability to UI.
		reachabilityStatusCancellable = reachability
			.updatesPublisher
			.sink { [weak self] state in
				guard let self else { return }
				self.emit(.reachabilityChanged(state.isReachable))
				Task { await self.handleImmediateNetworkStateChange(state) }
			}

		// Spec Algorithm D: debounce rapid network changes for 3 seconds before re-detecting.
		networkChangeCancellable = reachability
			.updatesPublisher
			.debounce(for: .seconds(3), scheduler: DispatchQueue.main)
			.sink { [coordinator] state in
				Task { await coordinator.handle(.networkStateChanged(state)) }
			}

		// Merge triggers: reachability became reachable OR app became active OR periodic reevaluation
		let reachableTrigger = reachability
			.updatesPublisher
			.map { $0.isReachable }
			.removeDuplicates()
			.filter { $0 }
			.map { _ in () }
			.eraseToAnyPublisher()

		let appActiveTrigger = NotificationCenter.default
			.publisher(for: UIApplication.didBecomeActiveNotification)
			.map { _ in () }
			.eraseToAnyPublisher()

		let periodicTrigger = Timer
			.publish(every: 60, on: .main, in: .common)
			.autoconnect()
			.map { _ in () }
			.eraseToAnyPublisher()

		triggersCancellable = Publishers.MergeMany([reachableTrigger, appActiveTrigger, periodicTrigger])
			.debounce(for: .seconds(3), scheduler: DispatchQueue.main)
			.sink { [weak self] in
				guard let self else { return }
				Task { await self.reprobeExistingPaths() }
			}
	}

	private func uninstallReloadTriggers() async {
		triggersCancellable?.cancel()
		triggersCancellable = nil
		reachabilityStatusCancellable?.cancel()
		reachabilityStatusCancellable = nil
		networkChangeCancellable?.cancel()
		networkChangeCancellable = nil
		foregroundCancellable?.cancel()
		foregroundCancellable = nil
		await coordinator.cancelCooldownTask()
	}

	// MARK: - Fast reprobe (no device reload)
	public func reprobeExistingPaths() async {
		await pipeline.reprobeExistingPaths()
	}

	/// Convenience accessor for external callers (e.g. login flow) that don't need the
	/// merged view but want to know whether mDNS has produced anything yet.
	public func localDevices() async -> [LocalDevice] {
		await catalog.localDevices()
	}

	/// Classifies the current connectivity state for the toast:
	/// - `.noInternet` (Liar Network): the OS reports a usable interface but our requests
	///   are still failing — typical for a bogus HTTP proxy or a captive Wi-Fi.
	/// - `.findingNetwork`: the OS reports no usable path (airplane mode, Wi-Fi off, etc.).
	private nonisolated func availabilityToastKind() -> NetworkAvailabilityToastKind {
		reachability.currentState.isReachable ? .noInternet : .findingNetwork
	}

	public nonisolated func start() {
		Task {
			await self.mdnsService.start()
			await self.reachability.start()
			await self.installReloadTriggers()
		}
	}

	public nonisolated func stop() {
		Task {
			await self.mdnsService.stop()
			await self.reachability.stop()
			await self.uninstallReloadTriggers()
		}
	}

	public func getMergedDevices(
		email: String,
		includeRemote: Bool = true,
		probeRemotePaths: Bool = true
	) async throws -> [MergedDevice] {
		try await pipeline.getMergedDevices(
			email: email,
			includeRemote: includeRemote,
			probeRemotePaths: probeRemotePaths
		)
	}

	// MARK: - Reload status
	public func isReloadingNow() async -> Bool {
		await pipeline.isReloadingNow()
	}

	/// Reacts immediately to each raw reachability event — clears stale local devices when
	/// WiFi is lost so they are not shown as reachable on cellular/wired/other connections.
	private func handleImmediateNetworkStateChange(_ state: NetworkState) async {
		guard state.interface != .wifi && state.interface != .none else { return }
		let locals = await catalog.localDevices()
		guard !locals.isEmpty else { return }
		await catalog.clearLocalDevices()
		emit(.devicesUpdated(await catalog.mergedDevices()))
	}

	// MARK: - Operation error handling → reprobe prompt
	/// Timeout, cannot connect, DNS — same as SDK @c isNetworkFailureError plus timedOut (status.php never hits core @c handleError).
	nonisolated private func isAutoReprobeTransportError(_ error: Error) -> Bool {
		let autoCodes: Set<Int> = [
			URLError.timedOut.rawValue,
			URLError.cannotConnectToHost.rawValue,
			URLError.cannotFindHost.rawValue,
			URLError.dnsLookupFailed.rawValue,
			URLError.networkConnectionLost.rawValue,
			URLError.notConnectedToInternet.rawValue
		]
		var current: Error? = error
		var depth = 0
		while let e = current, depth < 6 {
			let ns = e as NSError
			if ns.domain == NSURLErrorDomain, autoCodes.contains(ns.code) {
				return true
			}
			current = ns.userInfo[NSUnderlyingErrorKey] as? Error
			depth += 1
		}
		return false
	}

	public func forceReloadDevices() async {
		// Spec: reloadDevices() already probes all paths (via getMergedDevices or probeAll).
		// A second reprobeExistingPaths() call would probe every path twice; removed.
		await coordinator.beginExternalDetection()
		await pipeline.reloadDevices()
		await coordinator.endExternalDetection()
	}

	public func recalculateBestURLs() async {
		await pipeline.recalculateBestURLs()
	}

	// MARK: - Reset cached reachability state (e.g., on logout)
	public func resetState() async {
		await catalog.clear()
		await pathCacheStore.clear()
		await pipeline.cancelLoadTask()
		// Reset the coordinator so we don't retain a stale `.detecting` or queued state.
		// Any in-flight detection will still call `.detectionFinished`, which is a safe no-op
		// when the FSM is already `.idle` and the in-flight count returns to 0.
		await coordinator.reset()
		emit(.devicesUpdated(await catalog.mergedDevices()))
		urlProvider.clearAll()
	}

	// MARK: - Forward operation errors → transport auto reprobe + availability signal
	public nonisolated func reportOperationError(_ error: Error) {
		guard isAutoReprobeTransportError(error) else { return }
		// Transport failure → both kick off a switch and signal availability failure so
		// the 30 s "Finding network…" timer starts ticking even if no probes are running.
		Task { await self.recordAvailabilityFailureFromOperationError() }
		Task { await self.attemptSwitchAfterTransportFailure() }
	}

	private func recordAvailabilityFailureFromOperationError() async {
		// Operation errors arrive while the OS still reports a usable path (otherwise the
		// SDK wouldn't even attempt the request). Classify as "no internet" by default,
		// but defer to the current reachability state so an in-flight failure that lands
		// just after the interface drops still surfaces the right message.
		await availabilityMonitor.recordFailure(kind: availabilityToastKind())
	}

	/// Reprobe without prompting (status.php / pipeline failures never call core handleError).
	private func attemptSwitchAfterTransportFailure() async {
		let now = Date()
		if let last = lastTimeoutSwitchAttemptAt,
		   now.timeIntervalSince(last) < timeoutSwitchThrottleSeconds {
			return
		}
		lastTimeoutSwitchAttemptAt = now
		Log.debug("[STX-RA]: Transport failure → automatic path switch (reprobe)")

		if let email = preferences.favoriteEmail {
			let hasToken = await remoteAccessService.hasValidTokens()
			if hasToken == false {
				emit(.emailValidationNeeded(email: email))
			}
		}
		await forceReloadDevices()
	}

	// MARK: - Best path selection

	/// Returns true when local-type paths should be considered.
	/// Spec: local paths (mDNS and local-type Remote Access paths) are gated by WiFi.
	/// When the interface is unknown (.none), allow local paths rather than blocking.
	private var wifiAvailableForLocalPaths: Bool {
		let iface = reachability.currentState.interface
		return iface == .wifi || iface == .none
	}

	// MARK: - Path selection
	//
	// Two predicates are exposed:
	// - `nextURLToAttempt(...)` → "what URL should the SDK try right now?".
	//   Returns a fallback even when no probe has succeeded yet, so the SDK always has
	//   *something* to retry against. Use for `OCBaseURLProvider` / RA-base-URL bridging.
	// - `reachableSelection(...)` → "do we have positive evidence that the device is
	//   reachable?". Returns `nil` unless an operational probe (or a validated mDNS
	//   local) actually exists. Use for connectivity-gate decisions: login readiness,
	//   "still failing after detection" auth-loss prompt, etc.
	//
	// Mixing the two was the cause of the connectivity-toast bug: the old single
	// `currentBestPath(...)` answered "what to attempt?" but was being read as
	// "is anything reachable?".

	public func nextURLToAttempt(certificateCommonName cn: String) async -> SelectedPath? {
		await catalog.nextURLToAttempt(forCN: cn, wifiAvailable: wifiAvailableForLocalPaths)
	}

	public func reachableSelection(certificateCommonName cn: String) async -> SelectedPath? {
		await catalog.reachableSelection(forCN: cn, wifiAvailable: wifiAvailableForLocalPaths)
	}

	public func currentRemoteBaseURL() async -> URL? {
		guard let cn = preferences.favoriteDeviceCN else { return nil }
		return await catalog.remoteBaseURL(forCN: cn)
	}

	public func nextURLToAttempt(for merged: MergedDevice) -> SelectedPath? {
		catalog.nextURLToAttempt(for: merged, wifiAvailable: wifiAvailableForLocalPaths)
	}

	public func reachableSelection(for merged: MergedDevice) -> SelectedPath? {
		catalog.reachableSelection(for: merged, wifiAvailable: wifiAvailableForLocalPaths)
	}

}
