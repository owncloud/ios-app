import Foundation
import Combine
import ownCloudSDK

public extension Notification.Name {
	/// Posted on main when `HCContext.lastRemoteBaseURL` changes (reachability best path).
	static let hcRemoteBaseURLDidChange = Notification.Name("HCRemoteBaseURLDidChange")
}

private enum Constants {
	static let remoteAccessBaseURL = URL(
		string: "https://hc-remote-access-env-https.eba-a2nvhpbm.us-west-2.elasticbeanstalk.com:443/api"
	)!
}

public final class HCContext {
	public static let shared = HCContext()

	public let preferences: HCPreferences
	public let remoteAccessService: RemoteAccessService
	public let deviceReachabilityService: DeviceReachabilityService
	public let mdnsService: MDNSService
	public let remoteAccessTokenStore: RemoteAccessTokenStore
	public let networkAvailabilityMonitor: NetworkAvailabilityMonitor
	public var emailVerificationHandler: (@MainActor (_ email: String, _ completion: @escaping (Bool) -> Void) -> Void)?

	// Hack to provide this info for related data sources.
	// Use `RemoteAccessSharingURLResolver` directly if possible.
	public var lastRemoteBaseURL: URL?

	private var networkFailureObserver: NSObjectProtocol?
	private var cancellables = Set<AnyCancellable>()

	public init() {
		self.preferences = HCPreferences()
		self.remoteAccessTokenStore = RemoteAccessTokenStore()

		self.remoteAccessService = RemoteAccessService(
			api: RemoteAccessAPI(baseURL: Constants.remoteAccessBaseURL),
			tokenStore: remoteAccessTokenStore
		)
		self.mdnsService = MDNSService()
		self.networkAvailabilityMonitor = NetworkAvailabilityMonitor.shared

		self.deviceReachabilityService = DeviceReachabilityService(
			reachability: DefaultReachabilityObserver(),
			remoteAccessService: remoteAccessService,
			mdnsService: mdnsService,
			preferences: preferences,
			availabilityMonitor: networkAvailabilityMonitor
		)

		deviceReachabilityService.events
			.receive(on: DispatchQueue.main)
			.sink { [weak self] event in
				guard case let .remoteBaseURLChanged(url) = event else { return }
				self?.lastRemoteBaseURL = url
				NotificationCenter.default.post(name: .hcRemoteBaseURLDidChange, object: nil)
			}
			.store(in: &cancellables)
	}

	public func setup() {
		Task { OCConnection.defaultBaseURLProvider = await deviceReachabilityService.urlProvider }
		deviceReachabilityService.start()

		// status.php polling & similar: SDK does not call OCCoreDelegate handleError for these.
		if networkFailureObserver == nil {
			networkFailureObserver = NotificationCenter.default.addObserver(
				forName: NSNotification.Name.OCNetworkingFailureReachability,
				object: nil,
				queue: .main
			) { note in
				if let error = note.userInfo?["error"] as? Error {
					HCContext.shared.deviceReachabilityService.reportOperationError(error)
				}
			}
		}

		OCConnection.certificateValidationHandler = { _, request, certificate, _, proceedHandler in
			let ok = CertificateValidationService.shared.validatePinnedCertificate(
				serverCertificate: certificate,
				host: request.hostname,
				validateHost: false
			)
			if ok {
				proceedHandler(true, nil)
				return
			}

			// Not pinned: ask user whether to trust this server, and persist decision.
			DeviceCertificateTrustPrompt.askToTrust(host: request.hostname, certificate: certificate) { accepted in
				if accepted {
					proceedHandler(true, nil)
				} else {
					proceedHandler(false, NSError(ocError: .requestServerCertificateRejected))
				}
			}
		}
	}
}
