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

	public func nextURLToAttempt(forCN cn: String, wifiAvailable: Bool) -> SelectedPath? {
		// Prefer reachable remote path by priority, skipping local-type paths when WiFi is absent.
		if let remote = remoteDevicesStore.first(where: { $0.certificateCommonName == cn }) {
			let probesDict = probesByCN[cn] ?? [:]
			for path in remote.paths.ordered() {
				guard path.kind != .local || wifiAvailable else { continue }
				if let probe = probesDict[path.key], probe.isOperational {
					return .remote(path)
				}
			}
		}
		if let staticRemoteDeviceStore, staticRemoteDeviceStore.certificateCommonName == cn {
			let probesDict = probesByCN[cn] ?? [:]
			for path in staticRemoteDeviceStore.paths.ordered() {
				if let probe = probesDict[path.key], probe.isOperational {
					return .remote(path)
				}
			}
			// Static device is a user-configured override — always offer its first path
			// even when no probe succeeded, so the SDK can keep trying.
			if let first = staticRemoteDeviceStore.paths.ordered().first {
				return .remote(first)
			}
		}

		// Fallback: local mDNS — only when WiFi is available (spec: local paths are WiFi-gated).
		if wifiAvailable, let local = localDevicesStore.first(where: { $0.certificateCommonName == cn }) {
			return .mdns(host: local.host, port: local.port)
		}

		return nil
	}

	public func reachableSelection(forCN cn: String, wifiAvailable: Bool) -> SelectedPath? {
		if let remote = remoteDevicesStore.first(where: { $0.certificateCommonName == cn }) {
			let probesDict = probesByCN[cn] ?? [:]
			for path in remote.paths.ordered() {
				guard path.kind != .local || wifiAvailable else { continue }
				if let probe = probesDict[path.key], probe.isOperational {
					return .remote(path)
				}
			}
		}
		if let staticRemoteDeviceStore, staticRemoteDeviceStore.certificateCommonName == cn {
			let probesDict = probesByCN[cn] ?? [:]
			for path in staticRemoteDeviceStore.paths.ordered() {
				if let probe = probesDict[path.key], probe.isOperational {
					return .remote(path)
				}
			}
			// Note: no first-path fallback here — `reachableSelection` requires evidence.
		}
		// Validated mDNS local: presence of a CN means we successfully fetched `about`,
		// which is positive evidence even though the synthetic probe has state == .unknown.
		if wifiAvailable,
		   let local = localDevicesStore.first(where: { $0.certificateCommonName == cn }) {
			return .mdns(host: local.host, port: local.port)
		}
		return nil
	}

	public nonisolated func nextURLToAttempt(for merged: MergedDevice, wifiAvailable: Bool) -> SelectedPath? {
		// 1) Prefer operational probes in priority order, skipping local-type paths when WiFi is absent.
		if let probe = merged.pathProbes.first(where: { probe in
			guard probe.isOperational else { return false }
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

	public nonisolated func reachableSelection(for merged: MergedDevice, wifiAvailable: Bool) -> SelectedPath? {
		if let probe = merged.pathProbes.first(where: { probe in
			guard probe.isOperational else { return false }
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

		// Validated mDNS local counts as reachable.
		if wifiAvailable, let local = merged.localDevice, local.certificateCommonName != nil {
			return .mdns(host: local.host, port: local.port)
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
