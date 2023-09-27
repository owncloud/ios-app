//
//  BookmarkComposer.swift
//  ownCloud
//
//  Created by Felix Schwarz on 05.09.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK
import ownCloudAppShared

class BookmarkComposer: NSObject {
	// MARK: - Steps
	enum Step: Equatable, Hashable {
		case intro
		case enterUsername
		case serverURL(urlString: String?)
		case authenticate(withCredentials: Bool, username: String?, password: String?)
		case chooseServer(fromInstances: [OCServerInstance])
		case infinitePropfind
		case completed
	}

	struct UndoAction {
		var action: (_ composer: BookmarkComposer) -> Void
		var byUser: Bool
	}

	var configuration: BookmarkComposerConfiguration
	weak var delegate: BookmarkComposerDelegate?

	init(configuration: BookmarkComposerConfiguration, removeAuthDataFromCopy: Bool = false, delegate: BookmarkComposerDelegate?) {
		self.configuration = configuration
		self.delegate = delegate

		self.bookmark = configuration.bookmark?.copy() as? OCBookmark ?? OCBookmark()

		bookmark.authenticationDataStorage = .memory  // Disconnect bookmark from keychain

		if bookmark.isTokenBased == true, removeAuthDataFromCopy {
			bookmark.authenticationData = nil
		}

		if bookmark.scanForAuthenticationMethodsRequired == true {
			bookmark.authenticationMethodIdentifier = nil
			bookmark.authenticationData = nil
		}

		if let name = configuration.name {
			bookmark.name = name
		}
	}

	// MARK: - Internal storage
	var bookmark: OCBookmark

	// MARK: - Connection instantiation
	private var _cookieStorage : OCHTTPCookieStorage?
	var cookieStorage : OCHTTPCookieStorage? {
		if _cookieStorage == nil, let cookieSupportEnabled = OCCore.classSetting(forOCClassSettingsKey: .coreCookieSupportEnabled) as? Bool, cookieSupportEnabled == true {
			_cookieStorage = OCHTTPCookieStorage()
			Log.debug("Created cookie storage \(String(describing: _cookieStorage))")
		}

		return _cookieStorage
	}

	func instantiateConnection(for bmark: OCBookmark) -> OCConnection {
		let connection = OCConnection(bookmark: bmark)

		connection.hostSimulator = OCHostSimulatorManager.shared.hostSimulator(forLocation: .accountSetup, for: self)
		connection.cookieStorage = self.cookieStorage // Share cookie storage across all relevant connections

		return connection
	}

	// MARK: - Setup steps
	private var didShowIntro: Bool = false
	private var username: String?
	private var password: String?
	private var instances: [OCServerInstance]?
	private var supportsInfinitePropfind: Bool?
	private var performedPrepopulation: Bool = false
	private var isDriveBased: Bool?
	private var generationOptions: [OCAuthenticationMethodKey : Any]?

	// MARK: .intro
	func doneIntro() {
		didShowIntro = true

		self.pushUndoAction(undoAction: UndoAction(action: { composer in
			composer.didShowIntro = false
		}, byUser: true))

		self.updateState()
	}

	// MARK: .enterUsername
	func enterUsername(_ username: String, byUser: Bool = true, completion: @escaping Completion) {
		bookmark.serverLocationUserName = username
		self.username = username

		self.pushUndoAction(undoAction: UndoAction(action: { composer in
			composer.bookmark.serverLocationUserName = nil
			composer.username = nil
		}, byUser: byUser))

		completion(nil, nil, nil)
		self.updateState()
	}

	// MARK: .enterURL
	typealias Completion = (_ error: Error?, _ issue: OCIssue?, _ issueCompletionHandler: IssuesCardViewController.CompletionHandler?) -> Void

