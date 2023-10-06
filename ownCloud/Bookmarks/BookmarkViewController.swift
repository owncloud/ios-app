//
//  BookmarkViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 04.05.18.
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

import UIKit
import ownCloudSDK
import ownCloudUI
import ownCloudApp
import ownCloudAppShared
// UNCOMMENT FOR HOST SIMULATOR: // import ownCloudMocking

typealias BookmarkViewControllerUserActionCompletionHandler = (_ bookmark : OCBookmark?, _ savedValidBookmark: Bool) -> Void

class BookmarkViewController: StaticTableViewController {
	// MARK: - UI elements
	var nameSection : StaticTableViewSection?
	var nameRow : StaticTableViewRow?
	var nameChanged = false

	var helpSection : StaticTableViewSection?
	var helpButtonRow : StaticTableViewRow?

	var urlSection : StaticTableViewSection?
	var urlRow : StaticTableViewRow?
	var urlChanged = false
	var certificateRow : StaticTableViewRow?

	var credentialsSection : StaticTableViewSection?
	var usernameRow : StaticTableViewRow?
	var passwordRow : StaticTableViewRow?
	var tokenInfoRow : StaticTableViewRow?
	var deleteAuthDataButtonRow : StaticTableViewRow?
	var activeTextField: UITextField?

	var showOAuthInfoHeader = false
	var showedOAuthInfoHeader : Bool = false
	var tokenHelpSection : StaticTableViewSection?
	var tokenHelpRow: StaticTableViewRow?

	var userActionCompletionHandler : BookmarkViewControllerUserActionCompletionHandler?

