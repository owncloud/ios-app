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

	private var inFlightTokenUpdate: Task<String, Error>?

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
					return false

				case let .apiError(apiError):
					switch apiError {
						case .forbidden, .unauthorized:
							return false

						case let .httpStatus(statusCode, _):
							if (400...499).contains(statusCode) {
								_ = tokenStore.clear()
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
		if let t = inFlightTokenUpdate {
			t.cancel()
			inFlightTokenUpdate = nil
		}

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
		if let t = inFlightTokenUpdate {
			let token = try await t.value
			api.accessToken = token
			return try await mapErrors {
				try await body()
			}
		}

		let token = try await ensureValidAccessToken(clientId: clientId)
		api.accessToken = token

		do {
			return try await mapErrors {
				try await body()
			}
		} catch let error as RemoteAccessAPIError {
			// Spec: both 401 (unauthorized) and 403 (forbidden) trigger a single
			// token-refresh-and-replay attempt before the session is treated as invalid.
			switch error {
			case .unauthorized, .forbidden:
				let newToken = try await forceRefresh(clientId: clientId)
				api.accessToken = newToken
			default:
				break
			}
			return try await mapErrors {
				try await body()
			}
		}
	}

	private func ensureValidAccessToken(clientId: String) async throws -> String {
		if let t = inFlightTokenUpdate {
			return try await t.value
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

		return try await performTokenUpdate {
			try await self.api.refreshAccessToken(clientId: clientId, refreshToken: tokens.refreshToken)
		}
	}

	private func forceRefresh(clientId: String) async throws -> String {
		if let t = inFlightTokenUpdate { return try await t.value }

		guard let tokens = tokenStore.loadTokens(),
			  !tokens.refreshToken.isEmpty
		else {
			_ = tokenStore.clear()
			throw RemoteAccessServiceError.missingTokens
		}

		return try await performTokenUpdate {
			do {
				return try await self.api.refreshAccessToken(clientId: clientId, refreshToken: tokens.refreshToken)
			} catch let error as RemoteAccessServiceError {
				throw error
			} catch let error as RemoteAccessAPIError {
				throw RemoteAccessServiceError.apiError(error)
			} catch {
				throw RemoteAccessServiceError.unexpected(.init(error))
			}
		}
	}

	private func performTokenUpdate(
		_ op: @escaping @Sendable () async throws -> RATokenResponse
	) async throws -> String {
		if let t = inFlightTokenUpdate {
			return try await t.value
		}

		let task = Task<String, Error> { [weak self] in
			guard let self else { throw CancellationError() }
			return try await mapErrors {
				try await self.runTokenUpdate(op)
			}
		}

		inFlightTokenUpdate = task
		defer { inFlightTokenUpdate = nil }

		return try await task.value
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