	func enterURL(_ urlString: String, byUser: Bool = true, completion: @escaping Completion) {
		var username : NSString?, password: NSString?
		var protocolWasPrepended : ObjCBool = false

		// Normalize URL
		guard let serverURL = NSURL(username: &username, password: &password, afterNormalizingURLString: urlString, protocolWasPrepended: &protocolWasPrepended) as URL? else {
			return
		}

		// Check for zero-length host name
		if (serverURL.host == nil) || ((serverURL.host != nil) && (serverURL.host?.count==0)) {
			// Missing hostname
			completion(nil, OCIssue(localizedTitle: "Missing hostname".localized, localizedDescription: "The entered URL does not include a hostname.".localized, level: .error), nil)
			return
		}

		// Save username and password for possible later use if they were part of the URL
		if username != nil {
			self.username = username as? String
		}

		if password != nil {
			self.password = password as? String
		}

		// Probe URL
		bookmark.url = serverURL

		let connection = instantiateConnection(for: bookmark)

		hudMessage = "Contacting server…".localized

		connection.prepareForSetup(options: nil) { [weak self] (issue, _, _, preferredAuthenticationMethods, generationOptions) in
			self?.hudMessage = nil

			let continueToNextStep : () -> Void = { [weak self] in
				self?.bookmark.authenticationMethodIdentifier = preferredAuthenticationMethods?.first
				self?.pushUndoAction(undoAction: UndoAction(action: { composer in
					composer.username = nil
					composer.password = nil

					composer.bookmark.url = nil
					composer.bookmark.authenticationMethodIdentifier = nil

					composer.generationOptions = nil
				}, byUser: byUser))
				self?.updateState()
			}

			self?.generationOptions = generationOptions

			if let issue {
				// Parse issue for display
				if issue.prepareForDisplay().isAtLeast(level: .warning) {
					// Present issues if the level is >= warning
					completion(nil, issue, { [weak self, weak issue] (response) in
						switch response {
							case .cancel:
								issue?.reject()
								self?.bookmark.url = nil

							case .approve:
								issue?.approve()
								continueToNextStep()

							case .dismiss:
								self?.bookmark.url = nil
						}
					})
				} else {
					// Do not present issues
					issue.approve()
					continueToNextStep()
				}
			} else {
				continueToNextStep()
			}
		}
	}

	// MARK: .authenticate
	func authenticate(username: String? = nil, password: String? = nil, presentingViewController: UIViewController?, completion: @escaping Completion) {
		var options : [OCAuthenticationMethodKey : Any] = generationOptions ?? [:]

		let connection = instantiateConnection(for: bookmark)

		if let authMethodIdentifier = bookmark.authenticationMethodIdentifier {
			if OCAuthenticationMethod.isAuthenticationMethodPassphraseBased(authMethodIdentifier as OCAuthenticationMethodIdentifier) {
				options[.usernameKey] = username ?? ""
				options[.passphraseKey] = password ?? ""
			}
		}

		options[.presentingViewControllerKey] = presentingViewController
		options[.requiredUsernameKey] = bookmark.userName

		guard let bookmarkAuthenticationMethodIdentifier = bookmark.authenticationMethodIdentifier else { return }

		hudMessage = "Authenticating…".localized

		connection.generateAuthenticationData(withMethod: bookmarkAuthenticationMethodIdentifier, options: options) { (error, authMethodIdentifier, authMethodData) in
			if error == nil, let authMethodIdentifier, let authMethodData {
				self.bookmark.authenticationMethodIdentifier = authMethodIdentifier
				self.bookmark.authenticationData = authMethodData
				self.bookmark.scanForAuthenticationMethodsRequired = false

				self.hudMessage = "Fetching user information…".localized

				// Retrieve available instances for this account to chose from
				connection.retrieveAvailableInstances(options: options, authenticationMethodIdentifier: authMethodIdentifier, authenticationData: authMethodData, completionHandler: { error, instances in
					if error == nil, let instances, instances.count > 0 {
						self.instances = instances
					}

					if self.bookmark.isComplete {
						self.bookmark.authenticationDataStorage = .keychain // Commit auth changes to keychain
					}

					let continueCompletion : Completion = { (error, issue, issueCompletionHandler) in
						self.hudMessage = nil

						completion(error,issue,issueCompletionHandler)

						if error == nil, issue == nil {
							self.clearUndoStack()
							self.updateState()
						}
					}

					if self.instances == nil {
						// bookmark URL final -> retrieve server configuration right away
						self.retrieveServerConfiguration(completion: continueCompletion)
					} else {
						// server instance needs to be chosen
						if self.instances?.count == 1, let onlyInstance = self.instances?.first {
							// If only one instance is returned, choose it right away
							self.chooseServer(instance: onlyInstance, byUser: false, completion: continueCompletion)
						} else {
							continueCompletion(nil, nil, nil)
						}
					}

					Log.debug("\(connection) returned error=\(String(describing: error)) instances=\(String(describing: instances))") // Debug message also has the task to capture connection and avoid it being prematurely dropped
				})
			} else {
				self.hudMessage = nil

				var issue : OCIssue?
				let nsError = error as NSError?

				if let embeddedIssue = nsError?.embeddedIssue() {
					issue = embeddedIssue
				} else if let error = error {
					issue = OCIssue(forError: error, level: .error, issueHandler: nil)
				}

				if nsError?.isOCError(withCode: .authorizationFailed) == true {
					// Shake
					completion(error, nil, nil)
				} else if nsError?.isOCError(withCode: .authorizationCancelled) == true {
					// User cancelled authorization, no reaction needed
				} else if let issue {
					completion(nil, issue, { [weak self, weak issue] (response) in
						switch response {
							case .cancel:
								issue?.reject()

							case .approve:
								issue?.approve()
								self?.updateState()

							case .dismiss: break
						}
					})
				}
			}
		}
	}

