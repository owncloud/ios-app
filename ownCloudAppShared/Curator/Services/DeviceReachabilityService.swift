import Foundation
import Network
import Combine
import ownCloudSDK
import UIKit

// Simple timeout error used by lightweight probe timeouts
private enum ReprobeTimeoutError: Error { case timedOut }

public final actor DeviceReachabilityService {
	public struct PathProbe: Sendable, Codable {
		public enum Source: Sendable, Codable {
			case remotePath(RemoteDevice.Path)
			case mdns(host: String, port: Int)
		}
		public let source: Source
		public let status: Status?
		public let about: About?
		public var isReachable: Bool {
			guard let status, let about else { return false }
			return status.state == .ready && status.OOBE.done && (about.certificate_common_name.isEmpty == false)
		}
	}

	// Lightweight timeout helper for async operations
	nonisolated private func withTimeout<T>(_ seconds: Double, operation: @escaping @Sendable () async throws -> T) async throws -> T {
		return try await withThrowingTaskGroup(of: T.self) { group in
			group.addTask {
				return try await operation()
			}
			group.addTask {
				try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
				throw ReprobeTimeoutError.timedOut
			}
			let value = try await group.next()!
			group.cancelAll()
			return value
		}
	}

	public struct MergedDevice: Sendable, Codable {
		public let remoteDevice: RemoteDevice?
		public let localDevice: LocalDevice?
		public let pathProbes: [PathProbe]

		public var certificateCommonName: String? {
			if let remoteDevice {
				return remoteDevice.certificateCommonName
			}
			if let localDevice {
				return localDevice.certificateCommonName
			}
			return nil
		}

		func asJSON() -> String? {
			let encoder = JSONEncoder()
			encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
			encoder.dateEncodingStrategy = .iso8601

			do {
				let data = try encoder.encode(self)
				if let json = String(data: data, encoding: .utf8) {
					return json
				}
				return nil
			} catch {
				return nil
			}
		}
	}

	public enum SelectedPath: Sendable {
		case remote(RemoteDevice.Path)
		case mdns(host: String, port: Int)

		public var url: URL? {
			switch self {
				case let .mdns(host, port):
					return URL(host: host, port: port)
				case let .remote(path):
					return URL(host: path.address, port: path.port)
			}
		}
	}

	public let urlProvider: DeviceReachabilityURLProvider

	private var remoteDevices: [RemoteDevice] = []
	public private(set) var localDevices: [LocalDevice] = []
	private var remotePathProbesByCN: [String: [String: PathProbe]] = [:]
    private var onUpdate: (@MainActor ([MergedDevice]) -> Void)?
    private var onDetectionComplete: (@MainActor ([MergedDevice]) -> Void)?
    private var onDeviceFound: (@MainActor (RemoteDevice) -> Void)?
    private var onLocalDeviceFound: (@MainActor (MergedDevice) -> Void)?
    private var onReachabilityChange: (@MainActor (Bool) -> Void)?
	private var onEmailValidationRequest: (@MainActor (String) -> Void)?
	private var onReprobePrompt: (@MainActor (@escaping (Bool) -> Void) -> Void)?
	private var onRemoteBaseURLChange: (@MainActor (URL?) -> Void)?
	private var triggersCancellable: AnyCancellable?
	private var reachabilityStatusCancellable: AnyCancellable?
	private var networkChangeCancellable: AnyCancellable?
	private var foregroundCancellable: AnyCancellable?
	private var staticDeviceAddressCancellable: AnyCancellable?
	private var loadTask: Task<[MergedDevice], Error>?
	private var isReloading: Bool = false
	private var lastNetworkState: NetworkState?
	/// Spec: the first reachability event is the initial known state and should not trigger re-detection.
	private var hasSeenInitialNetworkState: Bool = false
	/// Tracks foreground/background using lifecycle notifications — avoids UIApplication.shared (unavailable in extensions).
	private var isAppActive: Bool = true
	/// Spec: network changes that arrive while the app is in background are stored and processed on foreground resume.
	private var pendingNetworkChange: NetworkState?
	/// Spec: minimum 30-second cooldown between network-change-triggered re-detection attempts.
	private var lastDetectionAt: Date?
	private let detectionCooldownSeconds: TimeInterval = 30
	/// Holds a deferred detection scheduled to fire after the cooldown window expires.
	private var cooldownTask: Task<Void, Never>?
	/// Monotonically increasing counter. Each new detection pass takes a snapshot;
	/// any suspended prior pass sees a mismatch and exits early (cancel-and-restart).
	private var detectionGeneration: Int = 0
	/// Spec: connection paths cached with a timestamp; expire after 1 hour.
	private var pathCacheByCN: [String: CachedPaths] = [:]
	/// Retains the last successfully validated local URL per CN.
	/// Unlike `localDevices`, this is NOT cleared on WiFi loss so that Algorithm B step 1
	/// can test the URL directly (no WiFi check) when a network change fires.
	private var lastKnownLocalURLByCN: [String: URL] = [:]
	private struct CachedPaths: Codable {
		var paths: [RemoteDevice.Path]
		var timestamp: Date
		var isExpired: Bool { Date().timeIntervalSince(timestamp) > 3600 }
		mutating func refreshTimestamp() { timestamp = Date() }
	}
	private var staticRemoteDevice: RemoteDevice?
	/// Throttles automatic reprobe (timeout, cannot connect, status.php poll failures, …).
	private var lastTimeoutSwitchAttemptAt: Date?
	private let timeoutSwitchThrottleSeconds: TimeInterval = 60
	private var lastReprobePromptAt: Date?
	private let reprobePromptThrottleSeconds: TimeInterval = 60

	private let reachability: ReachabilityObserving
	private let remoteAccessService: RemoteAccessService
	private let mdnsService: MDNSService
	private let preferences: HCPreferences

	public init(
		reachability: ReachabilityObserving,
		remoteAccessService: RemoteAccessService,
		mdnsService: MDNSService,
		preferences: HCPreferences
	) {
		self.reachability = reachability
		self.remoteAccessService = remoteAccessService
		self.mdnsService = mdnsService
		self.preferences = preferences

		urlProvider = DeviceReachabilityURLProvider(preferences: preferences)

		// Spec: restore the path cache (with timestamps) from the last session.
		if let data = preferences.cachedDevicePathsData,
		   let restored = try? JSONDecoder().decode([String: CachedPaths].self, from: data) {
			pathCacheByCN = restored
		}

		staticRemoteDevice = Self.buildStaticRemoteDevice(from: preferences.staticDeviceAddress)
		staticDeviceAddressCancellable = preferences.staticDeviceAddressPublisher
			.removeDuplicates()
			.sink { [weak self] address in
				guard let self else { return }
				Task { await self.handleStaticDeviceAddressChange(address) }
			}

		mdnsService.onUpdate = { [weak self] locals in
			guard let self else { return }
			Task { await self.handleMDNSUpdate(locals) }
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
		.sink { [weak self] isActive in
			guard let self else { return }
			Task {
				await self.handleAppLifecycleChange(isActive: isActive)
			}
		}

		// Immediate reactions: clear local devices on WiFi loss and forward reachability to UI.
		reachabilityStatusCancellable = reachability
			.updatesPublisher
			.sink { [weak self] state in
				guard let self else { return }
				Task {
					await self.handleImmediateNetworkStateChange(state)
					if let handler = await self.onReachabilityChange {
						await MainActor.run { handler(state.isReachable) }
					}
				}
			}

		// Spec Algorithm D: debounce rapid network changes for 3 seconds before re-detecting.
		networkChangeCancellable = reachability
			.updatesPublisher
			.debounce(for: .seconds(3), scheduler: DispatchQueue.main)
			.sink { [weak self] state in
				guard let self else { return }
				Task { await self.handleNetworkChange(state) }
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

	private func uninstallReloadTriggers() {
		triggersCancellable?.cancel()
		triggersCancellable = nil
		reachabilityStatusCancellable?.cancel()
		reachabilityStatusCancellable = nil
		networkChangeCancellable?.cancel()
		networkChangeCancellable = nil
		foregroundCancellable?.cancel()
		foregroundCancellable = nil
		cooldownTask?.cancel()
		cooldownTask = nil
	}

	// MARK: - Fast reprobe (no device reload)
	public func reprobeExistingPaths() async {
		if isReloading { return }
		isReloading = true
		defer { isReloading = false }

		do {
			let probes = (try await self.probeAll(self.remoteDevices))
			self.setProbes(probes)
		} catch {
			Log.debug("[STX-RA]: Failed to probe device with error: \(error)")
		}
		let merged = self.currentMerged()
		if let onUpdate = self.onUpdate { await MainActor.run { onUpdate(merged) } }
		recalculateBestURLs()

	}

	private func handleMDNSUpdate(_ locals: [LocalDevice]) {
		// Spec: local discovery is only useful on the same network as the device.
		// Skip mDNS results when WiFi is confirmed absent.
		// When the interface is .none (unknown), proceed rather than block (spec rule).
		let iface = reachability.currentState.interface
		guard iface == .wifi || iface == .none else {
			Log.debug("[STX-MDNS]: Skipping mDNS update — WiFi not available (interface: \(iface.rawValue)).")
			return
		}
		let previous = localDevices
		self.localDevices = locals

		// Remember every validated local URL so Algorithm B step 1 can use it even after WiFi loss.
		for local in locals {
			guard let cn = local.certificateCommonName,
				  let url = URL(host: local.host, port: local.port) else { continue }
			lastKnownLocalURLByCN[cn] = url
		}

		let merged = rebuildMerged(
			localDevices: localDevices,
			remoteDevices: remoteDevices,
			remotePathProbesByCN: remotePathProbesByCN,
			staticRemoteDevice: staticRemoteDevice
		)

		// Spec Algorithm A Phase 1: emit deviceFound for each newly CN-validated local device.
		// "newly" = the device has a CN now but didn't before (about endpoint just validated it).
		if let handler = onLocalDeviceFound {
			for local in locals {
				guard let cn = local.certificateCommonName else { continue }
				let wasValidated = previous.contains(where: { $0.certificateCommonName == cn })
				if !wasValidated, let entry = merged.first(where: { $0.certificateCommonName == cn }) {
					Task { @MainActor in handler(entry) }
				}
			}
		}

		if let onUpdate { Task { @MainActor in onUpdate(merged) } }
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
		loadTask?.cancel()
		loadTask = Task.detached { [email, includeRemote, probeRemotePaths] in
			let remote: [RemoteDevice]
			if includeRemote {
				remote = try await self.remoteAccessService.getRemoteDevices(email: email)
			} else {
				remote = []
			}
			await self.setRemoteDevices(remote)
			// Spec: populate the path cache so subsequent direct resolutions can use it.
			await self.updatePathCache(from: remote)
			// Spec §remote-phase: emit a device-found event for each remote device.
			// The payload is the raw RemoteDevice; local mDNS fields are intentionally excluded.
			if let handler = await self.onDeviceFound {
				for device in remote {
					await MainActor.run { handler(device) }
				}
			}
			if Task.isCancelled { return [] }

			let probes: [String: [String: PathProbe]]
			if includeRemote, probeRemotePaths, remote.isEmpty == false {
				probes = (try? await self.probeAll(remote)) ?? [:]
			} else {
				probes = [:]
			}
			await self.setProbes(probes)
			if Task.isCancelled { return [] }

			let merged = await self.currentMerged()
			// Only publish via onUpdate when paths have been probed; callers that pass
			// probeRemotePaths: false (e.g. reloadDevices) publish after the separate probe step.
			if probeRemotePaths, let onUpdate = await self.onUpdate {
				await MainActor.run { onUpdate(merged) }
			}
			return merged
		}
		return try await loadTask!.value
	}

	private func setRemoteDevices(_ v: [RemoteDevice]) {
		self.remoteDevices = v
	}

	private func setProbes(_ d: [String: [String: PathProbe]]) {
		self.remotePathProbesByCN = d
	}

	private func updatePathCache(from devices: [RemoteDevice]) {
		for device in devices {
			pathCacheByCN[device.certificateCommonName] = CachedPaths(paths: device.paths, timestamp: Date())
		}
		persistPathCache()
	}

	/// Persists the current `pathCacheByCN` to `HCPreferences` so that the 1-hour TTL
	/// survives app restarts (spec: "cached device paths with timestamp" as required state).
	private func persistPathCache() {
		if let data = try? JSONEncoder().encode(pathCacheByCN) {
			preferences.cachedDevicePathsData = data
		}
	}

	// MARK: - Reload status
	public func isReloadingNow() -> Bool {
		return isReloading
	}

    private func handleNetworkChange(_ state: NetworkState) async {
		// Spec Algorithm D: ignore the very first event — it represents the initial known state,
		// not an actual change. Record it so subsequent events can be compared against it.
		guard hasSeenInitialNetworkState else {
			hasSeenInitialNetworkState = true
			lastNetworkState = state
			return
		}

		if let last = lastNetworkState, last.interface == state.interface { return }
		lastNetworkState = state

		// Spec Algorithm D step 1: auth check — unconditional, not gated on favoriteEmail.
		let hasToken = await remoteAccessService.hasValidTokens()
		if !hasToken {
			if let email = preferences.favoriteEmail, let handler = onEmailValidationRequest {
				await MainActor.run { handler(email) }
			}
			return
		}

		// Spec Algorithm D step 2: if a detection is already running, return immediately.
		guard !isReloading else {
			Log.debug("[STX-RA]: Network change dropped — detection already in progress.")
			return
		}

		// Spec Algorithm D: 30-second cooldown between re-detection attempts.
		// Schedule a deferred task so the re-detection fires after the remaining wait time
		// rather than being silently dropped.
		if let last = lastDetectionAt {
			let elapsed = Date().timeIntervalSince(last)
			if elapsed < detectionCooldownSeconds {
				let wait = detectionCooldownSeconds - elapsed
				Log.debug("[STX-RA]: Cooldown active; deferring re-detection by \(Int(wait))s.")
				cooldownTask?.cancel()
				let capturedState = state
				cooldownTask = Task { [weak self] in
					try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
					guard let self, !Task.isCancelled else { return }
					await self.runDeferredDetection(state: capturedState)
				}
				return
			}
		}
		cooldownTask?.cancel()
		cooldownTask = nil
		lastDetectionAt = Date()

		// Spec Algorithm D: background check comes after the cooldown (spec §Re-Detection order).
		if !isAppActive {
			pendingNetworkChange = state
			Log.debug("[STX-RA]: Network change deferred (app not active). Interface: \(state.interface.rawValue).")
			return
		}

		await runDetection(state: state)
    }

	/// Processes a network change that was previously deferred (stored in pendingNetworkChange).
	/// Unlike handleNetworkChange, this skips the first-event and interface-equality filters
	/// (those only apply to freshly received events) but still enforces auth, cooldown, and
	/// background so deferred detections are rate-limited the same as any fresh event.
	private func processDeferredNetworkChange(_ state: NetworkState) async {
		// Spec Algorithm D step 1: auth check — unconditional, not gated on favoriteEmail.
		let hasToken = await remoteAccessService.hasValidTokens()
		if !hasToken {
			if let email = preferences.favoriteEmail, let handler = onEmailValidationRequest {
				await MainActor.run { handler(email) }
			}
			return
		}
		// Spec Algorithm D: cooldown check comes before background check.
		if let last = lastDetectionAt {
			let elapsed = Date().timeIntervalSince(last)
			if elapsed < detectionCooldownSeconds {
				let wait = detectionCooldownSeconds - elapsed
				Log.debug("[STX-RA]: Cooldown active; deferring deferred change by \(Int(wait))s.")
				cooldownTask?.cancel()
				let capturedState = state
				cooldownTask = Task { [weak self] in
					try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
					guard let self, !Task.isCancelled else { return }
					await self.runDeferredDetection(state: capturedState)
				}
				return
			}
		}
		cooldownTask?.cancel()
		cooldownTask = nil
		lastDetectionAt = Date()
		// Spec Algorithm D: background check comes after cooldown.
		guard isAppActive else {
			pendingNetworkChange = state
			Log.debug("[STX-RA]: Deferred network change re-deferred (app not active).")
			return
		}
		await runDetection(state: state)
	}

	/// Runs the core detection logic for a deferred cooldown trigger.
	private func runDeferredDetection(state: NetworkState) async {
		guard !isReloading else { return }
		// Spec Algorithm D: background check comes after the cooldown wait. The cooldown timer
		// fires asynchronously; by the time it does, the app may be in the background.
		// Re-defer to pendingNetworkChange instead of running detection while backgrounded.
		guard isAppActive else {
			pendingNetworkChange = state
			Log.debug("[STX-RA]: Cooldown fired while app is in background — re-deferred to foreground.")
			return
		}
		lastDetectionAt = Date()
		await runDetection(state: state)
	}

	/// Shared detection logic used by both handleNetworkChange and runDeferredDetection.
	private func runDetection(state: NetworkState) async {
		// Spec Algorithm D: auth check — unconditional, not gated on favoriteEmail.
		let hasToken = await remoteAccessService.hasValidTokens()
		if !hasToken {
			if let email = preferences.favoriteEmail, let handler = onEmailValidationRequest {
				await MainActor.run { handler(email) }
			}
			return
		}

		// Spec Algorithm D: when seagateDeviceID is already known, skip full re-discovery
		// and resolve paths for the known device directly. Fall back to a full reload only
		// if that targeted attempt fails (device truly unreachable or auth lost).
		if let saved = preferences.currentConnectedDevice,
		   let seagateDeviceID = saved.seagateDeviceID,
		   !seagateDeviceID.isEmpty {
			let resolved = await tryDirectPathResolution(
				seagateDeviceID: seagateDeviceID,
				certificateCommonName: saved.certificateCommonName
			)
			if resolved { return }
		}

		await forceReloadDevices()

		// Spec Algorithm D post-condition: distinguish RA auth failure from general unreachability.
		// "if current device is found again → update host; else → surface failure OR ask for RA auth"
		if let cn = preferences.favoriteDeviceCN {
			let merged = currentMerged()
			let preferredReachable = merged
				.first(where: { $0.certificateCommonName == cn })
				.flatMap { currentBestPath(for: $0) } != nil
			if !preferredReachable {
				Log.debug("[STX-RA]: Device \(cn) not reachable after full discovery.")
				let tokensStillValid = await remoteAccessService.hasValidTokens()
				if !tokensStillValid, let email = preferences.favoriteEmail, let handler = onEmailValidationRequest {
					// Auth was lost during detection — ask user to re-authenticate.
					await MainActor.run { handler(email) }
				} else {
					// Authenticated but no path available — surface reconnection failure.
					await requestReprobeFromUI()
				}
			}
		}
	}

	/// Called by the lifecycle notification subscriber to keep `isAppActive` in sync
	/// and to drain any network change that was deferred while the app was in background.
	private func handleAppLifecycleChange(isActive: Bool) async {
		isAppActive = isActive
		guard isActive, let pending = pendingNetworkChange else { return }
		pendingNetworkChange = nil
		Log.debug("[STX-RA]: Processing deferred network change on foreground. Interface: \(pending.interface.rawValue).")
		// Use processDeferredNetworkChange rather than handleNetworkChange.
		// handleNetworkChange updates lastNetworkState *before* the background check, so when
		// the same state is replayed here the interface-equality filter ("already on this
		// interface, nothing to do") immediately returns and the detection is silently dropped.
		// processDeferredNetworkChange skips that filter while still enforcing auth, background,
		// and the 30-second cooldown.
		await processDeferredNetworkChange(pending)
	}

	/// Reacts immediately to each raw reachability event — clears stale local devices when
	/// WiFi is lost so they are not shown as reachable on cellular/wired/other connections.
	private func handleImmediateNetworkStateChange(_ state: NetworkState) async {
		guard state.interface != .wifi && state.interface != .none else { return }
		guard !localDevices.isEmpty else { return }
		localDevices = []
		let merged = currentMerged()
		if let onUpdate { await MainActor.run { onUpdate(merged) } }
	}

	/// Spec Algorithm C: test local and public paths in parallel; return the best result
	/// immediately using local-beats-public priority without waiting for all probes to finish.
	/// Remote relay paths should NOT be passed here — use a separate call for relay fallback.
	nonisolated private func testPriorityPaths(_ paths: [RemoteDevice.Path]) async -> (path: RemoteDevice.Path, probe: PathProbe)? {
		guard !paths.isEmpty else { return nil }

		return await withTaskGroup(of: (RemoteDevice.Path, PathProbe?, Bool).self) { group in
			var localPending = 0
			for path in paths {
				let isLocal = path.kind == .local
				if isLocal { localPending += 1 }
				group.addTask {
					guard let url = path.apiBaseURL() else { return (path, nil, isLocal) }
					let api = DeviceAPI(deviceBaseURL: url)
					let timeout: Double = isLocal ? 4.0 : 9.0
					var status: Status?
					var about: About?
					do { status = try await self.withTimeout(timeout) { try await api.getStatus() } } catch {}
					do { about  = try await self.withTimeout(timeout) { try await api.getAbout() } } catch {}
					guard let s = status, let a = about else { return (path, nil, isLocal) }
					return (path, PathProbe(source: .remotePath(path), status: s, about: a), isLocal)
				}
			}

			var totalPending = paths.count
			var bestPublicResult: (RemoteDevice.Path, PathProbe)?

			while let (path, probe, isLocal) = await group.next() {
				if let probe, probe.isReachable {
					if isLocal {
						// Spec: local success → return immediately, cancel remaining.
						group.cancelAll()
						return (path, probe)
					} else {
						if bestPublicResult == nil { bestPublicResult = (path, probe) }
						// Spec: this check only fires on public success, not on local failure.
						if localPending == 0 {
							group.cancelAll()
							return bestPublicResult!
						}
					}
				}
				if isLocal { localPending -= 1 }
				totalPending -= 1
				if totalPending == 0 { return bestPublicResult }
			}
			return bestPublicResult
		}
	}

	/// Stores a successful direct-resolution result and notifies observers.
	private func commitDirectResolution(
		certificateCommonName: String,
		seagateDeviceID: String,
		allPaths: [RemoteDevice.Path],
		winningPath: RemoteDevice.Path,
		winningProbe: PathProbe
	) async -> Bool {
		if let existing = remoteDevices.first(where: { $0.certificateCommonName == certificateCommonName }) {
			let updated = RemoteDevice(
				seagateDeviceID: existing.seagateDeviceID,
				friendlyName: existing.friendlyName,
				hostname: existing.hostname,
				certificateCommonName: certificateCommonName,
				paths: allPaths
			)
			if let idx = remoteDevices.firstIndex(where: { $0.certificateCommonName == certificateCommonName }) {
				remoteDevices[idx] = updated
			}
		} else if let saved = preferences.currentConnectedDevice {
			let built = RemoteDevice(
				seagateDeviceID: seagateDeviceID,
				friendlyName: saved.friendlyName ?? "",
				hostname: saved.hostname ?? "",
				certificateCommonName: certificateCommonName,
				paths: allPaths
			)
			remoteDevices.append(built)
		}
		remotePathProbesByCN[certificateCommonName] = [winningPath.key: winningProbe]
		let merged = currentMerged()
		if let onUpdate { await MainActor.run { onUpdate(merged) } }
		recalculateBestURLs()
		Log.debug("[STX-RA]: Direct path resolution succeeded (\(winningPath.kind)) for \(certificateCommonName).")
		return true
	}

	private func pathsAreEqual(_ a: [RemoteDevice.Path], _ b: [RemoteDevice.Path]) -> Bool {
		Set(a.map(\.key)) == Set(b.map(\.key))
	}

	/// Spec Algorithm B: find the best connection for the known device without a full re-discovery.
	/// Steps: (1) local baseUrl shortcut, (2) cached or fresh paths → Algorithm C priority test,
	/// (3) cache refresh if expired, (4) relay fallback. Falls back to full reload on failure.
	private func tryDirectPathResolution(seagateDeviceID: String, certificateCommonName: String) async -> Bool {
		// Step 1: test the known local baseUrl directly — no WiFi check (spec WiFi exception).
		// Prefer in-memory localDevices; fall back to lastKnownLocalURLByCN which survives WiFi loss.
		let localURL: URL? = localDevices
			.first(where: { $0.certificateCommonName == certificateCommonName })
			.flatMap { URL(host: $0.host, port: $0.port) }
			?? lastKnownLocalURLByCN[certificateCommonName]

		if let url = localURL {
			do {
				let api = DeviceAPI(deviceBaseURL: url)
				let about = try await withTimeout(4.0) { try await api.getAbout() }
				if about.certificate_common_name == certificateCommonName {
					Log.debug("[STX-RA]: Local baseUrl shortcut succeeded for \(certificateCommonName).")
					let merged = currentMerged()
					if let onUpdate { await MainActor.run { onUpdate(merged) } }
					recalculateBestURLs()
					return true
				}
			} catch {
				Log.debug("[STX-RA]: Local baseUrl shortcut failed: \(error). Proceeding to backend.")
			}
		}

		guard await remoteAccessService.hasValidTokens() else { return false }

		let wifiAvailable = wifiAvailableForLocalPaths

		// Step 2: get paths from cache (spec: reuse even if expired; only fetch fresh if no cache at all).
		// Expired cached paths are still tested first. Fresh paths are only fetched in step 4,
		// after all cached priority paths fail AND the cache is confirmed expired.
		let cachedEntry = pathCacheByCN[certificateCommonName]
		let fromCache = cachedEntry != nil
		var allPaths: [RemoteDevice.Path]

		if let cached = cachedEntry {
			allPaths = cached.paths
			Log.debug("[STX-RA]: Using cached paths for \(certificateCommonName) (expired: \(cached.isExpired)).")
		} else {
			do {
				allPaths = try await remoteAccessService.getPathsForDevice(seagateDeviceID: seagateDeviceID)
				pathCacheByCN[certificateCommonName] = CachedPaths(paths: allPaths, timestamp: Date())
				persistPathCache()
			} catch {
				Log.debug("[STX-RA]: Failed to fetch paths for \(certificateCommonName): \(error).")
				return false
			}
		}

		guard !allPaths.isEmpty else { return false }

		// Step 3: Algorithm C — test local + public paths with priority early-return.
		var priorityPaths = allPaths.filter { $0.kind != .remote }
		if !wifiAvailable { priorityPaths = priorityPaths.filter { $0.kind != .local } }

		if let (best, probe) = await testPriorityPaths(priorityPaths) {
			return await commitDirectResolution(
				certificateCommonName: certificateCommonName, seagateDeviceID: seagateDeviceID,
				allPaths: allPaths, winningPath: best, winningProbe: probe
			)
		}

		// Step 4: if paths came from cache and cache is now expired, refresh once.
		if fromCache, pathCacheByCN[certificateCommonName]?.isExpired == true {
			do {
				let freshPaths = try await remoteAccessService.getPathsForDevice(seagateDeviceID: seagateDeviceID)
				if pathsAreEqual(freshPaths, allPaths) {
					// Spec: identical paths — refresh timestamp only, do not re-test.
					pathCacheByCN[certificateCommonName]?.refreshTimestamp()
					persistPathCache()
					Log.debug("[STX-RA]: Cache refreshed (paths unchanged) for \(certificateCommonName).")
				} else {
					pathCacheByCN[certificateCommonName] = CachedPaths(paths: freshPaths, timestamp: Date())
					persistPathCache()
					var freshPriority = freshPaths.filter { $0.kind != .remote }
					if !wifiAvailable { freshPriority = freshPriority.filter { $0.kind != .local } }
					if let (best, probe) = await testPriorityPaths(freshPriority) {
						return await commitDirectResolution(
							certificateCommonName: certificateCommonName, seagateDeviceID: seagateDeviceID,
							allPaths: freshPaths, winningPath: best, winningProbe: probe
						)
					}
				}
			} catch {
				Log.debug("[STX-RA]: Failed to refresh paths for \(certificateCommonName): \(error).")
			}
		}

		// Step 5: relay as last fallback.
		let relayPaths = allPaths.filter { $0.kind == .remote }
		if let (best, probe) = await testPriorityPaths(relayPaths) {
			return await commitDirectResolution(
				certificateCommonName: certificateCommonName, seagateDeviceID: seagateDeviceID,
				allPaths: allPaths, winningPath: best, winningProbe: probe
			)
		}

		Log.debug("[STX-RA]: Direct path resolution failed for \(certificateCommonName). Falling back to full reload.")
		return false
	}

	/// Spec Phase 1: wait up to 5 seconds for local mDNS discovery before starting remote.
	/// Exits immediately when local devices are already known, WiFi is unavailable, or the
	/// detection generation has been superseded by a newer call (cancel-and-restart).
	private func waitForLocalDiscovery(generation: Int) async {
		guard wifiAvailableForLocalPaths, localDevices.isEmpty else { return }
		Log.debug("[STX-RA]: Waiting for local discovery window (up to 5 s)…")
		let deadline = Date().addingTimeInterval(5)
		while localDevices.isEmpty && Date() < deadline && detectionGeneration == generation {
			try? await Task.sleep(nanoseconds: 100_000_000) // 100 ms poll
		}
		Log.debug("[STX-RA]: Local discovery window complete. Found \(localDevices.count) device(s).")
	}

	private func reloadDevices() async {
		// Spec: cancel any active detection session and restart from a clean state.
		// Bump the generation so any suspended prior pass sees a mismatch and exits early.
		detectionGeneration &+= 1
		let myGen = detectionGeneration
		loadTask?.cancel()
		loadTask = nil
		isReloading = true
		defer { if detectionGeneration == myGen { isReloading = false } }

		// Spec Algorithm A: reset the temporary device map before each detection pass.
		remoteDevices = []
		remotePathProbesByCN = [:]

		// Spec cancel-and-restart: stop mDNS and clear local state so the new detection
		// pass begins from a clean slate, then restart for the local discovery window.
		localDevices = []
		mdnsService.stop()
		mdnsService.start()

		// Spec Phase 1: local discovery window. Phase 2 (remote) starts only after this returns.
		await waitForLocalDiscovery(generation: myGen)
		guard detectionGeneration == myGen else { return }

		Log.debug("[STX-RA]: Reloading devices.")
		// Spec Algorithm A: only attempt remote discovery when authenticated.
		// Discovery only — path probing is Algorithm B and runs as a separate step below.
		if let email = preferences.favoriteEmail,
		   await remoteAccessService.hasValidTokens() {
			_ = (try? await getMergedDevices(email: email, probeRemotePaths: false)) ?? []
			guard detectionGeneration == myGen else { return }
		}
		if remoteDevices.isEmpty, let saved = preferences.currentConnectedDevice {
			// Seed with saved connected device so we can probe paths after relaunch
			let paths: [RemoteDevice.Path] = saved.paths.map { p in
				let raKind: RADevicePathKind
				switch p.kind {
					case .local: raKind = .local
					case .public: raKind = .public
					case .remote: raKind = .remote
				}
				let ra = RADevicePath(type: raKind, address: p.address, port: p.port)
				return RemoteDevice.Path(raDevicePath: ra)
			}
			let seeded = RemoteDevice(
				seagateDeviceID: saved.seagateDeviceID ?? "",
				friendlyName: saved.friendlyName ?? "",
				hostname: saved.hostname ?? "",
				certificateCommonName: saved.certificateCommonName,
				paths: paths
			)
			self.setRemoteDevices([seeded])
		}
		// Spec Algorithm B is separate from Algorithm A: probe all paths after discovery completes.
		let probes = (try? await self.probeAll(self.remoteDevices)) ?? [:]
		guard detectionGeneration == myGen else { return }
		self.setProbes(probes)
		let merged = self.currentMerged()
		if let onUpdate = self.onUpdate { await MainActor.run { onUpdate(merged) } }
		Log.debug("[STX-RA]: Remote count: \(remoteDevices.count). Local count: \(localDevices.count).")
		recalculateBestURLs()

		// Spec Algorithm A: emit detectionComplete after all phases (local + remote) have finished.
		let finalMerged = currentMerged()
		if let handler = onDetectionComplete { await MainActor.run { handler(finalMerged) } }
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

	nonisolated private func shouldOfferReprobe(for error: Error) -> Bool {
		let ns = error as NSError
		if ns.domain == NSURLErrorDomain {
			let codes: [URLError.Code] = [
				.notConnectedToInternet,
				.networkConnectionLost,
				.cannotFindHost,
				.cannotConnectToHost,
				.dnsLookupFailed,
				.timedOut,
				.dataNotAllowed,
				.internationalRoamingOff,
				.callIsActive
			]
			return codes.contains(where: { $0.rawValue == ns.code })
		}
		return false
	}

	private func requestReprobeFromUI() async {
		let now = Date()
		if let last = lastReprobePromptAt,
		   now.timeIntervalSince(last) < reprobePromptThrottleSeconds {
			return
		}
		lastReprobePromptAt = now
		guard let prompt = onReprobePrompt else {
			return
		}
		await MainActor.run {
			prompt { [weak self] accepted in
				guard let self else { return }
				if accepted {
					Task { await self.forceReloadDevices() }
				}
			}
		}
	}

	public func forceReloadDevices() async {
		// Spec: reloadDevices() already probes all paths (via getMergedDevices or probeAll).
		// A second reprobeExistingPaths() call would probe every path twice; removed.
		await reloadDevices()
	}

	public func recalculateBestURLs() {
		for device in currentMerged() {
			guard
				let cn = device.certificateCommonName,
				let path = currentBestPath(for: device),
				let url = path.url
			else { continue }

			urlProvider.setBestURL(url, for: cn)
			Task {
				guard let cn = preferences.favoriteDeviceCN else {
					await onRemoteBaseURLChange?(nil)
					return
				}
				await onRemoteBaseURLChange?(remoteBaseURL(forCertificateCommonName: cn))
			}
		}
		Log.debug("[STX-RA]: Best RA URL: \(urlProvider.currentBaseURL()?.absoluteString ?? "")")
	}

	private func currentMerged() -> [MergedDevice] {
		rebuildMerged(
			localDevices: localDevices,
			remoteDevices: remoteDevices,
			remotePathProbesByCN: remotePathProbesByCN,
			staticRemoteDevice: staticRemoteDevice
		)
	}

	// MARK: - Observing merged updates (bridge support)
	public func observeMergedDevices(_ handler: @escaping @MainActor ([MergedDevice]) -> Void) {
		self.onUpdate = handler
		let snapshot = self.currentMerged()
		Task { @MainActor in handler(snapshot) }
	}

	// MARK: - Observing reachability updates (bridge support)
	public func observeReachability(_ handler: @escaping @MainActor (Bool) -> Void) {
		self.onReachabilityChange = handler
	}

	// MARK: - Observing detection-complete event (spec Algorithm A)
	/// Called once after every full detection run (Algorithm A) completes, carrying the final device map.
	public func observeDetectionComplete(_ handler: @escaping @MainActor ([MergedDevice]) -> Void) {
		self.onDetectionComplete = handler
	}

	// MARK: - Observing per-device remote-phase events
	/// Called for each remote device discovered during the remote phase. The payload is the raw
	/// `RemoteDevice` without local mDNS fields merged in (spec §remote-phase device-found event).
	public func observeDeviceFound(_ handler: @escaping @MainActor (RemoteDevice) -> Void) {
		self.onDeviceFound = handler
	}

	// MARK: - Observing per-device local-phase events (spec Algorithm A Phase 1)
	/// Called for each mDNS device whose `about` endpoint has just been validated.
	/// The payload is the full `MergedDevice` map entry for that device.
	public func observeLocalDeviceFound(_ handler: @escaping @MainActor (MergedDevice) -> Void) {
		self.onLocalDeviceFound = handler
	}

	// MARK: - Observing email validation requests (when RA tokens are required)
	public func observeEmailValidationRequest(_ handler: @escaping @MainActor (String) -> Void) {
		self.onEmailValidationRequest = handler
	}

	// MARK: - Reset cached reachability state (e.g., on logout)
	public func resetState() async {
		remoteDevices = []
		localDevices = []
		remotePathProbesByCN = [:]
		pathCacheByCN = [:]
		lastKnownLocalURLByCN = [:]
		preferences.cachedDevicePathsData = nil
		loadTask?.cancel()
		loadTask = nil
		let merged = currentMerged()
		if let onUpdate = onUpdate {
			await MainActor.run { onUpdate(merged) }
		}
		urlProvider.clearAll()
	}

	public func observeRemoteBaseURL(_ handler: (@MainActor (URL?) -> Void)?) {
		self.onRemoteBaseURLChange = handler
	}

	// MARK: - Observing reprobe prompt requests (network errors from operations)
	public func observeReprobePrompt(_ handler: @escaping @MainActor (@escaping (Bool) -> Void) -> Void) {
		self.onReprobePrompt = handler
	}

	// MARK: - Forward operation errors → transport auto reprobe, else reprobe prompt
	public nonisolated func reportOperationError(_ error: Error) {
		if isAutoReprobeTransportError(error) {
			Task { await self.attemptSwitchAfterTransportFailure() }
			return
		}
		guard shouldOfferReprobe(for: error) else { return }
		Task { await self.requestReprobeFromUI() }
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
			if hasToken == false, let handler = onEmailValidationRequest {
				await MainActor.run { handler(email) }
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

	public func currentBestPath(certificateCommonName cn: String) -> SelectedPath? {
		let wifiAvailable = wifiAvailableForLocalPaths
		// Prefer reachable remote path by priority, skipping local-type paths when WiFi is absent.
		if let remote = remoteDevices.first(where: { $0.certificateCommonName == cn }) {
			let probesDict = remotePathProbesByCN[cn] ?? [:]
			for path in remote.paths.ordered() {
				guard path.kind != .local || wifiAvailable else { continue }
				if let probe = probesDict[path.key], probe.isReachable {
					return .remote(path)
				}
			}
		}
		if let staticRemoteDevice, staticRemoteDevice.certificateCommonName == cn {
			let probesDict = remotePathProbesByCN[cn] ?? [:]
			for path in staticRemoteDevice.paths.ordered() {
				if let probe = probesDict[path.key], probe.isReachable {
					return .remote(path)
				}
			}
			if let first = staticRemoteDevice.paths.ordered().first {
				return .remote(first)
			}
		}

		// Fallback: local mDNS — only when WiFi is available (spec: local paths are WiFi-gated).
		if wifiAvailable, let local = localDevices.first(where: { $0.certificateCommonName == cn }) {
			return .mdns(host: local.host, port: local.port)
		}

		return nil
	}

	public func currentRemoteBaseURL() -> URL? {
		guard let cn = preferences.favoriteDeviceCN else { return nil }
		return remoteBaseURL(forCertificateCommonName: cn)
	}

	public func currentBestPath(for merged: MergedDevice) -> SelectedPath? {
		let wifiAvailable = wifiAvailableForLocalPaths

		// 1) Prefer reachable probes in priority order, skipping local-type paths when WiFi is absent.
		if let probe = merged.pathProbes.first(where: { probe in
			guard probe.isReachable else { return false }
			switch probe.source {
				case .remotePath(let path) where path.kind == .local && !wifiAvailable:
					return false
				default:
					return true
			}
		}) {
			switch probe.source {
				case .remotePath(let path):
					return .remote(path)
				case .mdns(let host, let port):
					return .mdns(host: host, port: port)
			}
		}

		// 2) Fallback: best ordered non-local remote path (or any path if WiFi is available).
		if let remote = merged.remoteDevice {
			let ordered = remote.paths.ordered()
			let candidate = wifiAvailable ? ordered.first : ordered.first(where: { $0.kind != .local })
			if let first = candidate { return .remote(first) }
		}

		// 3) Fallback: local mDNS only when WiFi is available.
		if wifiAvailable, let local = merged.localDevice {
			return .mdns(host: local.host, port: local.port)
		}

		return nil
	}

	private func remoteBaseURL(forCertificateCommonName cn: String) -> URL? {
		guard let remote = remoteDevices.first(where: { $0.certificateCommonName == cn }) else {
			if let staticRemoteDevice, staticRemoteDevice.certificateCommonName == cn {
				if let remotePath = staticRemoteDevice.paths.ordered().first(where: { $0.kind == .remote }) {
					return remotePath.apiBaseURL()
				}
				return staticRemoteDevice.paths.ordered().first?.apiBaseURL()
			}
			return nil
		}

		let ordered = remote.paths.ordered()
		if let remotePath = ordered.first(where: { $0.kind == .remote }) {
			return remotePath.apiBaseURL()
		}

		return nil
	}

	private func probeAll(_ devices: [RemoteDevice]) async throws -> [String: [String: PathProbe]] {
		try await withThrowingTaskGroup(of: (String, [String: PathProbe]).self) { group in
			for device in devices {
				group.addTask {
					let pathMap = await self.probePaths(of: device)
					return (device.certificateCommonName, pathMap)
				}
			}
			var dict: [String: [String: PathProbe]] = [:]
			for try await (cn, map) in group { dict[cn] = map }
			return dict
		}
	}

	nonisolated private func probePaths(of device: RemoteDevice) async -> [String: PathProbe] {
		let items: [(path: RemoteDevice.Path, url: URL, key: String)] =
			device.paths.ordered().compactMap { path in
				guard let url = path.apiBaseURL() else { return nil }
				return (path, url, path.key)
			}

		return await withTaskGroup(of: (String, PathProbe)?.self) { group in
			for item in items {
				group.addTask {
					let api = DeviceAPI(deviceBaseURL: item.url)

					// Spec: 4 s budget for local paths, 9 s for public/remote paths.
					let timeout: Double = item.path.kind == .local ? 4.0 : 9.0

					var status: Status?
					var about: About?

					do { status = try await self.withTimeout(timeout) { try await api.getStatus() } } catch {
#if DEBUG
						Log.debug("[STX-RA]: Failed to get status. URL: \(item.url). Error \(error)")
#endif
					}
					do { about  = try await self.withTimeout(timeout) { try await api.getAbout() } } catch {
#if DEBUG
						Log.debug("[STX-RA]: Failed to get about. URL: \(item.url). Error \(error)")
#endif
					}

					guard status != nil && about != nil else { return nil }

					let probe = PathProbe(
						source: .remotePath(item.path),
						status: status,
						about: about
					)
					return (item.key, probe)
				}
			}

			var map: [String: PathProbe] = [:]
			var foundReachable = false
			while let pair = await group.next() {
				if let (k, v) = pair {
					map[k] = v
					if v.isReachable && !foundReachable {
						foundReachable = true
					}
				}
			}
			return map
		}
	}

	private func appendMDNSProbeIfNeeded(_ probes: [PathProbe], local: LocalDevice) -> [PathProbe] {
		let about: About? = {
			guard let cn = local.certificateCommonName else { return nil }
			return About(hostname: local.host, certificate_common_name: cn, os_state: nil)
		}()
		let status = Status(state: .unknown, OOBE: .init(done: local.oobeIsDone), apps: nil)
		let mdnsProbe = PathProbe(source: .mdns(host: local.host, port: local.port), status: status, about: about)
		return probes + [mdnsProbe]
	}

	private func rebuildMerged(
		localDevices: [LocalDevice],
		remoteDevices: [RemoteDevice],
		remotePathProbesByCN: [String: [String: PathProbe]],
		staticRemoteDevice: RemoteDevice?
	) -> [MergedDevice] {
		var map: [String: MergedDevice] = [:]

		// Seed with remote devices
		for remote in remoteDevices {
			let probesDict = remotePathProbesByCN[remote.certificateCommonName] ?? [:]
			// Keep stable ordering: remote, public, local paths
			let orderedPaths = remote.paths.ordered()
			let probes: [PathProbe] = orderedPaths.compactMap { path in
				probesDict[path.key]
			}
			map[remote.certificateCommonName] = MergedDevice(
				remoteDevice: remote,
				localDevice: nil,
				pathProbes: probes
			)
		}

		// Merge local devices by certificate CN if available, otherwise by name
		for local in localDevices {
			if let certCN = local.certificateCommonName {
				if let existing = map[certCN] {
					map[certCN] = MergedDevice(
						remoteDevice: existing.remoteDevice,
						localDevice: local,
						pathProbes: appendMDNSProbeIfNeeded(existing.pathProbes, local: local)
					)
				} else {
					map[certCN] = MergedDevice(
						remoteDevice: nil,
						localDevice: local,
						pathProbes: appendMDNSProbeIfNeeded([], local: local)
					)
				}
		} else {
			// Spec: the merge key is always certificateCommonName.
			// A device without a CN has not yet been validated via the about endpoint.
			// Store it under a synthetic key so it is visible in the UI but cannot be
			// incorrectly merged with a remote device that has a real CN.
			let pendingKey = "__unresolved__\(local.name)"
			if let existing = map[pendingKey] {
				map[pendingKey] = MergedDevice(
					remoteDevice: existing.remoteDevice,
					localDevice: local,
					pathProbes: appendMDNSProbeIfNeeded(existing.pathProbes, local: local)
				)
			} else {
				map[pendingKey] = MergedDevice(
					remoteDevice: nil,
					localDevice: local,
					pathProbes: appendMDNSProbeIfNeeded([], local: local)
				)
			}
		}
		}

		var merged = Array(map.values).sorted { a, b in
			let nameA = a.remoteDevice?.friendlyName ?? a.localDevice?.name ?? ""
			let nameB = b.remoteDevice?.friendlyName ?? b.localDevice?.name ?? ""
			return nameA.localizedCaseInsensitiveCompare(nameB) == .orderedAscending
		}

		if let staticRemoteDevice {
			let probesDict = remotePathProbesByCN[staticRemoteDevice.certificateCommonName] ?? [:]
			let staticProbes = staticRemoteDevice.paths.compactMap { probesDict[$0.key] }
			let staticMerged = MergedDevice(
				remoteDevice: staticRemoteDevice,
				localDevice: nil,
				pathProbes: staticProbes
			)
			merged.insert(staticMerged, at: 0)
		}

		Log.debug("[STX-RA]: Merged: ")
		merged.forEach { Log.debug($0.asJSON() ?? "") }
		return merged
	}

	private func handleStaticDeviceAddressChange(_ address: String?) async {
		staticRemoteDevice = Self.buildStaticRemoteDevice(from: address)
		let merged = currentMerged()
		if let onUpdate { await MainActor.run { onUpdate(merged) } }
		recalculateBestURLs()
	}

	private static func buildStaticRemoteDevice(from address: String?) -> RemoteDevice? {
		guard let address, address.isEmpty == false else { return nil }
		guard let components = URLComponents(string: address) else { return nil }
		guard let host = components.host, host.isEmpty == false else { return nil }
		let path = RemoteDevice.Path(kind: .remote, address: address, port: nil)
		return RemoteDevice(
			seagateDeviceID: address,
			friendlyName: address,
			hostname: host,
			certificateCommonName: address,
			paths: [path]
		)
	}
}

// MARK: - URL Provider Bridge (OCBaseURLProvider)
@objcMembers
public final class DeviceReachabilityURLProvider: NSObject, OCBaseURLProvider {
	private let cacheQueue = DispatchQueue(label: "com.personalCloudFiles.best-url-cache", attributes: .concurrent)
	private var bestURLByCN: [String: URL] = [:]

	private let preferences: HCPreferences

	init(preferences: HCPreferences) {
		self.preferences = preferences
	}

	public func setBestURL(_ url: URL, for cn: String) {
		var previous: URL?
		cacheQueue.sync { previous = self.bestURLByCN[cn] }

		let changed: Bool = {
			guard let prev = previous else { return true }
			return (prev.scheme?.lowercased() != url.scheme?.lowercased())
				|| (prev.host?.lowercased() != url.host?.lowercased())
				|| (prev.port != url.port)
		}()

		// If host/port/scheme didn’t change, do nothing
		guard changed else { return }

		cacheQueue.async(flags: .barrier) { self.bestURLByCN[cn] = url }

		DispatchQueue.main.async {
			let bookmarks = OCBookmarkManager.shared.bookmarks
			for bookmark in bookmarks {
				// If the bookmark currently points to the previous host/port, update it to the new best host/port
				if let prev = previous, let bmURL = bookmark.url {
					let prevHost = prev.host?.lowercased()
					let bmHost = bmURL.host?.lowercased()
					let sameHost = (prevHost?.isEmpty == false) && (prevHost == bmHost)
					let prevPort = prev.port
					let bmPort = bmURL.port
					let portsEqual = (prevPort != nil) ? (prevPort == bmPort) : (bmPort == nil)
					if sameHost && portsEqual {
						var comps = URLComponents(url: bmURL, resolvingAgainstBaseURL: false)
						let newComps = URLComponents(url: url, resolvingAgainstBaseURL: false)
						if let newScheme = newComps?.scheme, !newScheme.isEmpty { comps?.scheme = newScheme }
						if let newHost = newComps?.host, !newHost.isEmpty { comps?.host = newHost }
						comps?.port = newComps?.port
						if let adjusted = comps?.url {
							bookmark.url = adjusted
							OCBookmarkManager.shared.updateBookmark(bookmark)
						}
					}
				}

				OCCoreManager.shared.requestCore(for: bookmark, setup: nil) { core, _ in
					guard let core else { return }
					// Only cancel existing traffic if we are switching away from a known base
					if previous != nil {
						core.connection.cancelAllRequestsForCurrentPartition()
					}
					core.connection.validateConnection(withReason: "Best URL switched", dueToResponseTo: nil)
				}
			}
		}
	}

	@objc(currentBaseURL)
	public func currentBaseURL() -> URL? {
		if let cn = preferences.favoriteDeviceCN,
		   let url = cachedBestURL(for: cn) {
			Log.debug("[STX-RA]: Returned best URL: \(url)")
			return url
		}
		return nil
	}

	public func clearAll() {
		cacheQueue.async(flags: .barrier) { self.bestURLByCN.removeAll() }
	}

	private func cachedBestURL(for cn: String) -> URL? {
		var url: URL?
		cacheQueue.sync { url = bestURLByCN[cn] }
		return url
	}
}
