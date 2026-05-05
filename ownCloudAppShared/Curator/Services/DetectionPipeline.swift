import Foundation
import ownCloudSDK

/// Spec Algorithm A: orchestrates the full reload pipeline (local mDNS discovery →
/// remote device discovery → path probing → URL recalculation → availability
/// reporting). Owns the per-pass `loadTask` / `detectionGeneration` cancel-and-restart
/// state. Algorithm B (direct path resolution) is delegated to `DirectPathResolver`,
/// which the pipeline holds and exposes via `attemptDirectResolution(...)`.
///
/// All side effects flow through the injected `emit` callback so the pipeline does not
/// need a back-reference to the facade. The `recalculateBestURLs` re-entrancy is
/// resolved by `[weak self]` capture inside the resolver, identical to the original
/// in-line implementation.
public actor DetectionPipeline {
	public typealias EmitEvent = @Sendable (DeviceReachabilityEvent) -> Void

	private let pathProber: PathProber
	private let pathCacheStore: PathCacheStore
	private let catalog: DeviceCatalog
	/// Constructed at the tail of `init` once `self` is fully initialised. Declared as
	/// IUO so the closure capture in its `recalculateBestURLs` argument can take a
	/// `[weak self]` reference without tripping definite-init.
	private var directResolver: DirectPathResolver!
	private let urlProvider: DeviceReachabilityURLProvider
	private let mdnsService: MDNSService
	private let remoteAccessService: RemoteAccessService
	private let preferences: HCPreferences
	private let availabilityMonitor: NetworkAvailabilityMonitor
	private nonisolated let reachability: ReachabilityObserving
	private let emit: EmitEvent

	private var loadTask: Task<[MergedDevice], Error>?
	private var isReloading: Bool = false
	/// Monotonically increasing counter. Each new detection pass takes a snapshot;
	/// any suspended prior pass sees a mismatch and exits early (cancel-and-restart).
	private var detectionGeneration: Int = 0

	public init(
		pathProber: PathProber,
		pathCacheStore: PathCacheStore,
		catalog: DeviceCatalog,
		urlProvider: DeviceReachabilityURLProvider,
		mdnsService: MDNSService,
		remoteAccessService: RemoteAccessService,
		preferences: HCPreferences,
		availabilityMonitor: NetworkAvailabilityMonitor,
		reachability: ReachabilityObserving,
		emit: @escaping EmitEvent
	) {
		self.pathProber = pathProber
		self.pathCacheStore = pathCacheStore
		self.catalog = catalog
		self.urlProvider = urlProvider
		self.mdnsService = mdnsService
		self.remoteAccessService = remoteAccessService
		self.preferences = preferences
		self.availabilityMonitor = availabilityMonitor
		self.reachability = reachability
		self.emit = emit

		self.directResolver = DirectPathResolver(
			pathProber: pathProber,
			pathCacheStore: pathCacheStore,
			catalog: catalog,
			preferences: preferences,
			remoteAccessService: remoteAccessService,
			availabilityMonitor: availabilityMonitor,
			emit: emit,
			recalculateBestURLs: { @Sendable [weak self] in
				await self?.recalculateBestURLs()
			}
		)
	}

	// MARK: - Reload status

	public func isReloadingNow() -> Bool {
		return isReloading
	}

	public func cancelLoadTask() {
		loadTask?.cancel()
		loadTask = nil
	}

	// MARK: - Fast reprobe (no device reload)

	public func reprobeExistingPaths() async {
		if isReloading { return }
		isReloading = true
		defer { isReloading = false }

		let remote = await catalog.remoteDevices()
		let probeTargets = probeTargets(from: remote)
		do {
			let probes = try await pathProber.probeAll(probeTargets)
			await catalog.setProbes(probes)
		} catch {
			Log.debug("[STX-RA]: Failed to probe device with error: \(error)")
		}
		let merged = await catalog.mergedDevices()
		emit(.devicesUpdated(merged))
		await recalculateBestURLs()
		await reportAvailabilityFromCurrentState()
	}

	// MARK: - Availability reporting

	/// Signals success / failure to the `NetworkAvailabilityMonitor` based on the most
	/// recent probe round. mDNS validations are reported separately via
	/// `handleMDNSUpdate`, so they are intentionally not considered here.
	///
	/// We look at `PathProbe.hasResponded` (not `isOperational` and not
	/// `nextURLToAttempt(...)`): the toast is about *connectivity*, so a box that
	/// answered our requests counts as "we have network" even if it happens to be
	/// in maintenance / pre-OOBE.
	public func reportAvailabilityFromCurrentState() async {
		let remote = await catalog.remoteDevices()
		guard !remote.isEmpty else { return }

		let probes = await catalog.probes()
		let anyReachable = probes.values.contains(where: { dict in
			dict.values.contains(where: { $0.hasResponded })
		})

		let toastKind = availabilityToastKind()
		Task { [availabilityMonitor] in
			if anyReachable {
				await availabilityMonitor.recordSuccess()
			} else {
				await availabilityMonitor.recordFailure(kind: toastKind)
			}
		}
	}

	// MARK: - mDNS

	public func handleMDNSUpdate(_ locals: [LocalDevice]) async {
		// Spec: local discovery is only useful on the same network as the device.
		// Skip mDNS results when WiFi is confirmed absent.
		// When the interface is .none (unknown), proceed rather than block (spec rule).
		let iface = reachability.currentState.interface
		guard iface == .wifi || iface == .none else {
			Log.debug("[STX-MDNS]: Skipping mDNS update — WiFi not available (interface: \(iface.rawValue)).")
			return
		}
		let previous = await catalog.localDevices()
		await catalog.setLocalDevices(locals)

		// Remember every validated local URL so Algorithm B step 1 can use it even after WiFi loss.
		for local in locals {
			guard let cn = local.certificateCommonName,
				  let url = URL(host: local.host, port: local.port) else { continue }
			await catalog.recordLocalURL(url, forCN: cn)
		}

		let merged = await catalog.mergedDevices()

		// Spec Algorithm A Phase 1: emit localDeviceFound for each newly CN-validated local device.
		for local in locals {
			guard let cn = local.certificateCommonName else { continue }
			let wasValidated = previous.contains(where: { $0.certificateCommonName == cn })
			if !wasValidated, let entry = merged.first(where: { $0.certificateCommonName == cn }) {
				emit(.localDeviceFound(entry))
			}
		}

		emit(.devicesUpdated(merged))

		if locals.contains(where: { $0.certificateCommonName != nil }) {
			Task { [availabilityMonitor] in await availabilityMonitor.recordSuccess() }
		}
	}

	// MARK: - Static device

	public func handleStaticDeviceAddressChange(_ address: String?) async {
		await catalog.setStaticRemoteDevice(Self.buildStaticRemoteDevice(from: address))
		emit(.devicesUpdated(await catalog.mergedDevices()))
		await recalculateBestURLs()
	}

	// MARK: - Merged devices

	public func getMergedDevices(
		email: String,
		includeRemote: Bool = true,
		probeRemotePaths: Bool = true
	) async throws -> [MergedDevice] {
		loadTask?.cancel()
		loadTask = Task.detached { [
			email,
			includeRemote,
			probeRemotePaths,
			catalog = self.catalog,
			remoteAccessService = self.remoteAccessService,
			pathProber = self.pathProber,
			pathCacheStore = self.pathCacheStore,
			emit = self.emit
		] in
			let remote: [RemoteDevice]
			if includeRemote {
				remote = try await remoteAccessService.getRemoteDevices(email: email)
			} else {
				remote = []
			}
			await catalog.setRemoteDevices(remote)
			await pathCacheStore.update(fromDevices: remote)
			for device in remote {
				emit(.remoteDeviceFound(device))
			}
			if Task.isCancelled { return [] }

			let probes: [String: [String: PathProbe]]
			if includeRemote, probeRemotePaths, remote.isEmpty == false {
				probes = (try? await pathProber.probeAll(remote)) ?? [:]
			} else {
				probes = [:]
			}
			await catalog.setProbes(probes)
			if Task.isCancelled { return [] }

			let merged = await catalog.mergedDevices()
			if probeRemotePaths {
				emit(.devicesUpdated(merged))
			}
			return merged
		}
		return try await loadTask!.value
	}

	// MARK: - Algorithm A: full reload

	public func reloadDevices() async {
		// Spec: cancel any active detection session and restart from a clean state.
		// Bump the generation so any suspended prior pass sees a mismatch and exits early.
		detectionGeneration &+= 1
		let myGen = detectionGeneration
		loadTask?.cancel()
		loadTask = nil
		isReloading = true
		defer {
			if detectionGeneration == myGen {
				isReloading = false
			}
		}

		// Spec Algorithm A: reset the temporary device map before each detection pass.
		await catalog.setRemoteDevices([])
		await catalog.setProbes([:])

		// Spec cancel-and-restart: stop mDNS and clear local state so the new detection
		// pass begins from a clean slate, then restart for the local discovery window.
		await catalog.clearLocalDevices()
		mdnsService.stop()
		mdnsService.start()

		// Spec Phase 1: local discovery window. Phase 2 (remote) starts only after this returns.
		await waitForLocalDiscovery(generation: myGen)
		guard detectionGeneration == myGen else { return }

		Log.debug("[STX-RA]: Reloading devices.")
		// Spec Algorithm A: only attempt remote discovery when authenticated.
		if let email = preferences.favoriteEmail,
		   await remoteAccessService.hasValidTokens() {
			_ = (try? await getMergedDevices(email: email, probeRemotePaths: false)) ?? []
			guard detectionGeneration == myGen else { return }
		}
		var remoteList = await catalog.remoteDevices()
		if remoteList.isEmpty, let saved = preferences.currentConnectedDevice {
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
			await catalog.setRemoteDevices([seeded])
			remoteList = [seeded]
		}
		// Spec Algorithm B is separate from Algorithm A: probe all paths after discovery completes.
		let probeTargets = probeTargets(from: remoteList)
		let probes = (try? await pathProber.probeAll(probeTargets)) ?? [:]
		guard detectionGeneration == myGen else { return }
		await catalog.setProbes(probes)
		emit(.devicesUpdated(await catalog.mergedDevices()))
		let localCount = await catalog.localDevices().count
		Log.debug("[STX-RA]: Remote count: \(remoteList.count). Local count: \(localCount).")
		await recalculateBestURLs()
		await reportAvailabilityFromCurrentState()

		// Spec Algorithm A: emit detectionComplete after all phases (local + remote) have finished.
		let finalMerged = await catalog.mergedDevices()
		emit(.detectionComplete(finalMerged))

		// Post-condition: if the preferred device has no reachable path after a full detection,
		// surface the auth-loss case (so the user can re-validate their email). General
		// unreachability is handled by `NetworkAvailabilityMonitor` via the toast.
		if let cn = preferences.favoriteDeviceCN {
			let wifi = wifiAvailableForLocalPaths
			let preferredReachable = finalMerged
				.first(where: { $0.certificateCommonName == cn })
				.flatMap { catalog.reachableSelection(for: $0, wifiAvailable: wifi) } != nil
			if !preferredReachable {
				Log.debug("[STX-RA]: Device \(cn) not reachable after full detection.")
				let tokensValid = await remoteAccessService.hasValidTokens()
				if !tokensValid, let email = preferences.favoriteEmail {
					emit(.emailValidationNeeded(email: email))
				}
			}
		}
	}

	// MARK: - URL recalculation

	public func recalculateBestURLs() async {
		let merged = await catalog.mergedDevices()
		let wifi = wifiAvailableForLocalPaths
		for device in merged {
			guard
				let cn = device.certificateCommonName,
				let path = catalog.nextURLToAttempt(for: device, wifiAvailable: wifi),
				let url = path.url
			else { continue }

			urlProvider.setBestURL(url, for: cn)
			if let favoriteCN = preferences.favoriteDeviceCN {
				emit(.remoteBaseURLChanged(await catalog.remoteBaseURL(forCN: favoriteCN)))
			} else {
				emit(.remoteBaseURLChanged(nil))
			}
		}
		Log.debug("[STX-RA]: Best RA URL: \(urlProvider.currentBaseURL()?.absoluteString ?? "")")
	}

	// MARK: - Algorithm B passthrough

	public func attemptDirectResolution(
		seagateDeviceID: String,
		certificateCommonName: String,
		wifiAvailable: Bool
	) async -> Bool {
		await directResolver.tryDirectPathResolution(
			seagateDeviceID: seagateDeviceID,
			certificateCommonName: certificateCommonName,
			wifiAvailable: wifiAvailable
		)
	}

	// MARK: - Helpers

	/// Spec Phase 1: wait up to 5 seconds for local mDNS discovery before starting remote.
	/// Exits immediately when local devices are already known, WiFi is unavailable, or the
	/// detection generation has been superseded by a newer call (cancel-and-restart).
	private func waitForLocalDiscovery(generation: Int) async {
		guard wifiAvailableForLocalPaths, await catalog.localDevices().isEmpty else { return }
		Log.debug("[STX-RA]: Waiting for local discovery window (up to 5 s)…")
		let deadline = Date().addingTimeInterval(5)
		while await catalog.localDevices().isEmpty && Date() < deadline && detectionGeneration == generation {
			try? await Task.sleep(nanoseconds: 100_000_000) // 100 ms poll
		}
		let count = await catalog.localDevices().count
		Log.debug("[STX-RA]: Local discovery window complete. Found \(count) device(s).")
	}

	/// Public so the coordinator can derive `wifiAvailable` for direct-resolution calls
	/// without holding its own reachability reference.
	public nonisolated var wifiAvailableForLocalPaths: Bool {
		let iface = reachability.currentState.interface
		return iface == .wifi || iface == .none
	}

	private nonisolated func availabilityToastKind() -> NetworkAvailabilityToastKind {
		reachability.currentState.isReachable ? .noInternet : .findingNetwork
	}

	/// Restrict probing to the currently connected/preferred device.
	/// This avoids probing every known device on each periodic/event-driven reload.
	private func probeTargets(from remoteDevices: [RemoteDevice]) -> [RemoteDevice] {
		guard remoteDevices.isEmpty == false else { return [] }

		if let saved = preferences.currentConnectedDevice {
			if let seagateDeviceID = saved.seagateDeviceID, !seagateDeviceID.isEmpty {
				let byID = remoteDevices.filter { $0.seagateDeviceID == seagateDeviceID }
				if byID.isEmpty == false { return byID }
			}

			let bySavedCN = remoteDevices.filter { $0.certificateCommonName == saved.certificateCommonName }
			if bySavedCN.isEmpty == false { return bySavedCN }
		}

		if let favoriteCN = preferences.favoriteDeviceCN {
			let byFavoriteCN = remoteDevices.filter { $0.certificateCommonName == favoriteCN }
			if byFavoriteCN.isEmpty == false { return byFavoriteCN }
		}

		return []
	}

	static func buildStaticRemoteDevice(from address: String?) -> RemoteDevice? {
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
