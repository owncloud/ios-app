import UIKit
import Combine
import ownCloudSDK
import ownCloudAppShared

protocol LoginViewModelEventHandler: AnyObject {
	func handle(_ event: LoginViewModel.Event)
}

final public class LoginViewModel {
	enum Step {
		case emailEntry
		case deviceSelection
	}

    enum Event {
        case loginTap
        case resetPasswordTap
        case settingsTap
        case backToEmail
		case unableToConnect
		case unableToDetect
		case wrongState
		case setupRequired
		case deviceStarting
		case developerOptionsTap
    }

	enum LoginError {
		case authenticationFailed
		case serverNotFound
	}

	private let eventHandler: LoginViewModelEventHandler

	// Inputs
	@Published var email: String = ""
	@Published var password: String = ""

	// Outputs
	@Published private(set) var isLoginEnabled: Bool = true
	@Published private(set) var isLoading: Bool = false
	@Published private(set) var errors: [LoginError] = []
	@Published private(set) var emailEntryError: String?
    @Published private(set) var deviceItems: [String] = []
    @Published var selectedDeviceIndex: Int?
    @Published private(set) var isDetectingDevices: Bool = false
	@Published private(set) var step: Step = .emailEntry

	private var mergedDevices: [MergedDevice] = []
	private var cancellables = Set<AnyCancellable>()
	private var isCantFindFlowInProgress = false
	private var didPerformInitialLoad = false

	var bookmark: OCBookmark

	private var raService: RemoteAccessService {
		HCContext.shared.remoteAccessService
	}

	private var deviceReachabilityService: DeviceReachabilityService {
		HCContext.shared.deviceReachabilityService
	}

	private var preferences: HCPreferences {
		HCContext.shared.preferences
	}

	private var _cookieStorage : OCHTTPCookieStorage?
	var cookieStorage : OCHTTPCookieStorage? {
		if _cookieStorage == nil, let cookieSupportEnabled = OCCore.classSetting(forOCClassSettingsKey: .coreCookieSupportEnabled) as? Bool, cookieSupportEnabled == true {
			_cookieStorage = OCHTTPCookieStorage()
		}

		return _cookieStorage
	}

	// Progress to the next login step after email verification
	func advanceToDeviceSelection() {
		Log.debug("[STX]: Advance to device selection step")
		step = .deviceSelection
	}

    func backToEmailEntry() {
		Log.debug("[STX]: Going back to email entry")
        step = .emailEntry
        eventHandler.handle(.backToEmail)
    }

	func instantiateConnection(for bmark: OCBookmark) -> OCConnection {
		let connection = OCConnection(bookmark: bmark)

		connection.hostSimulator = OCHostSimulatorManager.shared.hostSimulator(forLocation: .accountSetup, for: self)
		connection.cookieStorage = self.cookieStorage // Share cookie storage across all relevant connections

		return connection
	}

	init(eventHandler: LoginViewModelEventHandler) {
		self.eventHandler = eventHandler
		self.bookmark = OCBookmark()

		if let favoriteEmail = preferences.favoriteEmail {
			email = favoriteEmail
			step = .deviceSelection
		} else {
			step = .emailEntry
		}

        Publishers
            .CombineLatest3($email, $password, $step)
			.receive(on: RunLoop.main)
			.sink(receiveValue: { [weak self] username, password, _ in
				guard let self else { return }
				switch step {
					case .emailEntry:
						self.isLoginEnabled = self.isValidEmail(username)
					case .deviceSelection:
                        self.isLoginEnabled = (self.selectedDeviceIndex != nil) && !password.isEmpty
				}
			})
			.store(in: &cancellables)

        $selectedDeviceIndex
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                if self.step == .deviceSelection {
                    self.isLoginEnabled = (self.selectedDeviceIndex != nil) && !self.password.isEmpty
                }
            }
            .store(in: &cancellables)

