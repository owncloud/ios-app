import Foundation
import ownCloudSDK

/// Owns the merged-device catalog: remote-discovery results, mDNS locals, latest path probes,
/// the optional user-configured static device, and the per-CN "last good local URL" cache
/// used for the Algorithm B fast path.
///
/// Reachability-free by design — every path-selection method takes `wifiAvailable` as a
/// parameter, so the catalog can be used from any context (detection pipeline, FSM, facade)
/// without coupling to the live `ReachabilityObserving` instance.
public actor DeviceCatalog {
	private var remoteDevicesStore: [RemoteDevice] = []
	private var localDevicesStore: [LocalDevice] = []
	private var probesByCN: [String: [String: PathProbe]] = [:]
	private var lastKnownLocalURLByCN: [String: URL] = [:]
	private var staticRemoteDeviceStore: RemoteDevice?

	public init() {}

	// MARK: - Reads

	public func remoteDevices() -> [RemoteDevice] { remoteDevicesStore }
	public func localDevices() -> [LocalDevice] { localDevicesStore }
	public func probes() -> [String: [String: PathProbe]] { probesByCN }
	public func staticRemoteDevice() -> RemoteDevice? { staticRemoteDeviceStore }
	public func lastKnownLocalURL(forCN cn: String) -> URL? { lastKnownLocalURLByCN[cn] }
	public func remoteDevice(forCN cn: String) -> RemoteDevice? {
		remoteDevicesStore.first(where: { $0.certificateCommonName == cn })
	}

	// MARK: - Writes

	public func setRemoteDevices(_ devices: [RemoteDevice]) {
		remoteDevicesStore = devices
	}

	public func upsertRemoteDevice(_ device: RemoteDevice) {
		if let idx = remoteDevicesStore.firstIndex(where: { $0.certificateCommonName == device.certificateCommonName }) {
			remoteDevicesStore[idx] = device
		} else {
			remoteDevicesStore.append(device)
		}
	}

	public func setLocalDevices(_ devices: [LocalDevice]) {
		localDevicesStore = devices
	}

	public func clearLocalDevices() {
		localDevicesStore = []
	}

	public func setProbes(_ probes: [String: [String: PathProbe]]) {
		probesByCN = probes
	}

	public func setStaticRemoteDevice(_ device: RemoteDevice?) {
		staticRemoteDeviceStore = device
	}

	public func recordLocalURL(_ url: URL, forCN cn: String) {
		lastKnownLocalURLByCN[cn] = url
	}

	/// Atomic update used by `commitDirectResolution`: replaces or appends a remote device
	/// by CN, then sets a single winning probe as the only probe for that CN.
	public func upsertResolution(
		_ device: RemoteDevice,
		winningPathKey: String,
		winningProbe: PathProbe
	) {
		if let idx = remoteDevicesStore.firstIndex(where: { $0.certificateCommonName == device.certificateCommonName }) {
			remoteDevicesStore[idx] = device
		} else {
			remoteDevicesStore.append(device)
		}
		probesByCN[device.certificateCommonName] = [winningPathKey: winningProbe]
	}

	public func clear() {
		remoteDevicesStore = []
		localDevicesStore = []
		probesByCN = [:]
		lastKnownLocalURLByCN = [:]
		// `staticRemoteDeviceStore` is owned by the user-configured static address and is
		// reset separately by the address-change handler — not on logout.
	}

	// MARK: - Merged view

	/// Builds the current merged view from in-actor state. Spec: merge key is always
	/// `certificateCommonName`; locals without a CN go under a synthetic key so they are
	/// still visible but cannot be incorrectly merged with a CN-bearing remote device.
	public func mergedDevices() -> [MergedDevice] {
		var map: [String: MergedDevice] = [:]

		// Seed with remote devices
		for remote in remoteDevicesStore {
			let probesDict = probesByCN[remote.certificateCommonName] ?? [:]
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
		for local in localDevicesStore {
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

		if let staticRemoteDeviceStore {
			let probesDict = probesByCN[staticRemoteDeviceStore.certificateCommonName] ?? [:]
			let staticProbes = staticRemoteDeviceStore.paths.compactMap { probesDict[$0.key] }
			let staticMerged = MergedDevice(
				remoteDevice: staticRemoteDeviceStore,
				localDevice: nil,
				pathProbes: staticProbes
			)
			merged.insert(staticMerged, at: 0)
		}

		Log.debug("[STX-RA]: Merged: ")
		merged.forEach { Log.debug($0.asJSON() ?? "") }
		return merged
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

	// MARK: - Path selection (caller passes `wifiAvailable`)

	/// First path in `paths.ordered()` whose kind matches `predicate` and whose probe is
	/// operational. Used by the `forCN`-keyed selectors which look up probes by path key.
	private static func firstOperationalPath(
		_ paths: [RemoteDevice.Path],
		probes: [String: PathProbe],
		where predicate: (RemoteDevice.Path.Kind) -> Bool
	) -> RemoteDevice.Path? {
		for path in paths.ordered() where predicate(path.kind) {
			if probes[path.key]?.isOperational == true {
				return path
			}
		}
		return nil
	}

	/// First `.remotePath` probe whose kind matches `predicate` and is operational, in
	/// array order. Used by the merged-device selectors which iterate already-ordered
	/// probes attached to the merged record.
	private static func firstOperationalProbePath(
		_ probes: [PathProbe],
		where predicate: (RemoteDevice.Path.Kind) -> Bool
	) -> RemoteDevice.Path? {
		for probe in probes {
			guard probe.isOperational,
			      case let .remotePath(path) = probe.source,
			      predicate(path.kind)
			else { continue }
			return path
		}
		return nil
	}

	public func nextURLToAttempt(
		forCN cn: String,
		wifiAvailable: Bool,
		preferredPathKey: String? = nil
	) -> SelectedPath? {
		let probesDict = probesByCN[cn] ?? [:]
		let dynamicRemote = remoteDevicesStore.first(where: { $0.certificateCommonName == cn })
		let staticRemote: RemoteDevice? = {
			guard let static_ = staticRemoteDeviceStore, static_.certificateCommonName == cn else { return nil }
			return static_
		}()

		// 1) LOCAL tier. Spec: "If we have local matching device we should use it."
		if wifiAvailable {
			// 1a) Operational RA `.local` probe on the dynamic device.
			if let remote = dynamicRemote,
			   let localPath = Self.firstOperationalPath(remote.paths, probes: probesDict, where: { $0 == .local }) {
				return .remote(localPath)
			}
			// 1a') Operational RA `.local` probe on the static device.
			if let remote = staticRemote,
			   let localPath = Self.firstOperationalPath(remote.paths, probes: probesDict, where: { $0 == .local }) {
				return .remote(localPath)
			}
			// 1b) CN-validated mDNS local.
			if let local = localDevicesStore.first(where: { $0.certificateCommonName == cn }) {
				return .mdns(host: local.host, port: local.port)
			}
		}

		// 2) NON-LOCAL tier: operational .public / .remote probes in priority order.
		if let remote = dynamicRemote,
		   let path = Self.firstOperationalPath(remote.paths, probes: probesDict, where: { $0 != .local }) {
			return .remote(path)
		}
		if let remote = staticRemote,
		   let path = Self.firstOperationalPath(remote.paths, probes: probesDict, where: { $0 != .local }) {
			return .remote(path)
		}

		// 3) Cold launch / relaunch: retry last successful path before defaulting.
		if let preferredPathKey, let remote = dynamicRemote,
		   let preferred = SelectedPath.matching(
		   	persistenceKey: preferredPathKey,
		   	paths: remote.paths,
		   	localDevice: localDevicesStore.first(where: { $0.certificateCommonName == cn }),
		   	wifiAvailable: wifiAvailable
		   ) {
			return preferred
		}
		if let preferredPathKey, let remote = staticRemote,
		   let preferred = SelectedPath.matching(
		   	persistenceKey: preferredPathKey,
		   	paths: remote.paths,
		   	localDevice: nil,
		   	wifiAvailable: wifiAvailable
		   ) {
			return preferred
		}

		// 4) Static device fallback: user-configured override — always offer its first
		// non-local path even when no probe succeeded, so the SDK can keep trying.
		if let remote = staticRemote,
		   let first = remote.paths.ordered().first(where: { $0.kind != .local }) {
			return .remote(first)
		}

		return nil
	}

	public func reachableSelection(forCN cn: String, wifiAvailable: Bool) -> SelectedPath? {
		let probesDict = probesByCN[cn] ?? [:]
		let dynamicRemote = remoteDevicesStore.first(where: { $0.certificateCommonName == cn })
		let staticRemote: RemoteDevice? = {
			guard let static_ = staticRemoteDeviceStore, static_.certificateCommonName == cn else { return nil }
			return static_
		}()

		// 1) LOCAL tier — when any local-source evidence exists, prefer it.
		// Validated mDNS local: presence of a CN means we successfully fetched `about`,
		// which is positive evidence even though the synthetic probe has state == .unknown.
		if wifiAvailable {
			if let remote = dynamicRemote,
			   let localPath = Self.firstOperationalPath(remote.paths, probes: probesDict, where: { $0 == .local }) {
				return .remote(localPath)
			}
			if let remote = staticRemote,
			   let localPath = Self.firstOperationalPath(remote.paths, probes: probesDict, where: { $0 == .local }) {
				return .remote(localPath)
			}
			if let local = localDevicesStore.first(where: { $0.certificateCommonName == cn }) {
				return .mdns(host: local.host, port: local.port)
			}
		}

		// 2) NON-LOCAL tier — operational .public / .remote probes only.
		// No first-path fallback here — `reachableSelection` requires evidence.
		if let remote = dynamicRemote,
		   let path = Self.firstOperationalPath(remote.paths, probes: probesDict, where: { $0 != .local }) {
			return .remote(path)
		}
		if let remote = staticRemote,
		   let path = Self.firstOperationalPath(remote.paths, probes: probesDict, where: { $0 != .local }) {
			return .remote(path)
		}
		return nil
	}

	public nonisolated func nextURLToAttempt(
		for merged: MergedDevice,
		wifiAvailable: Bool,
		preferredPathKey: String? = nil
	) -> SelectedPath? {
		// 1) LOCAL tier. Spec: "If we have local matching device we should use it."
		// Any local-source signal wins over .public / .remote.
		if wifiAvailable {
			// 1a) Operational RA probe with kind == .local — actively verified end-to-end.
			if let path = Self.firstOperationalProbePath(merged.pathProbes, where: { $0 == .local }) {
				return .remote(path)
			}
			// 1b) CN-validated mDNS local — non-nil CN means `about` succeeded recently.
			if let local = merged.localDevice, local.certificateCommonName != nil {
				return .mdns(host: local.host, port: local.port)
			}
		}

		// 2) NON-LOCAL tier: operational .public / .remote probes in priority order.
		if let path = Self.firstOperationalProbePath(merged.pathProbes, where: { $0 != .local }) {
			return .remote(path)
		}

		// 3) Cold launch / relaunch: retry last successful path before defaulting.
		if let preferredPathKey, let remote = merged.remoteDevice,
		   let preferred = SelectedPath.matching(
		   	persistenceKey: preferredPathKey,
		   	paths: remote.paths,
		   	localDevice: merged.localDevice,
		   	wifiAvailable: wifiAvailable
		   ) {
			return preferred
		}

		// 4) Fallback: first ordered non-local remote path (unprobed).
		// Tier 1 already covered all local signals, so we never offer .local here.
		if let remote = merged.remoteDevice,
		   let first = remote.paths.ordered().first(where: { $0.kind != .local }) {
			return .remote(first)
		}

		return nil
	}

	public nonisolated func reachableSelection(for merged: MergedDevice, wifiAvailable: Bool) -> SelectedPath? {
		// 1) LOCAL tier — operational RA `.local` probe or CN-validated mDNS local.
		if wifiAvailable {
			if let path = Self.firstOperationalProbePath(merged.pathProbes, where: { $0 == .local }) {
				return .remote(path)
			}
			if let local = merged.localDevice, local.certificateCommonName != nil {
				return .mdns(host: local.host, port: local.port)
			}
		}

		// 2) NON-LOCAL tier — operational .public / .remote probes.
		if let path = Self.firstOperationalProbePath(merged.pathProbes, where: { $0 != .local }) {
			return .remote(path)
		}

		return nil
	}

	// MARK: - Static-device base URL

	public func remoteBaseURL(forCN cn: String) -> URL? {
		if let remote = remoteDevicesStore.first(where: { $0.certificateCommonName == cn }) {
			let ordered = remote.paths.ordered()
			if let remotePath = ordered.first(where: { $0.kind == .remote }) {
				return remotePath.apiBaseURL()
			}
			return nil
		}
		if let staticRemoteDeviceStore, staticRemoteDeviceStore.certificateCommonName == cn {
			if let remotePath = staticRemoteDeviceStore.paths.ordered().first(where: { $0.kind == .remote }) {
				return remotePath.apiBaseURL()
			}
			return staticRemoteDeviceStore.paths.ordered().first?.apiBaseURL()
		}
		return nil
	}
}
