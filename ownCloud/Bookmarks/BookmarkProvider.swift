//
//  BookmarkProvider.swift
//  ownCloud
//
//  Created by Matthias Hühne on 27.07.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK
import ownCloudUI
import ownCloudApp
import ownCloudAppShared

class BookmarkProvider {
	
	var bookmark : OCBookmark?
	var originalBookmark : OCBookmark?
	var generationOptions: [OCAuthenticationMethodKey : Any]?
	var userActionCompletionHandler : BookmarkViewControllerUserActionCompletionHandler?
	
	private var mode : BookmarkViewControllerMode
	var parentViewController: UIViewController?
	var bookmarkViewController: BookmarkViewController?
	
	var urlChanged = false
	var nameChanged = false
	
	// MARK: - Connection instantiation
	private var _cookieStorage : OCHTTPCookieStorage?
	var cookieStorage : OCHTTPCookieStorage? {
		if _cookieStorage == nil, let cookieSupportEnabled = OCCore.classSetting(forOCClassSettingsKey: .coreCookieSupportEnabled) as? Bool, cookieSupportEnabled == true {
			_cookieStorage = OCHTTPCookieStorage()
			Log.debug("Created cookie storage \(String(describing: _cookieStorage))")
		}

		return _cookieStorage
	}
	
	// MARK: - Init & Deinit
	init(_ editBookmark: OCBookmark?, url: URL? = nil, removeAuthDataFromCopy: Bool = false) {
		if editBookmark != nil {
			mode = .edit

			bookmark = editBookmark?.copy() as? OCBookmark // Make a copy of the bookmark
		} else {
			mode = .create

			bookmark = OCBookmark()
			if let url = url {
				bookmark?.url = url
			}
		}

		bookmark?.authenticationDataStorage = .memory  // Disconnect bookmark from keychain

		if bookmark?.isTokenBased == true, removeAuthDataFromCopy {
			bookmark?.authenticationData = nil
		}

		if bookmark?.scanForAuthenticationMethodsRequired == true {
			bookmark?.authenticationMethodIdentifier = nil
			bookmark?.authenticationData = nil
		}

		originalBookmark = editBookmark // Save original bookmark (if any)
	}
	

	func instantiateConnection(for bmark: OCBookmark) -> OCConnection {
		let connection = OCConnection(bookmark: bmark)

		connection.hostSimulator = OCHostSimulatorManager.shared.hostSimulator(forLocation: .accountSetup, for: self)
		connection.cookieStorage = self.cookieStorage // Share cookie storage across all relevant connections

		return connection
	}

	// MARK: - Continue
	@objc func handleContinue() {
		let hud : ProgressHUDViewController? = ProgressHUDViewController(on: nil)

		let hudCompletion: (((() -> Void)?) -> Void) = { (completion) in
			OnMainThread {
				if hud?.presenting == true {
					hud?.dismiss(completion: completion)
				} else {
					completion?()
				}
			}
		}

		// Check if only account name was changed in edit mode: save and dismiss without re-authentication

		//if bookmark?.isTokenBased == true, removeAuthDataFromCopy {
		if mode == .edit, nameChanged, !urlChanged, let bookmark = bookmark, bookmark.authenticationData != nil {
			updateBookmark(bookmark: bookmark)
			completeAndDismiss(with: hudCompletion)
			return
		}

		if (bookmark?.url == nil) || (bookmark?.authenticationMethodIdentifier == nil) {
			
			var url = bookmark?.url?.absoluteString
			if let urlRow = bookmarkViewController?.urlRow {
				url = urlRow.textField?.text
			}
			
			handleContinueURLProbe(urlString: url ?? "",hud: hud, hudCompletion: hudCompletion)
			return
		}

		if bookmark?.authenticationData == nil {
			var proceed = true
			if let authMethodIdentifier = bookmark?.authenticationMethodIdentifier {
				if OCAuthenticationMethod.isAuthenticationMethodTokenBased(authMethodIdentifier as OCAuthenticationMethodIdentifier) {
					// Only proceed, if OAuth Info Header was shown to the user, before continue was pressed
					// Statement here is only important for http connections and token based auth
					if bookmarkViewController?.showOAuthInfoHeader == false {
						proceed = false
						bookmarkViewController?.showOAuthInfoHeader = true
					}
				}
			}
			proceed = true
			if proceed == true {
				handleContinueAuthentication(username: bookmarkViewController?.usernameRow?.textField?.text, password: bookmarkViewController?.passwordRow?.textField?.text, hud: hud, hudCompletion: hudCompletion)
			}

			return
		}
	}