	func retrieveServerConfiguration(completion: @escaping Completion) {
		let connection = instantiateConnection(for: bookmark)

		self.hudMessage = "Fetching server information…".localized

		connection.connect { [weak self] (error, issue) in
			guard let strongSelf = self else { return }

			// Handle errors
			guard error == nil, issue == nil else {
				self?.hudMessage = nil

				completion(error, issue, { [weak self, weak issue] (response) in
					switch response {
						case .cancel:
							issue?.reject()

						case .approve:
							issue?.approve()
							self?.updateState()

						case .dismiss: break
					}
				})
				return
			}

			// Inspect server configuration
			strongSelf.bookmark.userDisplayName = connection.loggedInUser?.displayName

			strongSelf.isDriveBased = connection.capabilities?.spacesEnabled?.boolValue ?? false
			strongSelf.supportsInfinitePropfind = connection.capabilities?.davPropfindSupportsDepthInfinity?.boolValue ?? false

			connection.disconnect(completionHandler: {
				self?.hudMessage = nil
				completion(nil, nil, nil)
			})
		}
	}

	// MARK: .chooseServer
	func chooseServer(instance: OCServerInstance, byUser: Bool = true, completion: @escaping Completion) {
		// Apply instance
		self.bookmark.apply(instance)

		// Drop all other choices
		self.instances = nil

		// Retrieve server configuration after instance changes have been applied
		self.retrieveServerConfiguration(completion: completion)
	}

	// MARK: .prepopulate
	func prepopulate(completion: @escaping Completion) -> Progress? {
		var prepopulationMethod : BookmarkPrepopulationMethod?

		// Determine prepopulation method
		if prepopulationMethod == nil, let prepopulationMethodClassSetting = BookmarkViewController.classSetting(forOCClassSettingsKey: .prepopulation) as? String {
			prepopulationMethod = BookmarkPrepopulationMethod(rawValue: prepopulationMethodClassSetting)
		}

		if prepopulationMethod == nil, supportsInfinitePropfind == true {
			prepopulationMethod = .streaming
		}

		if prepopulationMethod == nil {
			prepopulationMethod = .doNot
		}

		if isDriveBased == true {
			// Drive-based accounts do not support prepopulation yet
			prepopulationMethod = .doNot
		}

		performedPrepopulation = true

		// Prepopulation y/n?
		if let prepopulationMethod, prepopulationMethod != .doNot {
			// Perform prepopulation
			var prepopulateProgress : Progress?

			// Perform prepopulation method
			switch prepopulationMethod {
				case .streaming:
					prepopulateProgress = bookmark.prepopulate(streamCompletionHandler: { [weak self] _ in
						completion(nil, nil, nil)
						self?.updateState()
					})

				case .split:
					prepopulateProgress = bookmark.prepopulate(completionHandler: { [weak self] _ in
						completion(nil, nil, nil)
						self?.updateState()
					})

				default:
					completion(nil, nil, nil)
					self.updateState()
			}

			// Present progress
			return prepopulateProgress
		}

		// No prepopulation
		completion(nil, nil, nil)
		self.updateState()

		return nil
	}

