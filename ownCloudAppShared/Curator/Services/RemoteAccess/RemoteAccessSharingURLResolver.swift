import Foundation

public enum RemoteAccessSharingURLResolver {
	public static func resolveRemoteSharingURLSync(for url: URL?) -> URL? {
		guard let url, let remoteBaseURL = HCContext.shared.lastRemoteBaseURL else { return nil }
		return RemoteAccessSharingURLResolver.applyRemoteBase(remoteBaseURL, to: url)
	}

	public static func resolveRemoteSharingURL(
		for url: URL,
		completion: @escaping (URL?) -> Void
	) {
		Task {
			let resolved = await resolveRemoteSharingURL(for: url)
			await MainActor.run {
				completion(resolved)
			}
		}
	}

	public static func resolveRemoteSharingURL(for url: URL) async -> URL? {
		let deviceService = HCContext.shared.deviceReachabilityService

		if let remoteBaseURL = await deviceService.currentRemoteBaseURL(),
		   let adjusted = applyRemoteBase(remoteBaseURL, to: url) {
			return adjusted
		}

		guard let email = HCContext.shared.preferences.favoriteEmail else {
			return nil
		}

		let hasTokens = await HCContext.shared.remoteAccessService.hasValidTokens()
		if hasTokens == false {
			Log.debug("[STX-RA]: Has no valid tokens. Requesting email verification.")
			let authenticated = await requestEmailVerification(email: email)
			guard authenticated else { return nil }
		}

		await deviceService.forceReloadDevices()

		guard let remoteBaseURL = await deviceService.currentRemoteBaseURL() else {
			return nil
		}
		return applyRemoteBase(remoteBaseURL, to: url)
	}

	private static func applyRemoteBase(_ baseURL: URL, to url: URL) -> URL? {
		let baseComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
		guard var updatedComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
			return nil
		}

		let scheme = baseComponents?.scheme ?? updatedComponents.scheme
		let host = baseComponents?.host ?? updatedComponents.host
		let port = baseComponents?.port

		updatedComponents.scheme = scheme
		updatedComponents.host = host
		updatedComponents.port = port

		return updatedComponents.url
	}

	private static func requestEmailVerification(email: String) async -> Bool {
		guard let handler = HCContext.shared.emailVerificationHandler else {
			return false
		}

		return await withCheckedContinuation { continuation in
			Task { @MainActor in
				handler(email) { isAuthenticated in
					continuation.resume(returning: isAuthenticated)
				}
			}
		}
	}
}
