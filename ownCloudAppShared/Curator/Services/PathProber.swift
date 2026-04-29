import Foundation
import ownCloudSDK

/// Pure transport layer for connectivity probes. Owns the timeout policy and the
/// `getStatus` + `getAbout` request pair; produces `PathProbe` values without touching
/// any actor / catalog state.
public struct PathProber: Sendable {
	/// Timeout budget for LAN paths (mDNS / local-type RA paths).
	public static let localTimeout: TimeInterval = 4.0
	/// Timeout budget for public / WAN / relay paths.
	public static let publicTimeout: TimeInterval = 9.0

	public init() {}

	// MARK: - Public API

	/// Probes every path of every device in parallel.
	///
	/// Result map: `[certificateCommonName: [Path.key: PathProbe]]`. Paths whose endpoints
	/// did not respond are dropped from the inner map (so `hasResponded == true` for every
	/// stored probe).
	public func probeAll(_ devices: [RemoteDevice]) async throws -> [String: [String: PathProbe]] {
		try await withThrowingTaskGroup(of: (String, [String: PathProbe]).self) { group in
			for device in devices {
				group.addTask {
					let pathMap = await probe(device)
					return (device.certificateCommonName, pathMap)
				}
			}
			var dict: [String: [String: PathProbe]] = [:]
			for try await (cn, map) in group { dict[cn] = map }
			return dict
		}
	}

	/// Probes every path of a single device in parallel.
	public func probe(_ device: RemoteDevice) async -> [String: PathProbe] {
		let items: [(path: RemoteDevice.Path, url: URL, key: String)] =
			device.paths.ordered().compactMap { path in
				guard let url = path.apiBaseURL() else { return nil }
				return (path, url, path.key)
			}

		return await withTaskGroup(of: (String, PathProbe)?.self) { group in
			for item in items {
				group.addTask {
					guard let probe = await Self.probe(path: item.path, url: item.url) else { return nil }
					return (item.key, probe)
				}
			}
			var map: [String: PathProbe] = [:]
			while let pair = await group.next() {
				if let (k, v) = pair { map[k] = v }
			}
			return map
		}
	}

	/// Spec Algorithm C: test local + public paths in parallel and return the best result
	/// using local-beats-public priority without waiting for all probes to finish.
	///
	/// Remote relay paths should NOT be passed here — call again with the relay subset for
	/// the relay fallback step.
	public func testPriorityPaths(_ paths: [RemoteDevice.Path]) async -> (path: RemoteDevice.Path, probe: PathProbe)? {
		guard !paths.isEmpty else { return nil }

		return await withTaskGroup(of: (RemoteDevice.Path, PathProbe?, Bool).self) { group in
			var localPending = 0
			for path in paths {
				let isLocal = path.kind == .local
				if isLocal { localPending += 1 }
				group.addTask {
					guard let url = path.apiBaseURL() else { return (path, nil, isLocal) }
					let probe = await Self.probe(path: path, url: url)
					return (path, probe, isLocal)
				}
			}

			var totalPending = paths.count
			var bestPublicResult: (RemoteDevice.Path, PathProbe)?

			while let (path, probe, isLocal) = await group.next() {
				if let probe, probe.isOperational {
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

	/// Single-call helper for the local-baseUrl shortcut: only fetches `about`, with the
	/// caller-supplied timeout. Used by Algorithm B step 1 where a fast yes/no is enough.
	public func fetchAbout(url: URL, timeout: TimeInterval = PathProber.localTimeout) async throws -> About {
		try await Self.withTimeout(timeout) {
			try await DeviceAPI(deviceBaseURL: url).getAbout()
		}
	}

	// MARK: - Internals

	/// Performs one full status+about probe and returns a `PathProbe` only if both
	/// endpoints responded. Failures are intentionally swallowed: not-responded ⇒ no probe.
	private static func probe(path: RemoteDevice.Path, url: URL) async -> PathProbe? {
		let api = DeviceAPI(deviceBaseURL: url)
		let timeout: TimeInterval = path.kind == .local ? localTimeout : publicTimeout

		var status: Status?
		var about: About?
		do { status = try await withTimeout(timeout) { try await api.getStatus() } } catch {
#if DEBUG
			Log.debug("[STX-RA]: Failed to get status. URL: \(url). Error \(error)")
#endif
		}
		do { about  = try await withTimeout(timeout) { try await api.getAbout()  } } catch {
#if DEBUG
			Log.debug("[STX-RA]: Failed to get about. URL: \(url). Error \(error)")
#endif
		}
		guard let s = status, let a = about else { return nil }
		return PathProbe(source: .remotePath(path), status: s, about: a)
	}

	/// Lightweight timeout helper. Throws `PathProberError.timedOut` after `seconds`.
	static func withTimeout<T: Sendable>(
		_ seconds: TimeInterval,
		operation: @escaping @Sendable () async throws -> T
	) async throws -> T {
		try await withThrowingTaskGroup(of: T.self) { group in
			group.addTask { try await operation() }
			group.addTask {
				try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
				throw PathProberError.timedOut
			}
			let value = try await group.next()!
			group.cancelAll()
			return value
		}
	}
}

/// Errors produced by `PathProber` itself. Endpoint errors (URLError, decoding, …) are
/// surfaced from `DeviceAPI` and not wrapped.
public enum PathProberError: Error {
	case timedOut
}
