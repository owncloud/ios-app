//
//  StaticLoginSetupViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 26.11.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2018, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import ownCloudSDK
import UIKit
import ownCloudAppShared

class StaticLoginSetupViewController : StaticLoginStepViewController {
	var profile : StaticLoginProfile
	var bookmark : OCBookmark?
	var busySection : StaticTableViewSection?

	private var urlString : String?
	private var username : String?
	private var password : String?
	private var passwordRow : StaticTableViewRow?

	init(loginViewController theLoginViewController: StaticLoginViewController, profile theProfile: StaticLoginProfile) {
		profile = theProfile
		if let url = profile.url {
			bookmark = OCBookmark(for: url)
		}

		super.init(loginViewController: theLoginViewController)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		if profile.canConfigureURL {
			self.addSection(urlSection())
			if OCBookmarkManager.shared.bookmarks.count == 0, profile.promptForHelpURL != nil, profile.helpURLButtonString != nil, profile.helpURL != nil {
				self.addSection(urlHelpSection())
			}
		} else {
			proceedWithLogin()
		}
	}

	override func updateViewConstraints() {
		super.updateViewConstraints()
		if tableView.contentSize.height > view.frame.size.height {
			tableView.isScrollEnabled = true
		} else {
			tableView.isScrollEnabled = false
		}
	}

