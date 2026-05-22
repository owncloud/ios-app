import Foundation
import ownCloudSDK

// MARK: - URL Provider Bridge (OCBaseURLProvider)
// Thread-safe: all mutable state is guarded by `cacheQueue`; `preferences` has its own
// internal queue. Marked `@unchecked Sendable` so it can be exposed `nonisolated` from
// `DeviceReachabilityService` and queried synchronously from UI code.
@objcMembers
public final class DeviceReachabilityURLProvider: NSObject, OCBaseURLProvider, @unchecked Sendable {
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

		let isFavoriteDevice = (cn == preferences.favoriteDeviceCN)
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

			if isFavoriteDevice {
				NotificationCenter.default.post(
					name: .hcBestBaseURLDidChange,
					object: nil,
					userInfo: [HCBestBaseURLNotification.urlUserInfoKey: url]
				)
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
		DispatchQueue.main.async {
			NotificationCenter.default.post(name: .hcBestBaseURLDidChange, object: nil)
		}
	}

	private func cachedBestURL(for cn: String) -> URL? {
		var url: URL?
		cacheQueue.sync { url = bestURLByCN[cn] }
		return url
	}
}