        $password
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                if self.step == .deviceSelection {
                    self.isLoginEnabled = (self.selectedDeviceIndex != nil) && !self.password.isEmpty
                }
            }
            .store(in: &cancellables)

        $step
            .removeDuplicates()
            .sink { [weak self] step in
                if case .deviceSelection = step { self?.loadDevices() }
            }
            .store(in: &cancellables)
	}

	private func isValidEmail(_ email: String) -> Bool {
		let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
		return email.range(of: pattern, options: .regularExpression) != nil
	}

	func login(url: URL) {
		Log.debug("[STX]: Starting login. URL: \(url)")
		// TODO: Refactor during login from invite implementation.

		bookmark.url = url
		let connection = instantiateConnection(for: bookmark)
		OCConnection.setupHTTPPolicy = .allow
		Log.debug("[STX]: Calling OCConnection.prepareForSetup")
		connection.prepareForSetup(options: nil) { [weak self] (issue, _, supportedMethods, preferredAuthenticationMethods, generationOptions) in
			Log.debug("[STX]: prepareForSetup completion.")
			if let issues = issue?.issues {
				let issuesString = issues.map {
					"\($0.localizedTitle ?? "no title") - \($0.localizedDescription ?? "no description")"
				}.joined(separator: "\n")
				Log.debug("[STX]: Issues: \(issuesString)")
			}

			if let issues = issue?.issues, issues.contains(where: { $0.type == .error }) {
				self?.errors = [.serverNotFound]
				Log.debug("[STX]: There was an error preparing login. Aborting.")
				self?.isLoading = false
				return
			}

			Log.debug("[STX]: Checking supported authentication methods.")
			guard let supportedMethods else {
				Log.debug("[STX]: No supported methods found. Aborting.")
				self?.errors = [.serverNotFound]
				self?.isLoading = false
				return
			}

			Log.debug("[STX]: Supported methods: \(supportedMethods.map(\.rawValue).joined(separator: "\n"))")
			if let preferredAuthenticationMethods {
				Log.debug("[STX]: Preferred methods: \(preferredAuthenticationMethods.map(\.rawValue).joined(separator: "\n"))")
			}
			if let generationOptions {
				Log.debug("[STX]: Generation options: \(generationOptions)")
			}

			if supportedMethods.contains(.basicAuth) {
				self?.bookmark.authenticationMethodIdentifier = .basicAuth
				Log.debug("[STX]: Authenticating with basic auth method.")
				self?.authenticate(username: self?.email, password: self?.password)
			} else {
				Log.debug("[STX]: Basic auth is not supported. Aborting.")
				self?.errors = [.serverNotFound]
				self?.isLoading = false
			}
		}
	}

	func authenticate(username: String? = nil, password: String? = nil) {
		var options: [OCAuthenticationMethodKey: Any] = [:]

		let connection = instantiateConnection(for: bookmark)

		if let authMethodIdentifier = bookmark.authenticationMethodIdentifier {
			if OCAuthenticationMethod.isAuthenticationMethodPassphraseBased(authMethodIdentifier as OCAuthenticationMethodIdentifier) {
				Log.debug("[STX]: Authentication method passphrase based, providing username and password.")
				options[.usernameKey] = username ?? ""
				options[.passphraseKey] = password ?? ""
			} else {
				Log.debug("[STX]: Authentication method is not passphrase based.")
			}
		} else {
			Log.debug("[STX]: Bookmark doesnt have authentication method identifier.")
		}

		options[.requiredUsernameKey] = bookmark.userName

		// Pre-fill already provided username in case of a server locator being used
		if options[.requiredUsernameKey] == nil, let serverLocationUserName = bookmark.serverLocationUserName {
			options[.usernameKey] = serverLocationUserName
		}

		guard let bookmarkAuthenticationMethodIdentifier = bookmark.authenticationMethodIdentifier else {
			self.errors = [.serverNotFound]
			self.isLoading = false
			Log.debug("[STX]: Bookmark doesnt have authentication method identifier.")
			return
		}

		Log.debug("[STX]: Starting generation of authentication data.")
		connection.generateAuthenticationData(withMethod: bookmarkAuthenticationMethodIdentifier, options: options) { (error, authMethodIdentifier, authMethodData) in
			if error == nil, let authMethodIdentifier, let authMethodData {
				Log.debug("[STX]: Authentication generation succeeded.")
				self.bookmark.authenticationMethodIdentifier = authMethodIdentifier
				self.bookmark.authenticationData = authMethodData
				self.bookmark.scanForAuthenticationMethodsRequired = false

				Log.debug("[STX]: Retreiving available instances.")
				connection.retrieveAvailableInstances(options: options, authenticationMethodIdentifier: authMethodIdentifier, authenticationData: authMethodData, completionHandler: { error, instances in
					if error == nil, let instances, instances.count > 0 {
						Log.debug("[STX]: Instances: \(instances)")
					}

					if self.bookmark.isComplete {
						if let username, !username.isEmpty {
							self.preferences.favoriteEmail = username
						}
						if let selectedDeviceIndex = self.selectedDeviceIndex, selectedDeviceIndex < self.mergedDevices.count {
							let device = self.mergedDevices[selectedDeviceIndex]
							self.preferences.favoriteDeviceCN = device.certificateCommonName
						}
						Log.debug("[STX]: Bookmark is complete. Adding bookmark")
						self.bookmark.authenticationDataStorage = .keychain // Commit auth changes to keychain
						OCBookmarkManager.shared.addBookmark(self.bookmark)
					} else {
						Log.debug("[STX]: Bookmark is not complete")
					}
				})
			} else {
				Log.debug("[STX]: Authentication generation failed with error: \(error?.localizedDescription ?? "")")
				self.errors = [.authenticationFailed]
				self.isLoading = false
			}
		}
	}

	func resetErrors() {
		errors = []
		emailEntryError = nil
	}

	func handleUnknownEmailNotAllowed() {
		Log.debug("[STX]: Email not allowed during verification flow.")
		backToEmailEntry()
		emailEntryError = HCL10n.Auth.Login.notAllowedEmailError
	}

    func didTapLogin() {
		Log.debug("[STX]: Did tap login")
        resetErrors()
        switch step {
            case .emailEntry:

				if let favoriteEmail = preferences.favoriteEmail {
					if email != favoriteEmail {
						// Favorite email is stored and user enters a different email.
						// Update favorite email and remove old auth data
						Task {
							await raService.clearTokens()
						}
					}
				}
				preferences.favoriteEmail = email
				advanceToDeviceSelection()
            case .deviceSelection:
				isLoading = true
				Task {
					await self.prepareAddressAndLoginForSelectedDevice()
				}
        }
    }

    // MARK: - Devices Merge (RA + mDNS)

	func loadDevices() {
        Log.debug("[STX]: Starting devices load")
        isDetectingDevices = true
        deviceItems = []
        // keep current selection until we have a non-empty devices list or confirmed empty

		Task { [weak self, email] in
			guard let self else { return }
			let hasRAToken = await self.raService.hasValidTokens()
			let merged = (try? await self.deviceReachabilityService.getMergedDevices(
				email: email,
				includeRemote: hasRAToken,
				probeRemotePaths: false
			)) ?? []

			await MainActor.run {
				self.isDetectingDevices = false
				self.mergedDevices = merged
				self.deviceItems = merged.map { $0.remoteDevice?.friendlyName ?? $0.localDevice?.name ?? "" }
				if self.deviceItems.isEmpty {
						// Give mDNS a short grace period on the very first load before triggering the cant-find flow.
						if self.didPerformInitialLoad == false {
							self.didPerformInitialLoad = true
							let initialGrace = 3.0
							Task { [weak self] in
								guard let self else { return }
								try? await Task.sleep(nanoseconds: UInt64(initialGrace * 1_000_000_000))

								if await self.deviceReachabilityService.localDevices().isEmpty {
									await MainActor.run {
										self.selectedDeviceIndex = nil
										self.triggerCantFindDeviceFlow(autoTriggered: true)
									}
								} else {
									self.loadDevices()
								}
							}
						} else {
							self.selectedDeviceIndex = nil
							self.triggerCantFindDeviceFlow(autoTriggered: true)
						}
				} else {
					if
						let staticAddress = self.preferences.staticDeviceAddress,
						let staticIndex = self.mergedDevices.firstIndex(where: { $0.localDevice?.name == staticAddress })
					{
						self.selectedDeviceIndex = staticIndex
					} else if let cn = self.preferences.favoriteDeviceCN {
						self.selectedDeviceIndex = self.mergedDevices.firstIndex(where: {
							$0.certificateCommonName == cn
						}) ?? 0
					} else {
						self.selectedDeviceIndex = 0
					}
				}
			}
		}
    }

    func refreshDevices() {
		Log.debug("[STX]: Refreshing devices.")
		resetErrors()
        loadDevices()
    }

	func didTapCantFindDevice() {
		triggerCantFindDeviceFlow(autoTriggered: false)
	}

	private func triggerCantFindDeviceFlow(autoTriggered: Bool) {
		_ = autoTriggered
		guard isCantFindFlowInProgress == false else { return }
		guard isValidEmail(email) else { return }
		isCantFindFlowInProgress = true
		Task { [weak self] in
			guard let self else { return }
			defer { self.isCantFindFlowInProgress = false }

			let hasValidToken = await self.raService.hasValidTokens()
			if hasValidToken {
				await MainActor.run {
					self.eventHandler.handle(.unableToDetect)
				}
				return
			}

			await MainActor.run {
				CodeVerificationService.shared.requestEmailVerification(
					email: self.email,
					onUnknownEmailCancel: { [weak self] in
						self?.handleUnknownEmailNotAllowed()
					},
					completion: { [weak self] isAuthenticated in
						guard isAuthenticated else { return }
						self?.refreshDevices()
					}
				)
			}
		}
	}

	private func prepareAddressAndLoginForSelectedDevice() async {
		Log.debug("[STX]: Composing device URL")
        guard let idx = selectedDeviceIndex, idx < mergedDevices.count else {
			await MainActor.run { self.isLoading = false }
			return
		}
        let selectedDevice = mergedDevices[idx]

		// Algorithm C: probe only this device's local / public / relay links (early return).
		guard
			let loginPath = await deviceReachabilityService.selectLoginPath(for: selectedDevice),
			let deviceURL = loginPath.path.url
		else {
			await MainActor.run {
				self.isLoading = false
				self.eventHandler.handle(.unableToConnect)
			}
			return
		}

		let bestPath = loginPath.path
		let probe = loginPath.probe

		let owncloudServerURL = deviceURL.appendingPathComponent("files")
		Log.debug("[STX]: Login best path: \(owncloudServerURL)")

		if let about = probe.about, (about.os_state?.lowercased() ?? "normal") != "normal" {
			await MainActor.run {
				self.isLoading = false
				self.step = .deviceSelection
				self.eventHandler.handle(.wrongState)
			}
			return
		}

		if let status = probe.status {
			if status.OOBE.done == false {
				await MainActor.run {
					self.isLoading = false
					self.step = .deviceSelection
					self.eventHandler.handle(.setupRequired)
				}
				return
			}
			if status.apps?.files?.isReady == false {
				await MainActor.run {
					self.isLoading = false
					self.step = .deviceSelection
					self.eventHandler.handle(.deviceStarting)
				}
				return
			}
		}

		// Persist current device identification and email for reprobe on relaunch
		let cn = selectedDevice.remoteDevice?.certificateCommonName ?? selectedDevice.localDevice?.certificateCommonName
		if let cn {
			HCContext.shared.preferences.favoriteDeviceCN = cn
			if let remote = selectedDevice.remoteDevice {
				let savedPaths: [HCPreferences.SavedConnectedDevice.SavedPath] = remote.paths.map {
					let kind: HCPreferences.SavedConnectedDevice.SavedPath.Kind
					switch $0.kind {
						case .local: kind = .local
						case .public: kind = .public
						case .remote: kind = .remote
					}
					return .init(kind: kind, address: $0.address, port: $0.port)
				}
				let saved = HCPreferences.SavedConnectedDevice(
					seagateDeviceID: remote.seagateDeviceID,
					certificateCommonName: remote.certificateCommonName,
					friendlyName: remote.friendlyName,
					hostname: remote.hostname,
					paths: savedPaths,
					lastSuccessfulPathKey: bestPath.persistenceKey
				)
				HCContext.shared.preferences.currentConnectedDevice = saved
			}
		}
		if !email.isEmpty { HCContext.shared.preferences.favoriteEmail = email }
		login(url: owncloudServerURL)
	}

	func didTapResetPassword() {
		Log.debug("[STX]: Reset password tap.")
		eventHandler.handle(.resetPasswordTap)
	}

	func didTapSettings() {
		Log.debug("[STX]: Setings tap.")
		eventHandler.handle(.settingsTap)
	}

	func didTapDeveloperOptions() {
		Log.debug("[STX]: Developer options tap.")
		eventHandler.handle(.developerOptionsTap)
	}
}