	func urlSection() -> StaticTableViewSection {
		var urlSection : StaticTableViewSection

		urlSection = StaticTableViewSection(headerTitle: nil, identifier: "urlSection")
		urlSection.addStaticHeader(title: profile.welcome!, message: profile.promptForURL)

		urlSection.add(row: StaticTableViewRow(textFieldWithAction: { [weak self] (row, _, type) in
			if type == .didBegin, let cell = row.cell, let indexPath = self?.tableView.indexPath(for: cell) {
				self?.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
			}
			if let self = self, let value = row.value as? String {
				self.urlString = value
			}
			}, placeholder: "https://", value: self.urlString ?? "", keyboardType: .asciiCapable, autocorrectionType: .no, autocapitalizationType: .none, returnKeyType: .continue, identifier: "url"))

		if VendorServices.shared.canAddAccount, OCBookmarkManager.shared.bookmarks.count > 0 {
			let (proceedButton, cancelButton) = urlSection.addButtonFooter(proceedLabel: "Continue".localized, proceedItemStyle: .welcome, cancelLabel: "Cancel".localized)
			proceedButton?.addTarget(self, action: #selector(self.proceedWithURL), for: .touchUpInside)
			cancelButton?.addTarget(self, action: #selector(self.cancel(_:)), for: .touchUpInside)
		} else {
		let (proceedButton, _) = urlSection.addButtonFooter(proceedLabel: "Continue".localized, proceedItemStyle: .welcome, cancelLabel: nil)
			proceedButton?.addTarget(self, action: #selector(self.proceedWithURL), for: .touchUpInside)
		}

		return urlSection
	}

	func urlHelpSection() -> StaticTableViewSection {
		var urlHelpSection : StaticTableViewSection

		urlHelpSection = StaticTableViewSection(headerTitle: nil, identifier: "urlHelpSection")
		if let message = profile.promptForHelpURL, let title = profile.helpURLButtonString {
			let (proceedButton, _) = urlHelpSection.addButtonFooter(message: message, messageItemStyle: .welcomeMessage, proceedLabel: title, proceedItemStyle: .informal, cancelLabel: nil)
				proceedButton?.addTarget(self, action: #selector(self.helpAction), for: .touchUpInside)
		}

		return urlHelpSection
	}

	func loginMaskSection() -> StaticTableViewSection {
		var loginMaskSection : StaticTableViewSection

		loginMaskSection = StaticTableViewSection(headerTitle: nil, identifier: "loginMaskSection")
		loginMaskSection.addStaticHeader(title: profile.welcome!, message: profile.promptForPasswordAuth)

		loginMaskSection.add(row: StaticTableViewRow(textFieldWithAction: { [weak self] (row, _, type) in
			if type == .didBegin, let cell = row.cell, let indexPath = self?.tableView.indexPath(for: cell) {
				self?.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
			}
			if let value = row.value as? String {
				self?.username = value
			}
			}, placeholder: "Username".localized, keyboardType: .asciiCapable, autocorrectionType: .no, autocapitalizationType: .none, returnKeyType: .continue, identifier: "username"))

		passwordRow = StaticTableViewRow(secureTextFieldWithAction: { [weak self] (row, _, type) in
			if type == .didBegin, let cell = row.cell, let indexPath = self?.tableView.indexPath(for: cell) {
				self?.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
			}
			if let value = row.value as? String {
				self?.password = value
			}
			}, placeholder: "Password".localized, keyboardType: .asciiCapable, autocorrectionType: .no, autocapitalizationType: .none, returnKeyType: .continue, identifier: "password")
		if let passwordRow = passwordRow {
			loginMaskSection.add(row: passwordRow)
		}

		if VendorServices.shared.canAddAccount, OCBookmarkManager.shared.bookmarks.count > 0 {
			let (proceedButton, cancelButton) = loginMaskSection.addButtonFooter(proceedLabel: "Login".localized, proceedItemStyle: .welcome, cancelLabel: "Cancel".localized)
			proceedButton?.addTarget(self, action: #selector(self.startAuthentication), for: .touchUpInside)
			cancelButton?.addTarget(self, action: #selector(self.cancel(_:)), for: .touchUpInside)
		} else {
			let (proceedButton, _) = loginMaskSection.addButtonFooter(proceedLabel: "Login".localized, proceedItemStyle: .welcome, cancelLabel: nil)
			proceedButton?.addTarget(self, action: #selector(self.startAuthentication), for: .touchUpInside)
		}

		return loginMaskSection
	}

	func tokenMaskSection() -> StaticTableViewSection {
		var tokenMaskSection : StaticTableViewSection

		tokenMaskSection = StaticTableViewSection(headerTitle: nil, identifier: "tokenMaskSection")
		tokenMaskSection.addStaticHeader(title: profile.welcome!, message: profile.promptForTokenAuth)

		if VendorServices.shared.canAddAccount, OCBookmarkManager.shared.bookmarks.count > 0 {
			let (proceedButton, cancelButton) = tokenMaskSection.addButtonFooter(proceedLabel: "Continue", cancelLabel: "Cancel")
			proceedButton?.addTarget(self, action: #selector(self.startAuthentication), for: .touchUpInside)
			cancelButton?.addTarget(self, action: #selector(self.cancel(_:)), for: .touchUpInside)
		} else {
			let (proceedButton, _) = tokenMaskSection.addButtonFooter(proceedLabel: "Continue", proceedItemStyle: .welcome, cancelLabel: nil)
			proceedButton?.addTarget(self, action: #selector(self.startAuthentication), for: .touchUpInside)
		}

		return tokenMaskSection
	}

	func busySection(message: String) -> StaticTableViewSection {
		let busySection : StaticTableViewSection = StaticTableViewSection(headerTitle: nil, identifier: "busySection")
		let activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView(style: Theme.shared.activeCollection.activityIndicatorViewStyle)
		let containerView : FullWidthHeaderView = FullWidthHeaderView()
		let centerView : UIView = UIView()
		let messageLabel : UILabel = UILabel()

		containerView.translatesAutoresizingMaskIntoConstraints = false
		centerView.translatesAutoresizingMaskIntoConstraints = false
		messageLabel.translatesAutoresizingMaskIntoConstraints = false
		activityIndicator.translatesAutoresizingMaskIntoConstraints = false

		centerView.addSubview(activityIndicator)
		centerView.addSubview(messageLabel)

		containerView.addSubview(centerView)

		containerView.addThemeApplier({ (_, collection, _) in
			messageLabel.applyThemeCollection(collection, itemStyle: .welcomeMessage)
		})

		messageLabel.text = message

		NSLayoutConstraint.activate([
			activityIndicator.widthAnchor.constraint(equalToConstant: 30),
			activityIndicator.heightAnchor.constraint(equalToConstant: 30),
			activityIndicator.leftAnchor.constraint(equalTo: centerView.leftAnchor),
			activityIndicator.topAnchor.constraint(equalTo: centerView.topAnchor),
			activityIndicator.bottomAnchor.constraint(equalTo: centerView.bottomAnchor),

			messageLabel.centerYAnchor.constraint(equalTo: centerView.centerYAnchor),
			messageLabel.leftAnchor.constraint(equalTo: activityIndicator.rightAnchor, constant: 20),
			messageLabel.rightAnchor.constraint(equalTo: centerView.rightAnchor),

			centerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 40),
			centerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
			centerView.leftAnchor.constraint(greaterThanOrEqualTo: containerView.leftAnchor),
			centerView.rightAnchor.constraint(lessThanOrEqualTo: containerView.rightAnchor),
			centerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -40)
		])

		busySection.headerView = containerView

		activityIndicator.startAnimating()

		return busySection
	}

	private var _cookieStorage : OCHTTPCookieStorage?
	var cookieStorage : OCHTTPCookieStorage? {
		if _cookieStorage == nil, let cookieSupportEnabled = OCCore.classSetting(forOCClassSettingsKey: .coreCookieSupportEnabled) as? Bool, cookieSupportEnabled == true {
			_cookieStorage = OCHTTPCookieStorage()
			Log.debug("Created cookie storage \(String(describing: _cookieStorage)) for static login")
		}

		return _cookieStorage
	}

	func instantiateConnection(for bmark: OCBookmark) -> OCConnection {
		let connection = OCConnection(bookmark: bmark)

		connection.hostSimulator = OCHostSimulatorManager.shared.hostSimulator(forLocation: .accountSetup, for: self)
		connection.cookieStorage = self.cookieStorage // Share cookie storage across all relevant connections

		return connection
	}

	@objc func helpAction() {
		if let helpURL = self.profile.helpURL {
			let alert = ThemedAlertController(title: "Do you want to open the following URL?".localized,
							  message: helpURL.absoluteString,
							  preferredStyle: .alert)

			let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
				UIApplication.shared.open(helpURL, options: [:], completionHandler: nil)
			}
			let cancelAction = UIAlertAction(title: "Cancel".localized, style: .cancel)
			alert.addAction(okAction)
			alert.addAction(cancelAction)
			self.present(alert, animated: true)
		}
	}

	@objc func proceedWithURL() {
		var error = false
		if let value = self.urlString, value.count > 0 {
			if let normalizedURL = NSURL(username: nil, password: nil, afterNormalizingURLString: value, protocolWasPrepended: nil) {
				if let allowedHosts = self.profile.allowedHosts, allowedHosts.count > 0, let host = normalizedURL.host {
					if !allowedHosts.contains(where: { (allowedHost) -> Bool in
						return host.hasSuffix(allowedHost) ? true : false
					}) {
						error = true
					}
				}

				if !error {
					self.bookmark = OCBookmark(for: normalizedURL as URL)
					self.proceedWithLogin()
				}
			} else {
				error = true
			}
		} else {
			error = true
		}

		if error {
			let alert = ThemedAlertController(title: "Wrong URL".localized,
							  message: "Please enter a valid URL".localized,
							  preferredStyle: .alert)

			let okAction = UIAlertAction(title: "OK".localized, style: .default)
			alert.addAction(okAction)
			self.present(alert, animated: true)
		}
	}

	func proceedWithLogin() {
		guard self.bookmark != nil else {
			let alertController = ThemedAlertController(title: "Missing Profile URL".localized, message: String(format: "The Profile '%@' does not have a URL configured.\nPlease provide a URL via configuration or MDM.".localized, profile.name ?? ""), preferredStyle: .alert)

			alertController.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: nil))

			self.loginViewController?.present(alertController, animated: true, completion: nil)
			return
		}

		if let urlSection = self.sectionForIdentifier("urlSection") {
			self.removeSection(urlSection)
		}
		if let urlHelpSection = self.sectionForIdentifier("urlHelpSection") {
			self.removeSection(urlHelpSection)
		}

		busySection = self.busySection(message: "Contacting server…".localized)

		self.addSection(busySection!)
		self.determineSupportedAuthMethod()
	}

	@objc func startAuthentication(_ sender: Any?) {
		guard let bookmark = self.bookmark else { return }
		let hud : ProgressHUDViewController? = ProgressHUDViewController(on: nil)

		let connection = instantiateConnection(for: bookmark)
		var options : [OCAuthenticationMethodKey : Any] = [:]

		if let authMethodIdentifier = bookmark.authenticationMethodIdentifier {
			if OCAuthenticationMethod.registeredAuthenticationMethod(forIdentifier: authMethodIdentifier)?.type == .passphrase {
				options[.usernameKey] = username ?? ""
				options[.passphraseKey] = password ?? ""
			}

			options[.presentingViewControllerKey] = self

			let spinner = UIActivityIndicatorView(style: .white)
			if let button = sender as? ThemeButton {
				button.setTitle("Authenticating…".localized, for: .normal)
				button.isEnabled = false
				let buttonHeight = button.bounds.size.height
				let buttonWidth = button.bounds.size.width
				let spinnerWidth = spinner.bounds.size.width
				spinner.center = CGPoint(x: buttonWidth - spinnerWidth - 10.0, y: buttonHeight/2)
				button.addSubview(spinner)
				spinner.startAnimating()
			} else {
				hud?.present(on: self, label: "Authenticating…".localized)
			}

			connection.generateAuthenticationData(withMethod: authMethodIdentifier, options: options, completionHandler: { (error, authMethodIdentifier, authMethodData) in
				OnMainThread {
					if let button = sender as? ThemeButton {
						spinner.removeFromSuperview()
						button.setTitle("Login".localized, for: .normal)
						button.isEnabled = true
					}
					hud?.dismiss(completion: {
						if error == nil {
							bookmark.authenticationMethodIdentifier = authMethodIdentifier
							bookmark.authenticationData = authMethodData
							bookmark.name = self.profile.bookmarkName
							bookmark.userInfo[StaticLoginProfile.staticLoginProfileIdentifierKey] = self.profile.identifier

							OCBookmarkManager.shared.addBookmark(bookmark)

							self.loginViewController?.showFirstScreen()
							//self.pushSuccessViewController()
						} else {
							var issue : OCIssue?
							let nsError = error as NSError?

							if let embeddedIssue = nsError?.embeddedIssue() {
								issue = embeddedIssue
							} else if let error = error {
								issue = OCIssue(forError: error, level: .error, issueHandler: nil)
							}

							if nsError?.isOCError(withCode: .authorizationFailed) == true {
								// Shake
								self.navigationController?.view.shakeHorizontally()
								OnMainThread {
									self.passwordRow?.textField?.becomeFirstResponder()
								}
							} else {
								if let loginViewController = self.loginViewController, let issue = issue {

									if let busySection = self.busySection, busySection.attached {
										self.removeSection(busySection)
									}

									IssuesCardViewController.present(on: loginViewController, issue: issue, completion: { [weak self, weak issue] (response) in
										switch response {
										case .cancel:
											issue?.reject()

										case .approve:
											issue?.approve()
											self?.startAuthentication(nil)

										case .dismiss: break
										}
									})
								}
							}
						}
					})
				}
			})
		}
	}

	@objc func cancel(_ sender: Any?) {
		self.navigationController?.popViewController(animated: true)
	}

	func pushSuccessViewController() {
		let successViewController : StaticLoginStepViewController = StaticLoginStepViewController(loginViewController: self.loginViewController!)
		let messageSection = StaticTableViewSection(headerTitle: "")

		messageSection.addStaticHeader(title: "Setup complete".localized)

		let (proceedButton, showAccountsList) = messageSection.addButtonFooter(proceedLabel: "Connect".localized, proceedItemStyle: .welcome, cancelLabel: "Show accounts".localized)

		proceedButton?.addTarget(self, action: #selector(self.connectToBookmark), for: .touchUpInside)
		showAccountsList?.addTarget(loginViewController, action: #selector(loginViewController?.showFirstScreen), for: .touchUpInside)

		successViewController.addSection(messageSection)

		self.navigationController?.pushViewController(successViewController, animated: true)
	}

	@objc func connectToBookmark() {
		guard let bookmark = self.bookmark else { return }
		self.loginViewController?.openBookmark(bookmark, closeHandler: {
			self.loginViewController?.showFirstScreen()
		})
	}

	func determineSupportedAuthMethod(_ isInitialRequest: Bool = true) {
		guard let bookmark = self.bookmark else { return }

		let connection = instantiateConnection(for: bookmark)
		connection.prepareForSetup(options: nil, completionHandler: { (connectionIssue, _, _, preferredAuthenticationMethods) in
			var proceed : Bool = true

			if let issue = connectionIssue {
				proceed = self.show(issue: issue, proceed: { () in
					OnMainThread {
						if isInitialRequest {
							self.determineSupportedAuthMethod(false)
						}
					}
				}, cancel: { () in
					OnMainThread {
						if self.profile.canConfigureURL {
							if let busySection = self.busySection, busySection.attached {
								self.removeSection(busySection)
							}
							self.addSection(self.urlSection())
							if OCBookmarkManager.shared.bookmarks.count == 0, self.profile.promptForHelpURL != nil, self.profile.helpURLButtonString != nil, self.profile.helpURL != nil {
								self.addSection(self.urlHelpSection())
							}
						} else {
							self.cancel(nil)
						}
					}
				})
			}

			if proceed {
				// Determine authentication method
				// - use the most preferred one by default
				var useAuthMethod = preferredAuthenticationMethods?.first

				// - if a limit is imposed on the allowed authentication methods, use the most preferred authentication method that's also available
				if let allowedAuthenticationMethods = self.profile.allowedAuthenticationMethods, let preferredAuthenticationMethods = preferredAuthenticationMethods {
					useAuthMethod = nil

					for preferredAuthenticationMethod in preferredAuthenticationMethods {
						if allowedAuthenticationMethods.contains(preferredAuthenticationMethod) {
							useAuthMethod = preferredAuthenticationMethod
							break
						}
					}
				}

				var authMethodKnown = false

				if proceed, preferredAuthenticationMethods != nil, let authenticationMethod = useAuthMethod, let authenticationMethodClass = OCAuthenticationMethod.registeredAuthenticationMethod(forIdentifier: authenticationMethod) {

					bookmark.authenticationMethodIdentifier = useAuthMethod
					authMethodKnown = true

					OnMainThread {
						self.removeSection(self.busySection!, animated: true)

						let authMethodType = authenticationMethodClass.type as OCAuthenticationMethodType
						switch authMethodType {
						case .passphrase:
							if self.sectionForIdentifier("loginMaskSection") == nil {
								self.addSection(self.loginMaskSection())
							}
						case .token:
							if self.sectionForIdentifier("tokenMaskSection") == nil {
								self.addSection(self.tokenMaskSection())
							}
						}
					}
				}

				if !authMethodKnown {
					bookmark.authenticationMethodIdentifier = nil

					OnMainThread {
						let alert = ThemedAlertController(title: "Server error".localized,
														  message: ((preferredAuthenticationMethods != nil) && (preferredAuthenticationMethods!.count > 0)) ?
															"The server doesn't support any allowed authentication method.".localized :
															"The server doesn't support any known and allowed authentication method found.".localized,
														  preferredStyle: .alert)

						alert.addAction(UIAlertAction(title: "Retry detection".localized, style: .default, handler: { (_) in
							self.determineSupportedAuthMethod()
						}))

						self.present(alert, animated: true, completion: nil)
					}
				}
			}
		})
	}

	func show(issue: OCIssue?, proceed: (() -> Void)? = nil, cancel: (() -> Void)? = nil) -> Bool {
		if let displayIssues = issue?.prepareForDisplay() {
			if displayIssues.isAtLeast(level: .warning) {
				// Present issues if the level is >= warning
				OnMainThread {
					if let loginViewController = self.loginViewController, let issue = issue {
						if let busySection = self.busySection, busySection.attached {
							self.removeSection(busySection)
						}

						IssuesCardViewController.present(on: loginViewController, issue: issue, displayIssues: displayIssues, completion: { [weak issue] (response) in
							switch response {
								case .cancel:
									issue?.reject()
									cancel?()

								case .approve:
									issue?.approve()
									proceed?()

								case .dismiss:
									cancel?()
							}
						})
					}
				}

				return false
			} else {
				// Do not present issues
				issue?.approve()
				proceed?()
			}
		}

		return true
	}
}