	func handleContinueURLProbe(urlString: String, hud: ProgressHUDViewController?, hudCompletion: @escaping (((() -> Void)?) -> Void)) {
			var username : NSString?, password: NSString?
			var protocolWasPrepended : ObjCBool = false

			// Normalize URL
			if let serverURL = NSURL(username: &username, password: &password, afterNormalizingURLString: urlString, protocolWasPrepended: &protocolWasPrepended) as URL? {
				// Check for zero-length host name
				if (serverURL.host == nil) || ((serverURL.host != nil) && (serverURL.host?.count==0)) {
					// Missing hostname
					let alertController = ThemedAlertController(title: "Missing hostname".localized, message: "The entered URL does not include a hostname.", preferredStyle: .alert)

					alertController.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: nil))

					parentViewController?.present(alertController, animated: true, completion: nil)

					self.bookmarkViewController?.urlRow?.cell?.shakeHorizontally()

					return
				}

				// Save username and password for possible later use if they were part of the URL
				if username != nil {
					bookmarkViewController?.usernameRow?.value = username
				}

				if password != nil {
					bookmarkViewController?.passwordRow?.value = password
				}

				// Probe URL
				bookmark?.url = serverURL

				if let connectionBookmark = bookmark {
					let connection = instantiateConnection(for: connectionBookmark)
					let previousCertificate = bookmark?.primaryCertificate

					hud?.present(on: parentViewController, label: "Contacting server…".localized)

					connection.prepareForSetup(options: nil) { (issue, _, _, preferredAuthenticationMethods, generationOptions) in
						hudCompletion({
							// Update URL
							self.bookmarkViewController?.urlRow?.textField?.text = serverURL.absoluteString

							let continueToNextStep : () -> Void = { [weak self] in
								self?.bookmark?.authenticationMethodIdentifier = preferredAuthenticationMethods?.first
								
								self?.handleContinue()
								
								self?.bookmarkViewController?.composeSectionsAndRows(animated: true) {
									self?.bookmarkViewController?.updateInputFocus()
								}

								if self?.bookmark?.primaryCertificate == previousCertificate,
								   let authMethodIdentifier = self?.bookmark?.authenticationMethodIdentifier,
								   OCAuthenticationMethod.isAuthenticationMethodTokenBased(authMethodIdentifier as OCAuthenticationMethodIdentifier) == true {

									self?.handleContinue()
								}
							}

							self.generationOptions = generationOptions

							if issue != nil {
								// Parse issue for display
								if let issue = issue {
									let displayIssues = issue.prepareForDisplay()

									if displayIssues.isAtLeast(level: .warning), let parentViewController = self.parentViewController {
										// Present issues if the level is >= warning
										IssuesCardViewController.present(on: parentViewController, issue: issue, displayIssues: displayIssues, completion: { [weak self, weak issue] (response) in
											switch response {
												case .cancel:
													issue?.reject()
													self?.bookmark?.url = nil

												case .approve:
													issue?.approve()
													continueToNextStep()

												case .dismiss:
													self?.bookmark?.url = nil
											}
										})
									} else {
										// Do not present issues
										issue.approve()
										continueToNextStep()
									}
								}
							} else {
								continueToNextStep()
							}
						})
					}
				}
			}
	}

	func handleContinueAuthentication(username: String?, password: String?, hud: ProgressHUDViewController?, hudCompletion: @escaping (((() -> Void)?) -> Void)) {
		if let connectionBookmark = bookmark {
			var options : [OCAuthenticationMethodKey : Any] = generationOptions ?? [:]

			let connection = instantiateConnection(for: connectionBookmark)

			if let authMethodIdentifier = bookmark?.authenticationMethodIdentifier {
				if OCAuthenticationMethod.isAuthenticationMethodPassphraseBased(authMethodIdentifier as OCAuthenticationMethodIdentifier) {
					options[.usernameKey] = username ?? ""
					options[.passphraseKey] = password ?? ""
				}
			}

			options[.presentingViewControllerKey] = self.parentViewController
			options[.requiredUsernameKey] = connectionBookmark.userName

			guard let bookmarkAuthenticationMethodIdentifier = bookmark?.authenticationMethodIdentifier else { return }

			hud?.present(on: parentViewController, label: "Authenticating…".localized)

			connection.generateAuthenticationData(withMethod: bookmarkAuthenticationMethodIdentifier, options: options) { (error, authMethodIdentifier, authMethodData) in
				if error == nil, let authMethodIdentifier, let authMethodData {
					self.bookmark?.authenticationMethodIdentifier = authMethodIdentifier
					self.bookmark?.authenticationData = authMethodData
					self.bookmark?.scanForAuthenticationMethodsRequired = false
					OnMainThread {
						hud?.updateLabel(with: "Fetching user information…".localized)
					}

					// Retrieve available instances for this account to chose from
					connection.retrieveAvailableInstances(options: options, authenticationMethodIdentifier: authMethodIdentifier, authenticationData: authMethodData, completionHandler: { error, instances in
						// No account chooser implemented at this time. If an account is returned, use the URL of the first one.
						if error == nil, let instance = instances?.first {
							self.bookmark?.apply(instance)
						}

						self.save(hudCompletion: hudCompletion)

						Log.debug("\(connection) returned error=\(String(describing: error)) instances=\(String(describing: instances))") // Debug message also has the task to capture connection and avoid it being prematurely dropped
					})
				} else {
					hudCompletion({
						var issue : OCIssue?
						let nsError = error as NSError?

						if let embeddedIssue = nsError?.embeddedIssue() {
							issue = embeddedIssue
						} else if let error = error {
							issue = OCIssue(forError: error, level: .error, issueHandler: nil)
						}

						if nsError?.isOCError(withCode: .authorizationFailed) == true {
							// Shake
							self.parentViewController?.navigationController?.view.shakeHorizontally()
							self.bookmarkViewController?.updateInputFocus(fallbackRow: self.bookmarkViewController?.passwordRow)
						} else if nsError?.isOCError(withCode: .authorizationCancelled) == true {
							// User cancelled authorization, no reaction needed
						} else if let issue = issue, let parentViewController = self.parentViewController {
							IssuesCardViewController.present(on: parentViewController, issue: issue, completion: { [weak self, weak issue] (response) in
								switch response {
									case .cancel:
										issue?.reject()

									case .approve:
										issue?.approve()
										self?.handleContinue()

									case .dismiss: break
								}
							})
						}
					})
				}
			}
		}
	}

	func completeAndDismiss(with hudCompletion: @escaping (((() -> Void)?) -> Void)) {
		guard let userActionCompletionHandler = self.userActionCompletionHandler else { return }

		self.userActionCompletionHandler = nil

		OnMainThread {
			hudCompletion({
				OnMainThread {
					userActionCompletionHandler(self.bookmark, true)
				}
				self.parentViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
			})
		}
	}

	// MARK: - User actions
	@objc func userActionCancel() {
		let userActionCompletionHandler = self.userActionCompletionHandler
		self.userActionCompletionHandler = nil

		parentViewController?.presentingViewController?.dismiss(animated: true, completion: {
			OnMainThread {
				userActionCompletionHandler?(nil, false)
			}
		})
	}

	@objc func userActionSave() {
		let hud : ProgressHUDViewController? = ProgressHUDViewController(on: nil)

		let hudCompletion: (((() -> Void)?) -> Void) = { (completion) in
			OnMainThread {
				if hud?.presenting == true {
					hud?.dismiss(completion: completion)
				} else {
					completion?()
				}
			}
		}

		hud?.present(on: parentViewController, label: "Updating connection…".localized)

		save(hudCompletion: hudCompletion)
	}

	func updateBookmark(bookmark: OCBookmark) {
		originalBookmark?.setValuesFrom(bookmark)
		if let originalBookmark = originalBookmark, !OCBookmarkManager.shared.updateBookmark(originalBookmark) {
			Log.error("Changes to \(originalBookmark) not saved as it's not tracked by OCBookmarkManager!")
		}
	}

	func save(hudCompletion: @escaping (((() -> Void)?) -> Void)) {
		guard let bookmark = self.bookmark else { return }

		if isBookmarkComplete(bookmark: bookmark) {
			bookmark.authenticationDataStorage = .keychain // Commit auth changes to keychain
			let connection = instantiateConnection(for: bookmark)

			connection.connect { [weak self] (error, issue) in
				if let strongSelf = self {
					if error == nil {
						let serverSupportsInfinitePropfind = connection.capabilities?.davPropfindSupportsDepthInfinity
						let isDriveBased = connection.capabilities?.spacesEnabled ?? false

						bookmark.userDisplayName = connection.loggedInUser?.displayName

						connection.disconnect(completionHandler: {

							let done = { (_ doAddBookmark: Bool) in
								if doAddBookmark {
									OCBookmarkManager.shared.addBookmark(bookmark)
								}

								let userActionCompletionHandler = strongSelf.userActionCompletionHandler
								strongSelf.userActionCompletionHandler = nil

								OnMainThread {
									hudCompletion({
										OnMainThread {
											userActionCompletionHandler?(bookmark, true)
										}
										strongSelf.parentViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
									})
								}
							}

							switch strongSelf.mode {
								case .create:
									// Add bookmark
									OnMainThread {
										var prepopulationMethod : BookmarkPrepopulationMethod?

										// Determine prepopulation method
										if prepopulationMethod == nil, let prepopulationMethodClassSetting = BookmarkViewController.classSetting(forOCClassSettingsKey: .prepopulation) as? String {
											prepopulationMethod = BookmarkPrepopulationMethod(rawValue: prepopulationMethodClassSetting)
										}

										if prepopulationMethod == nil, serverSupportsInfinitePropfind?.boolValue == true {
											prepopulationMethod = .streaming
										}

										if prepopulationMethod == nil {
											prepopulationMethod = .doNot
										}

										if isDriveBased.boolValue {
											// Drive-based accounts do not support prepopulation yet
											prepopulationMethod = .doNot
										}

										// Prepopulation y/n?
										if let prepopulationMethod = prepopulationMethod, prepopulationMethod != .doNot {
											// Perform prepopulation
											var progressViewController : ProgressIndicatorViewController?
											var prepopulateProgress : Progress?
											let prepopulateCompletionHandler = {
												// Wrap up
												OCBookmarkManager.shared.addBookmark(bookmark)

												OnMainThread {
													progressViewController?.dismiss(animated: true, completion: {
														done(false)
													})
												}
											}

											// Perform prepopulation method
											switch prepopulationMethod {
												case .streaming:
													prepopulateProgress = bookmark.prepopulate(streamCompletionHandler: { _ in
														prepopulateCompletionHandler()
													})

												case .split:
													prepopulateProgress = bookmark.prepopulate(completionHandler: { _ in
														prepopulateCompletionHandler()
													})

												default:
													done(true)
											}

											// Present progress
											if let prepopulateProgress = prepopulateProgress {

												progressViewController = ProgressIndicatorViewController(initialTitleLabel: "Preparing account".localized, initialProgressLabel: "Please wait…".localized, progress: nil, cancelLabel: "Skip".localized, cancelHandler: {
													prepopulateProgress.cancel()
												})
												progressViewController?.progress = prepopulateProgress // work around compiler bug (https://forums.swift.org/t/didset-is-not-triggered-while-called-after-super-init/45226/10)
												if let progressViewController = progressViewController {
													self?.parentViewController?.topMostViewController.present(progressViewController, animated: true, completion: nil)
												}
											}

										} else {
											// No prepopulation
											done(true)
										}
									}

								case .edit:
									// Update original bookmark
									self?.originalBookmark?.setValuesFrom(bookmark)
									if let originalBookmark = self?.originalBookmark, !OCBookmarkManager.shared.updateBookmark(originalBookmark) {
										Log.error("Changes to \(originalBookmark) not saved as it's not tracked by OCBookmarkManager!")
									}

									done(false)
							}
						})
					} else {
						OnMainThread {
							hudCompletion({
								if let issue = issue, let parentViewController = strongSelf.parentViewController {
									self?.bookmark?.authenticationData = nil

									IssuesCardViewController.present(on: parentViewController, issue: issue, completion: { [weak self, weak issue] (response) in
										switch response {
											case .cancel:
												issue?.reject()

											case .approve:
												issue?.approve()
												self?.handleContinue()

											case .dismiss: break
										}
									})
								} else {
									strongSelf.parentViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
								}
							})
						}
					}
				}
			}
		} else {
			hudCompletion({ [weak self] in
				if let strongSelf = self {
					strongSelf.handleContinue()
				}
			})
		}
	}
	
	func isBookmarkComplete(bookmark: OCBookmark?) -> Bool {
		return (bookmark?.url != nil) && (bookmark?.authenticationMethodIdentifier != nil) && (bookmark?.authenticationData != nil)
	}
	
}
