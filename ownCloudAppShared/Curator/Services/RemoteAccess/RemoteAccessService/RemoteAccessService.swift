import Foundation
import UIKit

private enum Constants {
	static var clientId: String {
		UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
	}

	static var clientFriendlyName: String {
		UIDevice.current.name
	}
}

public enum RemoteAccessServiceError: Error, Sendable {
	case missingTokens
	case apiError(RemoteAccessAPIError)
	case unexpected(AnySendableError)
}

public actor RemoteAccessService {
	private let api: RemoteAccessAPI
	private let tokenStore: RemoteAccessTokenStore

	/// Only one token refresh / exchange at a time; other callers wait for its result.
	private var isUpdatingTokens = false
	private var tokenUpdateWaiters: [CheckedContinuation<String, Error>] = []

	public init(api: RemoteAccessAPI, tokenStore: RemoteAccessTokenStore) {
		self.api = api
		self.tokenStore = tokenStore
	}

	public func sendEmailCode(email: String) async throws -> RAInitiateResponse {
		try await mapErrors {
			try await api.sendEmailCode(
				email: email,
				clientId: Constants.clientId,
				clientFriendlyName: Constants.clientFriendlyName
			)
		}
	}

	public func validateEmailCode(code: String, reference: String) async throws {
		let token = try await performTokenUpdate {
			try await self.api.validateEmailCode(
				code: code,
				clientId: Constants.clientId,
				reference: reference
			)
		}
		api.accessToken = token
	}

	public func listDevices(clientId: String) async throws -> [RADevice] {
		return try await authedCall(clientId: clientId) {
			try await api.listDevices()
		}
	}

	public func getDevicePaths(clientId: String, deviceID: String) async throws -> RADevicePaths {
		try await authedCall(clientId: clientId) {
			try await api.getDevicePaths(deviceID: deviceID)
		}
	}

	public func hasValidTokens() async -> Bool {
		do {
			_ = try await ensureValidAccessToken(clientId: Constants.clientId)
			return true
		} catch let error as RemoteAccessServiceError {
			switch error {
				case .missingTokens:
					Log.debug("[STX-RA]: Tokens are missing.")
					return false

				case let .apiError(apiError):
					switch apiError {
						case .forbidden, .unauthorized:
							Log.debug("[STX-RA]: forbiden or unauthorized after token refresh.")
							return false

						case let .httpStatus(statusCode, _):
							if (400...499).contains(statusCode) {
								_ = tokenStore.clear()
								Log.debug("[STX-RA]: \(statusCode) after token refresh.")
								return false
							} else {
								return true
							}

						default:
							return true
					}

				default:
					return true
			}
		} catch is URLError {
			return true
		} catch {
			return true
		}
	}

	public func clearTokens() {
		failTokenUpdateWaiters(CancellationError())
		isUpdatingTokens = false
		_ = tokenStore.clear()
		api.accessToken = nil
	}

	/// Fetches and maps connection paths for a single known device without a full device-list round-trip.
	public func getPathsForDevice(seagateDeviceID: String) async throws -> [RemoteDevice.Path] {
		let raPaths = try await getDevicePaths(clientId: Constants.clientId, deviceID: seagateDeviceID)
		return raPaths.paths.map { RemoteDevice.Path(raDevicePath: $0) }
	}

	public func getRemoteDevices(email: String) async throws -> [RemoteDevice] {
		let apiDevices = try await listDevices(clientId: Constants.clientId)
		return try await withThrowingTaskGroup(of: RemoteDevice.self) { group in
			for device in apiDevices {
				group.addTask {
					let paths = try await self.getDevicePaths(clientId: Constants.clientId, deviceID: device.seagateDeviceID)
					return RemoteDevice(raDevice: device, raDevicePaths: paths)
				}
			}

			var gathered: [RemoteDevice] = []
			for try await item in group {
				gathered.append(item)
			}
			return gathered
		}
	}

	private func mapErrors<T>(_ body: @Sendable () async throws -> T) async throws -> T {
		do {
			return try await body()
		} catch let error as RemoteAccessServiceError {
			throw error
		} catch let error as RemoteAccessAPIError {
			throw RemoteAccessServiceError.apiError(error)
		} catch {
			throw RemoteAccessServiceError.unexpected(.init(error))
		}
	}

	private func authedCall<T>(
		clientId: String,
		_ body: @Sendable () async throws -> T
	) async throws -> T {
		if isUpdatingTokens {
			let token = try await waitForInFlightTokenUpdate()
			api.accessToken = token
			return try await executeAuthedBodyWithUnauthorizedRetry(clientId: clientId, body: body)
		}

		let token = try await ensureValidAccessToken(clientId: clientId)
		api.accessToken = token

		return try await executeAuthedBodyWithUnauthorizedRetry(clientId: clientId, body: body)
	}

	private func executeAuthedBodyWithUnauthorizedRetry<T>(
		clientId: String,
		body: @Sendable () async throws -> T
	) async throws -> T {
		do {
			return try await mapErrors {
				try await body()
			}
		} catch let error as RemoteAccessServiceError {
			guard shouldRefreshAndReplay(after: error) else { throw error }

			let newToken = try await forceRefresh(clientId: clientId)
			api.accessToken = newToken
			return try await mapErrors {
				try await body()
			}
		}
	}

	private func shouldRefreshAndReplay(after error: RemoteAccessServiceError) -> Bool {
		guard case let .apiError(apiError) = error else { return false }
		switch apiError {
		case .unauthorized, .forbidden:
			return true
		default:
			return false
		}
	}

	private func ensureValidAccessToken(clientId: String) async throws -> String {
		if isUpdatingTokens {
			return try await waitForInFlightTokenUpdate()
		}

		guard let tokens = tokenStore.loadTokens(),
			  !tokens.refreshToken.isEmpty
		else {
			_ = tokenStore.clear()
			throw RemoteAccessServiceError.missingTokens
		}

		if let exp = tokens.accessTokenExpiry, Date() <= exp {
			return tokens.accessToken
		}

		return try await refreshAccessToken(clientId: clientId)
	}

	private func forceRefresh(clientId: String) async throws -> String {
		if isUpdatingTokens {
			return try await waitForInFlightTokenUpdate()
		}

		guard let tokens = tokenStore.loadTokens(),
			  !tokens.refreshToken.isEmpty
		else {
			_ = tokenStore.clear()
			throw RemoteAccessServiceError.missingTokens
		}

		return try await refreshAccessToken(clientId: clientId)
	}

	private func refreshAccessToken(clientId: String) async throws -> String {
		try await performTokenUpdate {
			try await self.refreshTokenResponseWithStaleRetry(clientId: clientId)
		}
	}

	/// If the refresh token was rotated by a concurrent caller, retry once with the latest from storage.
	private func refreshTokenResponseWithStaleRetry(clientId: String) async throws -> RATokenResponse {
		let firstRefreshToken = try currentRefreshToken()
		do {
			return try await api.refreshAccessToken(
				clientId: clientId,
				refreshToken: firstRefreshToken
			)
		} catch {
			let mapped = RemoteAccessAPIError(catching: error)
			guard shouldRetryRefreshWithLatestToken(mapped),
				  let latest = tokenStore.loadTokens()?.refreshToken,
				  !latest.isEmpty,
				  latest != firstRefreshToken
			else {
				throw mapped
			}

			return try await api.refreshAccessToken(
				clientId: clientId,
				refreshToken: latest
			)
		}
	}

	private func currentRefreshToken() throws -> String {
		guard let token = tokenStore.loadTokens()?.refreshToken, !token.isEmpty else {
			_ = tokenStore.clear()
			throw RemoteAccessServiceError.missingTokens
		}
		return token
	}

	private func shouldRetryRefreshWithLatestToken(_ error: RemoteAccessAPIError) -> Bool {
		switch error {
		case .unauthorized, .forbidden:
			return true
		case .httpStatus(let code, _):
			return code == 400
		default:
			return false
		}
	}

	private func waitForInFlightTokenUpdate() async throws -> String {
		try await withCheckedThrowingContinuation { continuation in
			tokenUpdateWaiters.append(continuation)
		}
	}

	private func performTokenUpdate(
		_ op: @Sendable () async throws -> RATokenResponse
	) async throws -> String {
		if isUpdatingTokens {
			return try await waitForInFlightTokenUpdate()
		}

		isUpdatingTokens = true
		do {
			let accessToken = try await mapErrors {
				try await self.runTokenUpdate(op)
			}
			resumeTokenUpdateWaiters(with: .success(accessToken))
			return accessToken
		} catch {
			resumeTokenUpdateWaiters(with: .failure(error))
			throw error
		}
	}

	private func resumeTokenUpdateWaiters(with result: Result<String, Error>) {
		isUpdatingTokens = false
		let waiters = tokenUpdateWaiters
		tokenUpdateWaiters = []
		for waiter in waiters {
			switch result {
			case let .success(token):
				waiter.resume(returning: token)
			case let .failure(error):
				waiter.resume(throwing: error)
			}
		}
	}

	private func failTokenUpdateWaiters(_ error: Error) {
		resumeTokenUpdateWaiters(with: .failure(error))
	}

	private func runTokenUpdate(
		_ op: @Sendable () async throws -> RATokenResponse
	) async throws -> String {
		do {
			let resp = try await op()

			let tokens = RemoteAccessToken(raTokenResponse: resp)
			_ = tokenStore.save(tokens)

			guard let updated = tokenStore.loadTokens() else {
				_ = tokenStore.clear()
				throw RemoteAccessServiceError.missingTokens
			}

			api.accessToken = updated.accessToken
			return updated.accessToken
		} catch let error as RemoteAccessAPIError {
			throw RemoteAccessServiceError.apiError(error)
		} catch {
			throw RemoteAccessServiceError.unexpected(.init(error))
		}
	}
}
