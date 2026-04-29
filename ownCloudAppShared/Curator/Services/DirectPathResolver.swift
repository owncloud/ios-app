import Foundation
import ownCloudSDK

/// Spec Algorithm B: find the best connection for a known device without a full re-discovery.
///
/// Stateless helper — every dependency is injected at construction. Held by the detection
/// pipeline (Pass E); the facade no longer owns Algorithm B directly.
///
/// Steps:
///   1. Fast path — test the known local baseUrl directly (no WiFi check).
///   2. Get cached or freshly-fetched paths and run Algorithm C priority test.
///   3. Refresh the cache once if step 2 used expired paths.
///   4. Relay-only fallback.
///
/// Returns `true` when one of the steps committed a winning path; `false` to signal
/// the caller it should escalate to a full reload (Algorithm A).
public struct DirectPathResolver: Sendable {
	public typealias EmitEvent = @Sendable (DeviceReachabilityEvent) -> Void
	public typealias RecalculateBestURLs = @Sendable () async -> Void

	private let pathProber: PathProber
	private let pathCacheStore: PathCacheStore
	private let catalog: DeviceCatalog
	private let preferences: HCPreferences
	private let remoteAccessService: RemoteAccessService
	private let availabilityMonitor: NetworkAvailabilityMonitor
	private let emit: EmitEvent
	private let recalculateBestURLs: RecalculateBestURLs

	public init(
		pathProber: PathProber,
		pathCacheStore: PathCacheStore,
		catalog: DeviceCatalog,
		preferences: HCPreferences,
		remoteAccessService: RemoteAccessService,
		availabilityMonitor: NetworkAvailabilityMonitor,
		emit: @escaping EmitEvent,
		recalculateBestURLs: @escaping RecalculateBestURLs
	) {
		self.pathProber = pathProber
		self.pathCacheStore = pathCacheStore
		self.catalog = catalog
		self.preferences = preferences
		self.remoteAccessService = remoteAccessService
		self.availabilityMonitor = availabilityMonitor
		self.emit = emit
		self.recalculateBestURLs = recalculateBestURLs
	}