	// MARK: .finished
	func setName(_ bookmarkName: String?) {
		self.bookmark.name = bookmarkName
	}

	// MARK: - Undo
	var undoStack: [UndoAction] = []

	var canUndoLastStep: Bool {
		return !undoStack.isEmpty
	}

	func clearUndoStack() {
		undoStack.removeAll()
	}

	func pushUndoAction(undoAction: UndoAction) {
		undoStack.append(undoAction)
	}

	func undoLastStep() {
		if undoStack.count > 0 {
			while undoStack.last != nil {
				let undoAction = undoStack.removeLast()
				undoAction.action(self)

				if undoAction.byUser {
					break
				}
			}

			updateState()
		}
	}

	// MARK: - State
	var currentStep: Step? {
		didSet {
			if oldValue != currentStep, let currentStep {
				delegate?.present(composer: self, step: currentStep)

				Log.debug("BookmarkComposer.currentStep=\(currentStep)")
			}
		}
	}
	var hudMessage: String? {
		didSet {
			if hudMessage != oldValue {
				delegate?.present(composer: self, hudMessage: hudMessage)
			}
		}
	}

	func updateState() {
		if configuration.hasIntro, !didShowIntro {
			currentStep = .intro
		} else if OCServerLocator.useServerLocatorIdentifier != nil, bookmark.serverLocationUserName == nil {
			currentStep = .enterUsername
		} else if bookmark.url == nil {
			if let absoluteURL = configuration.url?.absoluteString, !configuration.urlEditable {
				enterURL(absoluteURL, byUser: false, completion: { [weak self] error, issue, issueCompletionHandler in
					if let self {
						self.delegate?.present(composer: self, error: error, issue: issue, issueCompletionHandler: issueCompletionHandler)
					}
				})
			} else {
				currentStep = .serverURL(urlString: configuration.url?.absoluteString)
			}
		} else if bookmark.authenticationData == nil {
			currentStep = .authenticate(withCredentials: bookmark.isTokenBased == false, username: username, password: password)
		} else if let instances, instances.count > 0 {
			currentStep = .chooseServer(fromInstances: instances)
		} else if supportsInfinitePropfind == true, !performedPrepopulation {
			currentStep = .infinitePropfind
		} else {
			currentStep = .completed
		}
	}

	// MARK: - Add or update bookmark
	func addBookmark() -> OCBookmark {
		OCBookmarkManager.shared.addBookmark(bookmark)

		return bookmark
	}

	func updateBookmark(_ originalBookmark: OCBookmark? = nil) {
		guard let originalBookmark = originalBookmark ?? configuration.bookmark else {
			return
		}

		originalBookmark.setValuesFrom(bookmark)

		if !OCBookmarkManager.shared.updateBookmark(originalBookmark) {
			Log.error("Changes to \(originalBookmark) not saved as it's not tracked by OCBookmarkManager!")
		}
	}
}

protocol BookmarkComposerDelegate : AnyObject {
	func present(composer: BookmarkComposer, step: BookmarkComposer.Step)
	func present(composer: BookmarkComposer, error: Error?, issue: OCIssue?, issueCompletionHandler: IssuesCardViewController.CompletionHandler?)
	func present(composer: BookmarkComposer, hudMessage: String?)
}

extension OCBookmark {
	var isComplete: Bool {
		return url != nil && authenticationMethodIdentifier != nil && authenticationData != nil
	}
}
