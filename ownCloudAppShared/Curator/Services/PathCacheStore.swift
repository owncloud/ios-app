import Foundation
import ownCloudSDK

/// Owns the per-device path cache with a 1-hour TTL. Persists to `HCPreferences` on every
/// mutation so the cache survives app restarts.
public actor PathCacheStore {
	/// One cache entry: paths previously fetched from RA plus the timestamp at which they
	/// were captured. Spec: cache expires after 1 hour but expired paths are still tested
	/// before refetching.
	public struct CachedPaths: Codable, Sendable {
		public var paths: [RemoteDevice.Path]
		public var timestamp: Date
		public var isExpired: Bool { Date().timeIntervalSince(timestamp) > 3600 }

		public init(paths: [RemoteDevice.Path], timestamp: Date) {
			self.paths = paths
			self.timestamp = timestamp
		}
	}

	private var entries: [String: CachedPaths] = [:]
	private let preferences: HCPreferences

	public init(preferences: HCPreferences) {
		self.preferences = preferences
		if let data = preferences.cachedDevicePathsData,
		   let restored = try? JSONDecoder().decode([String: CachedPaths].self, from: data) {
			entries = restored
		}
	}

	// MARK: - Reads

	public func paths(forCN cn: String) -> CachedPaths? {
		entries[cn]
	}

	// MARK: - Writes (always persist)

	/// Replaces all cache entries for the given devices with fresh timestamps.
	public func update(fromDevices devices: [RemoteDevice]) {
		for device in devices {
			entries[device.certificateCommonName] = CachedPaths(paths: device.paths, timestamp: Date())
		}
		persist()
	}

	/// Sets a single entry; call when fresh paths arrive from RA.
	public func set(forCN cn: String, paths: [RemoteDevice.Path], timestamp: Date = Date()) {
		entries[cn] = CachedPaths(paths: paths, timestamp: timestamp)
		persist()
	}

	/// Bumps the timestamp on an existing entry; spec: when refetched paths are unchanged.
	public func refreshTimestamp(forCN cn: String) {
		guard entries[cn] != nil else { return }
		entries[cn]?.timestamp = Date()
		persist()
	}

	/// Wipes the in-memory map and the persisted blob (e.g. on logout).
	public func clear() {
		entries = [:]
		preferences.cachedDevicePathsData = nil
	}

	// MARK: - Internals

	private func persist() {
		if let data = try? JSONEncoder().encode(entries) {
			preferences.cachedDevicePathsData = data
		}
	}
}