	lazy var continueBarButtonItem: UIBarButtonItem = UIBarButtonItem(title: "Continue".localized, style: .done, target: self, action: #selector(handleContinue))
	lazy var saveBarButtonItem: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(BookmarkViewController.userActionSave))
	lazy var nextBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow-down"), style: .plain, target: self, action: #selector(toogleTextField))
	lazy var previousBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow-up"), style: .plain, target: self, action: #selector(toogleTextField))
	lazy var inputToolbar: UIToolbar = {
		var toolbar = UIToolbar()
		toolbar.barStyle = .default
		toolbar.isTranslucent = true
		toolbar.sizeToFit()
		let doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(resignTextField))
		let flexibleSpaceBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
		let fixedSpaceBarButtonItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
		toolbar.setItems([fixedSpaceBarButtonItem, previousBarButtonItem, fixedSpaceBarButtonItem, fixedSpaceBarButtonItem, nextBarButtonItem, flexibleSpaceBarButtonItem, doneBarButtonItem], animated: false)
		toolbar.isUserInteractionEnabled = true
		return toolbar
	}()

	// MARK: - Internal storage
	var bookmark : OCBookmark?
	var originalBookmark : OCBookmark?

	var generationOptions: [OCAuthenticationMethodKey : Any]?

	enum BookmarkViewControllerMode {
		case create
		case edit
	}

	private var mode : BookmarkViewControllerMode

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

	// MARK: - Init & Deinit
	init(_ editBookmark: OCBookmark?, removeAuthDataFromCopy: Bool = false) {
		// Determine mode
		if editBookmark != nil {
			mode = .edit

			bookmark = editBookmark?.copy() as? OCBookmark // Make a copy of the bookmark
		} else {
			mode = .create

			bookmark = OCBookmark()
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

		// Super init
		super.init(style: .grouped)

		self.cssSelector = .bookmarkEditor

		// Accessibility Identifiers
		continueBarButtonItem.accessibilityIdentifier = "continue-bar-button"
		saveBarButtonItem.accessibilityIdentifier = "save-bar-button"

		// Name section + row
		nameRow = StaticTableViewRow(textFieldWithAction: { [weak self] (_, sender, action) in
			if let textField = sender as? UITextField, action == .changed {
				self?.nameChanged = true
				self?.bookmark?.name = (textField.text?.count == 0) ? nil : textField.text
			}
		}, placeholder: "Name".localized, value: editBookmark?.name ?? "", identifier: "row-name-name", accessibilityLabel: "Server name".localized)

		nameSection = StaticTableViewSection(headerTitle: "Name".localized, footerTitle: nil, identifier: "section-name", rows: [ nameRow! ])

		// URL section + row
		urlRow = StaticTableViewRow(textFieldWithAction: { [weak self]  (_, sender, action) in
			if let textField = sender as? UITextField, action == .changed {
				var placeholderString = "Name".localized
				var changedBookmark = false
				self?.urlChanged = true

				// Disable Continue button if there is no url
				if textField.text != "" {
					self?.continueBarButtonItem.isEnabled = true
				} else {
					self?.continueBarButtonItem.isEnabled = false
				}

				if let urlString = textField.text, let normalizedURL = NSURL(username: nil, password: nil, afterNormalizingURLString: urlString, protocolWasPrepended: nil) {
					if let host = normalizedURL.host {
						placeholderString = host
					}

					// Erase origin URL if URL is changed
					if self?.bookmark?.originURL != nil {
						self?.bookmark?.originURL = nil
					}
				}

				// Erase authentication data and hide fields (if any) if URL is edited
				if self?.bookmark?.authenticationMethodIdentifier != nil {
					self?.bookmark?.authenticationMethodIdentifier = nil
					self?.bookmark?.authenticationData = nil

					changedBookmark = true
				}

				if let certificateCount = self?.bookmark?.certificateStore?.allRecords.count, certificateCount > 0 {
					self?.bookmark?.certificateStore?.removeAllCertificates()

					changedBookmark = true
				}

				if changedBookmark {
					self?.showOAuthInfoHeader = false
					self?.composeSectionsAndRows(animated: true)
				}

				if let nameRowTextField = self?.nameRow?.textField {
					let placeholderColor = nameRowTextField.getThemeCSSColor(.stroke, selectors: [.placeholder]) ?? .secondaryLabel
					nameRowTextField.attributedPlaceholder = NSAttributedString(string: placeholderString, attributes: [.foregroundColor : placeholderColor])
				}
			}
		}, placeholder: "https://", keyboardType: .URL, autocorrectionType: .no, identifier: "row-url-url", accessibilityLabel: "Server URL".localized)

		certificateRow = StaticTableViewRow(rowWithAction: { [weak self] (_, _) in
			if let certificate = self?.bookmark?.primaryCertificate {
				let certificateViewController : ThemeCertificateViewController = ThemeCertificateViewController(certificate: certificate, compare: nil)
				let navigationController = ThemeNavigationController(rootViewController: certificateViewController)

				self?.present(navigationController, animated: true, completion: nil)
			}
		}, title: "Certificate Details".localized, accessoryType: .disclosureIndicator, accessoryView: BorderedLabel(), identifier: "row-url-certificate")

		urlSection = StaticTableViewSection(headerTitle: "Server URL".localized, footerTitle: nil, identifier: "section-url", rows: [ urlRow! ])

		// Credentials section + rows
		usernameRow = StaticTableViewRow(textFieldWithAction: { [weak self] (_, sender, action) in
			if (sender as? UITextField) != nil, self?.bookmark?.authenticationData != nil, action == .changed {
				self?.bookmark?.authenticationData = nil
				self?.composeSectionsAndRows(animated: true)
			}
		}, placeholder: "Username".localized, autocorrectionType: .no, identifier: "row-credentials-username", accessibilityLabel: "Server Username".localized)
		usernameRow?.textField?.textContentType = .username

		passwordRow = StaticTableViewRow(secureTextFieldWithAction: { [weak self] (_, sender, action) in
			if (sender as? UITextField) != nil, self?.bookmark?.authenticationData != nil, action == .changed {
				self?.bookmark?.authenticationData = nil
				self?.composeSectionsAndRows(animated: true)
			}
		}, placeholder: "Password".localized, autocorrectionType: .no, identifier: "row-credentials-password", accessibilityLabel: "Server Password".localized)
		passwordRow?.textField?.textContentType = .password

		addPasswordManagerButton()

		tokenInfoRow = StaticTableViewRow(label: "", identifier: "row-credentials-token-info")

		// Token help
		tokenHelpRow = StaticTableViewRow(label: "", identifier: "row-token-help")
		tokenHelpSection =  StaticTableViewSection(headerTitle: "", footerTitle: nil, identifier: "section-token-help", rows: [ tokenHelpRow! ])

		deleteAuthDataButtonRow = StaticTableViewRow(buttonWithAction: { [weak self] (_, _) in
			if self?.bookmark?.authenticationData != nil {

				if let authMethodIdentifier = self?.bookmark?.authenticationMethodIdentifier {
					if OCAuthenticationMethod.isAuthenticationMethodTokenBased(authMethodIdentifier as OCAuthenticationMethodIdentifier) {
						self?.showOAuthInfoHeader = true
						self?.showedOAuthInfoHeader = true
					}
				}

				self?.bookmark?.authenticationMethodIdentifier = nil
				self?.bookmark?.authenticationData = nil
				self?.updateUI(from: (self?.bookmark)!, fieldSelector: { (row) -> Bool in
					return ((row == self?.usernameRow!) && self?.mode != .edit) || (row == self?.passwordRow!)
				})
				self?.composeSectionsAndRows(animated: true)
				self?.updateInputFocus()
			}
		}, title: "Delete Authentication Data".localized, style: .destructive, identifier: "row-credentials-auth-data-delete")

		credentialsSection = StaticTableViewSection(headerTitle: "Credentials".localized, footerTitle: nil, identifier: "section-credentials", rows: [ usernameRow!, passwordRow! ])

		// Input focus tracking
		urlRow?.textField?.delegate = self
		passwordRow?.textField?.delegate = self
		usernameRow?.textField?.delegate = self

		// Mode setup
		self.navigationController?.navigationBar.isHidden = false
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(BookmarkViewController.userActionCancel))
		self.navigationItem.leftBarButtonItem?.accessibilityIdentifier = "cancel"

		switch mode {
			case .create:
				self.navigationItem.title = Branding.shared.organizationName ?? "Add account".localized
				self.navigationItem.rightBarButtonItem = continueBarButtonItem

				// Support for bookmark default name
				if let defaultNameString = AccountSettingsProvider.shared.defaultBookmarkName {
					self.bookmark?.name = defaultNameString

					if bookmark != nil {
						updateUI(from: bookmark!) { (_) -> Bool in return(true) }
					}
				}

				// Support for bookmark default URL
				if let defaultURL = AccountSettingsProvider.shared.defaultURL {
					self.bookmark?.url = defaultURL

					if bookmark != nil {
						updateUI(from: bookmark!) { (_) -> Bool in return(true) }
					}
				}

				if let url = AccountSettingsProvider.shared.profileHelpURL, let title = AccountSettingsProvider.shared.profileHelpButtonLabel {
					let imageView = UIImageView(image: UIImage(systemName: "questionmark.circle")!)
					helpButtonRow = StaticTableViewRow(rowWithAction: { staticRow, sender in
						UIApplication.shared.open(url)
					}, title: title, alignment: .center, accessoryView: imageView)

					helpSection = StaticTableViewSection(headerTitle: "Help".localized, footerTitle: AccountSettingsProvider.shared.profileOpenHelpMessage, identifier: "section-help", rows: [ helpButtonRow! ])
				}

			case .edit:
				// Fill UI
				if bookmark != nil {
					updateUI(from: bookmark!) { (_) -> Bool in return(true) }

					if bookmark?.isTokenBased == false, removeAuthDataFromCopy {
						bookmark?.authenticationData = nil
						self.passwordRow?.value = ""
					}
				}

				self.usernameRow?.enabled =
				(bookmark?.authenticationMethodIdentifier == nil) ||	// Enable if no authentication method was set (to keep it available)
				((bookmark?.authenticationMethodIdentifier != nil) && (bookmark?.isPassphraseBased == true) && (((self.usernameRow?.value as? String) ?? "").count == 0)) // Enable if authentication method was set, is not tokenbased, but username is not available (i.e. when keychain was deleted/not migrated)

				self.navigationItem.title = "Edit account".localized
				self.navigationItem.rightBarButtonItem = saveBarButtonItem
		}

		// Support for bookmark URL editable
		if AccountSettingsProvider.shared.URLEditable == false {
			self.urlRow?.enabled = false

			let vectorImageView = VectorImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))

			Theme.shared.add(tvgResourceFor: "icon-locked")
			vectorImageView.vectorImage = Theme.shared.tvgImage(for: "icon-locked")

			self.urlRow?.cell?.accessoryView = vectorImageView
		}

		// Update contents
		self.composeSectionsAndRows(animated: false)

		if let bookmark = bookmark, bookmark.scanForAuthenticationMethodsRequired == true, bookmark.authenticationMethodIdentifier == nil {
			OnMainThread {
				self.handleContinue()
			}
		}

		let logoAndAppNameView = ComposedMessageView.infoBox(additionalElements: [
			.image(AccountSettingsProvider.shared.logo, size: CGSize(width: 64, height: 64), cssSelectors: [.icon]),
			.title(VendorServices.shared.appName, alignment: .centered, cssSelectors: [.title])
		])

		logoAndAppNameView.cssSelectors = [.welcome, .message]
		logoAndAppNameView.backgroundInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 0, trailing: 20)
		logoAndAppNameView.elementInsets = NSDirectionalEdgeInsets(top: 30, leading: 20, bottom: 10, trailing: 20)

		(logoAndAppNameView.backgroundView as? RoundCornerBackgroundView)?.fillImage = Branding.shared.brandedImageNamed(.loginBackground)

		self.tableView.tableHeaderView = logoAndAppNameView
		self.tableView.layoutTableHeaderView()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - View controller events
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.updateInputFocus()
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		if size.width != self.view.frame.size.width {
			DispatchQueue.main.async {
				self.tableView.layoutTableHeaderView()
			}
		}
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
			handleContinueURLProbe(hud: hud, hudCompletion: hudCompletion)
			return
		}

		if bookmark?.authenticationData == nil {
			var proceed = true
			if let authMethodIdentifier = bookmark?.authenticationMethodIdentifier {
				if OCAuthenticationMethod.isAuthenticationMethodTokenBased(authMethodIdentifier as OCAuthenticationMethodIdentifier) {
					// Only proceed, if OAuth Info Header was shown to the user, before continue was pressed
					// Statement here is only important for http connections and token based auth
					if showedOAuthInfoHeader == false {
						proceed = false
						showedOAuthInfoHeader = true
					}
				}
			}
			if proceed == true {
				handleContinueAuthentication(hud: hud, hudCompletion: hudCompletion)
			}

			return
		}
	}

	func handleContinueURLProbe(hud: ProgressHUDViewController?, hudCompletion: @escaping (((() -> Void)?) -> Void)) {
		if let urlString = urlRow?.value as? String {
			var username : NSString?, password: NSString?
			var protocolWasPrepended : ObjCBool = false

			// Normalize URL
			if let serverURL = NSURL(username: &username, password: &password, afterNormalizingURLString: urlString, protocolWasPrepended: &protocolWasPrepended) as URL? {
				// Check for zero-length host name
				if (serverURL.host == nil) || ((serverURL.host != nil) && (serverURL.host?.count==0)) {
					// Missing hostname
					let alertController = ThemedAlertController(title: "Missing hostname".localized, message: "The entered URL does not include a hostname.", preferredStyle: .alert)

					alertController.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: nil))

					self.present(alertController, animated: true, completion: nil)

					self.urlRow?.cell?.shakeHorizontally()

					return
				}

				// Save username and password for possible later use if they were part of the URL
				if username != nil {
					usernameRow?.value = username
				}

				if password != nil {
					passwordRow?.value = password
				}

				// Probe URL
				bookmark?.url = serverURL

				if let connectionBookmark = bookmark {
					let connection = instantiateConnection(for: connectionBookmark)
					let previousCertificate = bookmark?.primaryCertificate

					hud?.present(on: self, label: "Contacting server…".localized)

					connection.prepareForSetup(options: nil) { (issue, _, _, preferredAuthenticationMethods, generationOptions) in
						hudCompletion({
							// Update URL
							self.urlRow?.textField?.text = serverURL.absoluteString

							let continueToNextStep : () -> Void = { [weak self] in
								self?.bookmark?.authenticationMethodIdentifier = preferredAuthenticationMethods?.first
								self?.composeSectionsAndRows(animated: true) {
									self?.updateInputFocus()
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

									if displayIssues.isAtLeast(level: .warning) {
										// Present issues if the level is >= warning
										IssuesCardViewController.present(on: self, issue: issue, displayIssues: displayIssues, completion: { [weak self, weak issue] (response) in
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
	}

	func handleContinueAuthentication(hud: ProgressHUDViewController?, hudCompletion: @escaping (((() -> Void)?) -> Void)) {
		if let connectionBookmark = bookmark {
			var options : [OCAuthenticationMethodKey : Any] = generationOptions ?? [:]

			let connection = instantiateConnection(for: connectionBookmark)

			if let authMethodIdentifier = bookmark?.authenticationMethodIdentifier {
				if OCAuthenticationMethod.isAuthenticationMethodPassphraseBased(authMethodIdentifier as OCAuthenticationMethodIdentifier) {
					options[.usernameKey] = usernameRow?.value ?? ""
					options[.passphraseKey] = passwordRow?.value ?? ""
				}
			}

			options[.presentingViewControllerKey] = self
			options[.requiredUsernameKey] = connectionBookmark.userName

			guard let bookmarkAuthenticationMethodIdentifier = bookmark?.authenticationMethodIdentifier else { return }

			hud?.present(on: self, label: "Authenticating…".localized)

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
							self.navigationController?.view.shakeHorizontally()
							self.updateInputFocus(fallbackRow: self.passwordRow)
						} else if nsError?.isOCError(withCode: .authorizationCancelled) == true {
							// User cancelled authorization, no reaction needed
						} else if let issue = issue {
							IssuesCardViewController.present(on: self, issue: issue, completion: { [weak self, weak issue] (response) in
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
				self.presentingViewController?.dismiss(animated: true, completion: nil)
			})
		}
	}

	// MARK: - User actions
	@objc func userActionCancel() {
		let userActionCompletionHandler = self.userActionCompletionHandler
		self.userActionCompletionHandler = nil

		self.presentingViewController?.dismiss(animated: true, completion: {
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

		hud?.present(on: self, label: "Updating connection…".localized)

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
										strongSelf.presentingViewController?.dismiss(animated: true, completion: nil)
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
													self?.topMostViewController.present(progressViewController, animated: true, completion: nil)
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
								if let issue = issue {
									self?.bookmark?.authenticationData = nil

									IssuesCardViewController.present(on: strongSelf, issue: issue, completion: { [weak self, weak issue] (response) in
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
									strongSelf.presentingViewController?.dismiss(animated: true, completion: nil)
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

	// MARK: - Update section and row composition
	func composeSectionsAndRows(animated: Bool = true, completion: (() -> Void)? = nil) {
		if animated {
			self.tableView.performBatchUpdates({
				_composeSectionsAndRows(animated: animated)
			}, completion: { (_) in
				completion?()
			})
		} else {
			_composeSectionsAndRows(animated: animated)
			completion?()
		}
	}

	func _composeSectionsAndRows(animated: Bool = true) {
		// Name section: display if a bookmark's URL or name has been set
		if (bookmark?.url != nil) || (bookmark?.name != nil) {
			if nameSection?.attached == false {
				self.insertSection(nameSection!, at: 0, animated: animated)
			}
		} else {
			if nameSection?.attached == true {
				self.removeSection(nameSection!, animated: animated)
			}
		}

		// URL section: certificate details - show if there's one
		if bookmark?.primaryCertificate != nil {
			if certificateRow != nil, certificateRow?.attached == false {
				urlSection?.add(row: certificateRow!, animated: animated)
				showedOAuthInfoHeader = true
				bookmark?.primaryCertificate?.validationResult(completionHandler: { (_, shortDescription, longDescription, color, _) in
					OnMainThread {
						guard let accessoryView = self.certificateRow?.additionalAccessoryView as? BorderedLabel else { return }
						accessoryView.update(text: shortDescription, color: color)
					}
					self.urlSection?.footerTitle = longDescription
				})
			}
		} else {
			if certificateRow != nil, certificateRow?.attached == true {
				urlSection?.updateFooter(title: nil)
				urlSection?.remove(rows: [certificateRow!], animated: animated)
			}
		}

		// URL section: show always
		if urlSection?.attached == false {
			self.insertSection(urlSection!, at: self.sections.contains(nameSection!) ? 1 : 0, animated: animated)
		}

		// Credentials section: show depending on authentication method and data
		var showCredentialsSection = false
		if let authenticationMethodIdentifier = bookmark?.authenticationMethodIdentifier {
			// Username & Password: show if passphrase-based authentication method is used
			if let authenticationMethodClass = OCAuthenticationMethod.registeredAuthenticationMethod(forIdentifier: authenticationMethodIdentifier) {
				// Remove unwanted rows
				var removeRows : [StaticTableViewRow] = []
				let authMethodType = authenticationMethodClass.type as OCAuthenticationMethodType

				switch authMethodType {
					case .passphrase:
						showCredentialsSection = true // Show for passphrase-based authentication methods

						if tokenInfoRow?.attached == true {
							removeRows.append(tokenInfoRow!)
						}

						if !authenticationMethodClass.usesUserName {
							removeRows.append(usernameRow!)
						}

					case .token:
						if usernameRow?.attached == true {
							removeRows.append(usernameRow!)
						}

						if passwordRow?.attached == true {
							removeRows.append(passwordRow!)
						}

						if bookmark?.authenticationData != nil {
							showCredentialsSection = true
						}
				}

				if self.bookmark?.authenticationData == nil {
					if deleteAuthDataButtonRow?.attached == true {
						removeRows.append(deleteAuthDataButtonRow!)
					}
				}

				credentialsSection?.remove(rows: removeRows, animated: animated)

				// Add wanted rows
				switch authMethodType {
					case .passphrase:
						if passwordRow?.attached == false {
							credentialsSection?.insert(row: passwordRow!, at: 0, animated: animated)
						}

						if authenticationMethodClass.usesUserName {
							if usernameRow?.attached == false {
								credentialsSection?.insert(row: usernameRow!, at: 0, animated: animated)
							}
						}

					case .token:
						if let authData = self.bookmark?.authenticationData, let userName = authenticationMethodClass.userName(fromAuthenticationData: authData) {
							tokenInfoRow?.value = NSString(format:"Authenticated as %@ via %@".localized as NSString, userName, authenticationMethodClass.name)
						} else {
							tokenInfoRow?.value = "Authenticated via".localized + " " + authenticationMethodClass.name
						}

						if self.bookmark?.authenticationData != nil {
							if tokenInfoRow?.attached == false {
								credentialsSection?.insert(row: tokenInfoRow!, at: 0, animated: animated)
							}

							showCredentialsSection = true
						} else {
							showOAuthInfoHeader = true
						}
				}

				if self.bookmark?.authenticationData != nil {
					if deleteAuthDataButtonRow?.attached == false {
						credentialsSection?.add(row: deleteAuthDataButtonRow!, animated: animated)
					}
				}
			}
		}

		if showCredentialsSection {
			if credentialsSection?.attached == false {
				if let urlSectionIndex = urlSection?.index {
					self.insertSection(credentialsSection!, at: urlSectionIndex+1, animated: animated)
				}
			}
		} else {
			if credentialsSection?.attached == true {
				self.removeSection(credentialsSection!, animated: animated)
			}
		}

		if showOAuthInfoHeader {
			var authMethodName = "OAuth2"

			if let authenticationMethodIdentifier = bookmark?.authenticationMethodIdentifier, let localizedAuthMethodName = OCAuthenticationMethod.localizedName(forAuthenticationMethodIdentifier: authenticationMethodIdentifier) {
				authMethodName = localizedAuthMethodName
			}

			let messageText = "If you 'Continue', you will be prompted to allow the '{{app.name}}' app to open the {{authmethodName}} login page where you can enter your credentials.".localized(["authmethodName" :  authMethodName])

			tokenHelpRow?.value = messageText

			OnMainThread {
				if self.tokenHelpSection?.attached == false {
					self.insertSection(self.tokenHelpSection!, at: 0, animated: animated)
				}
			}
		} else {
			if tokenHelpSection?.attached == true {
				removeSection(tokenHelpSection!, animated: animated)
			}
		}

		// Continue button: show always
		if isBookmarkComplete(bookmark: self.bookmark) {
			if self.mode == .create {
				self.navigationItem.rightBarButtonItem = continueBarButtonItem
			} else {
				self.navigationItem.rightBarButtonItem = saveBarButtonItem
			}
		} else {
			self.navigationItem.rightBarButtonItem = continueBarButtonItem
			if urlRow?.textField?.text != ""{
				continueBarButtonItem.isEnabled = true
			} else {
				continueBarButtonItem.isEnabled = false
			}
		}

		if helpSection?.attached == false {
			self.insertSection(helpSection!, at: self.sections.count, animated: animated)
		}
	}

	@discardableResult func updateInputFocus(fallbackRow: StaticTableViewRow? = nil ) -> Bool {
		var firstResponder : UIView?
		var firstResponderRow : StaticTableViewRow?

		if urlRow?.attached == true, (urlRow?.value as? String)?.count == 0 {
			firstResponderRow = urlRow
		} else {
			if credentialsSection?.attached == true {
				if usernameRow?.attached == true, (usernameRow?.value as? String)?.count == 0 {
					firstResponderRow = usernameRow
				} else if passwordRow?.attached == true, (passwordRow?.value as? String)?.count == 0 {
					firstResponderRow = passwordRow
				}
			}
		}

		if firstResponderRow == nil {
			firstResponderRow = fallbackRow
		}

		if firstResponder == nil, firstResponderRow != nil {
			firstResponder = firstResponderRow?.textField
		}

		if firstResponder != nil, firstResponderRow != nil {
			firstResponder?.becomeFirstResponder()
			if let indexPath = firstResponderRow?.indexPath {
				// FWIW calling this directly here after the table was updated or focus changed (making the keyboard appear, making the visible area change, ..) will result in a no-op
				// Works reliable if moved to the next runloop iteration, so that's what we do here
				OnMainThread {
					self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
				}
			}

			return true
		} else {
			self.view.window?.endEditing(true)

			return false
		}
	}

	func updateUI(from bookmark: OCBookmark, fieldSelector: ((_ row: StaticTableViewRow) -> Bool)) {
		// Name
		if nameRow != nil, fieldSelector(nameRow!) {
			// - Value
			if bookmark.name != nil {
				nameRow!.value = bookmark.name
			} else {
				nameRow!.value = ""
			}

			// - Placeholder
			var placeholderString = "Name".localized

			if (bookmark.url != nil) || (bookmark.originURL != nil) {
				placeholderString = bookmark.shortName
			}

			if let nameRowTextField = nameRow?.textField {
				let placeholderColor = nameRowTextField.getThemeCSSColor(.stroke, selectors: [.placeholder]) ?? .secondaryLabel
				nameRowTextField.attributedPlaceholder = NSAttributedString(string: placeholderString, attributes: [.foregroundColor : placeholderColor])
			}
		}

		// URL
		if urlRow != nil, fieldSelector(urlRow!) {
			if bookmark.url != nil {
				urlRow?.value = bookmark.url?.absoluteString
			} else {
				urlRow?.value = ""
			}
		}

		// Username and password
		var userName : String?
		var password : String?

		if let authMethodIdentifier = bookmark.authenticationMethodIdentifier,
		   OCAuthenticationMethod.isAuthenticationMethodPassphraseBased(authMethodIdentifier as OCAuthenticationMethodIdentifier),
		   let authData = bookmark.authenticationData,
		   let authenticationMethodClass = OCAuthenticationMethod.registeredAuthenticationMethod(forIdentifier: authMethodIdentifier) {
			userName = authenticationMethodClass.userName(fromAuthenticationData: authData)
			password = authenticationMethodClass.passPhrase(fromAuthenticationData: authData)
		}

		if usernameRow != nil, fieldSelector(usernameRow!) {
			usernameRow?.value = userName ?? ""
		}

		if passwordRow != nil, fieldSelector(passwordRow!) {
			passwordRow?.value = password ?? ""
		}
	}

	// MARK: - Tools
	func isBookmarkComplete(bookmark: OCBookmark?) -> Bool {
		return (bookmark?.url != nil) && (bookmark?.authenticationMethodIdentifier != nil) && (bookmark?.authenticationData != nil)
	}

	// MARK: - Keyboard AccessoryView
	@objc func toogleTextField (_ sender: UIBarButtonItem) {
		if passwordRow?.textField?.isFirstResponder ?? false {
			// Found next responder, so set it
			usernameRow?.textField?.becomeFirstResponder()
		} else {
			// Not found, so remove keyboard
			passwordRow?.textField?.becomeFirstResponder()
		}
	}

	@objc func resignTextField (_ sender: UIBarButtonItem) {
		activeTextField?.resignFirstResponder()
	}
}

// MARK: - Convenience for presentation
extension BookmarkViewController {
	static func showBookmarkUI(on hostViewController: UIViewController, edit bookmark: OCBookmark? = nil, performContinue: Bool = false, attemptLoginOnSuccess: Bool = false, autosolveErrorOnSuccess: NSError? = nil, removeAuthDataFromCopy: Bool = true) {
		var editBookmark = bookmark

		if let bookmark {
			// Retrieve latest version of bookmark from OCBookmarkManager
			if let latestStoredBookmarkVersion = OCBookmarkManager.shared.bookmark(forUUIDString: bookmark.uuid.uuidString) {
				editBookmark = latestStoredBookmarkVersion
			}
		}

		let bookmarkViewController : BookmarkViewController = BookmarkViewController(editBookmark, removeAuthDataFromCopy: removeAuthDataFromCopy)
		bookmarkViewController.userActionCompletionHandler = { (bookmark, success) in
			if success, let bookmark = bookmark {
				if let error = autosolveErrorOnSuccess as Error? {
					OCMessageQueue.global.resolveIssues(forError: error, forBookmarkUUID: bookmark.uuid)
				}

				if attemptLoginOnSuccess {
					AccountConnectionPool.shared.connection(for: bookmark)?.connect()
				}
			}
		}

		let navigationController : ThemeNavigationController = ThemeNavigationController(rootViewController: bookmarkViewController)
		navigationController.isModalInPresentation = true

		hostViewController.present(navigationController, animated: true, completion: {
			OnMainThread {
				if performContinue {
					bookmarkViewController.showedOAuthInfoHeader = true // needed for HTTP+OAuth2 connections to really continue on .handleContinue() call
					bookmarkViewController.handleContinue()
				}
			}
		})
	}
}

// MARK: - OCClassSettings support

extension OCClassSettingsIdentifier {
	static let bookmark = OCClassSettingsIdentifier("bookmark")
}

extension OCClassSettingsKey {
	static let prepopulation = OCClassSettingsKey("prepopulation")
}

enum BookmarkPrepopulationMethod : String {
	case doNot
	case streaming
	case split
}

extension BookmarkViewController : OCClassSettingsSupport {
	static func defaultSettings(forIdentifier identifier: OCClassSettingsIdentifier) -> [OCClassSettingsKey : Any]? {
		return nil
	}

	static let classSettingsIdentifier : OCClassSettingsIdentifier = .bookmark

	static func classSettingsMetadata() -> [OCClassSettingsKey : [OCClassSettingsMetadataKey : Any]]? {
		return [
			.prepopulation : [
				.type 		: OCClassSettingsMetadataType.string,
				.description 	: "Controls prepopulation of the local database with the full item set during account setup.",
				.category	: "Bookmarks",
				.status		: OCClassSettingsKeyStatus.supported,
				.possibleValues	: [
					[
						OCClassSettingsMetadataKey.description : "No prepopulation. Request the contents of every folder individually.",
						OCClassSettingsMetadataKey.value : BookmarkPrepopulationMethod.doNot.rawValue
					],
					[
						OCClassSettingsMetadataKey.description : "Parse the prepopulation metadata while receiving it.",
						OCClassSettingsMetadataKey.value : BookmarkPrepopulationMethod.streaming.rawValue
					],
					[
						OCClassSettingsMetadataKey.description : "Parse the prepopulation metadata after receiving it as a whole.",
						OCClassSettingsMetadataKey.value : BookmarkPrepopulationMethod.split.rawValue
					]
				]
			]
		]
	}
}

// MARK: - Keyboard / return key tracking
extension BookmarkViewController : UITextFieldDelegate {

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if self.navigationItem.rightBarButtonItem == continueBarButtonItem {
			if !updateInputFocus() {
				handleContinue()
			}

			return false
		}

		return true
	}

	func textFieldDidBeginEditing(_ textField: UITextField) {
		activeTextField = textField
		if textField.isEqual(urlRow?.textField) {
			textField.returnKeyType = .continue
		} else if textField.isEqual(usernameRow?.textField) && passwordRow?.textField?.isEnabled ?? false {
			previousBarButtonItem.isEnabled = false
			nextBarButtonItem.isEnabled = true
			textField.inputAccessoryView = inputToolbar
			textField.returnKeyType = .next
		} else if textField.isEqual(passwordRow?.textField) && usernameRow?.textField?.isEnabled ?? false {
			previousBarButtonItem.isEnabled = true
			nextBarButtonItem.isEnabled = false
			textField.inputAccessoryView = inputToolbar
			textField.returnKeyType = .continue
		}
	}
}

// MARK: - Password manager support
extension BookmarkViewController {
	func addPasswordManagerButton() {
		if PasswordManagerAccess.installed {
			let vectorImageView = VectorImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))

			Theme.shared.add(tvgResourceFor: "icon-password-manager")
			vectorImageView.vectorImage = Theme.shared.tvgImage(for: "icon-password-manager")

			vectorImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(BookmarkViewController.openPasswordManagerSheet(sender:))))

			self.passwordRow?.cell?.accessoryView = vectorImageView
		}
	}

	@objc func openPasswordManagerSheet(sender: Any?) {
		if let bookmarkURL = self.bookmark?.url {
			PasswordManagerAccess.findCredentials(url: bookmarkURL, viewController: self, sourceView: (sender as? UITapGestureRecognizer)?.view) { (error, inUsername, inPassword) in
				if error == nil {
					OnMainThread {
						if let username = inUsername {
							self.usernameRow?.value = username
						}

						if let password = inPassword {
							self.passwordRow?.value = password
						}

						self.updateInputFocus()
					}
				} else {
					Log.debug("Error retrieving \(Log.mask(bookmarkURL)) credentials from password manager: \(Log.mask(error))")
				}
			}
		}
	}
}

public extension OCAuthenticationMethod {

	static func authenticationMethodTypeForIdentifier(_ authenticationMethodIdentifier: OCAuthenticationMethodIdentifier) -> OCAuthenticationMethodType? {
		if let authenticationMethodClass = OCAuthenticationMethod.registeredAuthenticationMethod(forIdentifier: authenticationMethodIdentifier) {
			return authenticationMethodClass.type
		}

		return nil
	}

	static func isAuthenticationMethodPassphraseBased(_ authenticationMethodIdentifier: OCAuthenticationMethodIdentifier) -> Bool {
		return authenticationMethodTypeForIdentifier(authenticationMethodIdentifier) == OCAuthenticationMethodType.passphrase
	}

	static func isAuthenticationMethodTokenBased(_ authenticationMethodIdentifier: OCAuthenticationMethodIdentifier) -> Bool {
		return authenticationMethodTypeForIdentifier(authenticationMethodIdentifier) == OCAuthenticationMethodType.token
	}

}

extension ThemeCSSSelector {
	static let bookmarkEditor = ThemeCSSSelector(rawValue: "bookmarkEditor")
}