	public func tryDirectPathResolution(
		seagateDeviceID: String,
		certificateCommonName: String,
		wifiAvailable: Bool
	) async -> Bool {
		// Step 1: test the known local baseUrl directly — no WiFi check (spec WiFi exception).
		// Prefer in-memory localDevices; fall back to lastKnownLocalURL which survives WiFi loss.
		let locals = await catalog.localDevices()
		let localURLFromMDNS: URL? = locals
			.first(where: { $0.certificateCommonName == certificateCommonName })
			.flatMap { URL(host: $0.host, port: $0.port) }
		let localURL: URL?
		if let url = localURLFromMDNS {
			localURL = url
		} else {
			localURL = await catalog.lastKnownLocalURL(forCN: certificateCommonName)
		}

		if let url = localURL {
			do {
				let about = try await pathProber.fetchAbout(url: url)
				if about.certificate_common_name == certificateCommonName {
					Log.debug("[STX-RA]: Local baseUrl shortcut succeeded for \(certificateCommonName).")
					emit(.devicesUpdated(await catalog.mergedDevices()))
					await recalculateBestURLs()
					return true
				}
			} catch {
				Log.debug("[STX-RA]: Local baseUrl shortcut failed: \(error). Proceeding to backend.")
			}
		}

		guard await remoteAccessService.hasValidTokens() else { return false }

		// Step 2: get paths from cache (spec: reuse even if expired; only fetch fresh if no cache at all).
		// Expired cached paths are still tested first. Fresh paths are only fetched in step 4,
		// after all cached priority paths fail AND the cache is confirmed expired.
		let cachedEntry = await pathCacheStore.paths(forCN: certificateCommonName)
		let fromCache = cachedEntry != nil
		var allPaths: [RemoteDevice.Path]

		if let cached = cachedEntry {
			allPaths = cached.paths
			Log.debug("[STX-RA]: Using cached paths for \(certificateCommonName) (expired: \(cached.isExpired)).")
		} else {
			do {
				allPaths = try await remoteAccessService.getPathsForDevice(seagateDeviceID: seagateDeviceID)
				await pathCacheStore.set(forCN: certificateCommonName, paths: allPaths)
			} catch {
				Log.debug("[STX-RA]: Failed to fetch paths for \(certificateCommonName): \(error).")
				return false
			}
		}

		guard !allPaths.isEmpty else { return false }

		// Step 3: Algorithm C — test local + public paths with priority early-return.
		var priorityPaths = allPaths.filter { $0.kind != .remote }
		if !wifiAvailable { priorityPaths = priorityPaths.filter { $0.kind != .local } }

		if let (best, probe) = await pathProber.testPriorityPaths(priorityPaths) {
			return await commitDirectResolution(
				certificateCommonName: certificateCommonName, seagateDeviceID: seagateDeviceID,
				allPaths: allPaths, winningPath: best, winningProbe: probe
			)
		}

		// Step 4: if paths came from cache and cache is now expired, refresh once.
		if fromCache, cachedEntry?.isExpired == true {
			do {
				let freshPaths = try await remoteAccessService.getPathsForDevice(seagateDeviceID: seagateDeviceID)
				if Self.pathsAreEqual(freshPaths, allPaths) {
					// Spec: identical paths — refresh timestamp only, do not re-test.
					await pathCacheStore.refreshTimestamp(forCN: certificateCommonName)
					Log.debug("[STX-RA]: Cache refreshed (paths unchanged) for \(certificateCommonName).")
				} else {
					await pathCacheStore.set(forCN: certificateCommonName, paths: freshPaths)
					var freshPriority = freshPaths.filter { $0.kind != .remote }
					if !wifiAvailable { freshPriority = freshPriority.filter { $0.kind != .local } }
					if let (best, probe) = await pathProber.testPriorityPaths(freshPriority) {
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
		if let (best, probe) = await pathProber.testPriorityPaths(relayPaths) {
			return await commitDirectResolution(
				certificateCommonName: certificateCommonName, seagateDeviceID: seagateDeviceID,
				allPaths: allPaths, winningPath: best, winningProbe: probe
			)
		}

		Log.debug("[STX-RA]: Direct path resolution failed for \(certificateCommonName). Falling back to full reload.")
		return false
	}

	/// Stores a successful direct-resolution result (in the catalog) and notifies observers.
	private func commitDirectResolution(
		certificateCommonName: String,
		seagateDeviceID: String,
		allPaths: [RemoteDevice.Path],
		winningPath: RemoteDevice.Path,
		winningProbe: PathProbe
	) async -> Bool {
		let existing = await catalog.remoteDevice(forCN: certificateCommonName)
		let device: RemoteDevice?
		if let existing {
			device = RemoteDevice(
				seagateDeviceID: existing.seagateDeviceID,
				friendlyName: existing.friendlyName,
				hostname: existing.hostname,
				certificateCommonName: certificateCommonName,
				paths: allPaths
			)
		} else if let saved = preferences.currentConnectedDevice {
			device = RemoteDevice(
				seagateDeviceID: seagateDeviceID,
				friendlyName: saved.friendlyName ?? "",
				hostname: saved.hostname ?? "",
				certificateCommonName: certificateCommonName,
				paths: allPaths
			)
		} else {
			device = nil
		}
		if let device {
			await catalog.upsertResolution(device, winningPathKey: winningPath.key, winningProbe: winningProbe)
		}
		emit(.devicesUpdated(await catalog.mergedDevices()))
		await recalculateBestURLs()
		Task { [availabilityMonitor] in await availabilityMonitor.recordSuccess() }
		Log.debug("[STX-RA]: Direct path resolution succeeded (\(winningPath.kind)) for \(certificateCommonName).")
		return true
	}

	private static func pathsAreEqual(_ a: [RemoteDevice.Path], _ b: [RemoteDevice.Path]) -> Bool {
		Set(a.map(\.key)) == Set(b.map(\.key))
	}
}
