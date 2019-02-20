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

class BookmarkViewController: StaticTableViewController {
	// MARK: - UI elements
	var nameSection : StaticTableViewSection?
	var nameRow : StaticTableViewRow?

	var urlSection : StaticTableViewSection?
	var urlRow : StaticTableViewRow?
	var certificateRow : StaticTableViewRow?

	var credentialsSection : StaticTableViewSection?
	var usernameRow : StaticTableViewRow?
	var passwordRow : StaticTableViewRow?
	var tokenInfoRow : StaticTableViewRow?
	var deleteAuthDataButtonRow : StaticTableViewRow?

	var continueSection : StaticTableViewSection?
	var continueButtonRow : StaticTableViewRow?

	// MARK: - Internal storage
	var bookmark : OCBookmark?
	var originalBookmark : OCBookmark?

	enum BookmarkViewControllerMode {
		case create
		case edit
	}

	private var mode : BookmarkViewControllerMode

	// MARK: - Init & Deinit
	init(_ editBookmark: OCBookmark?) {
		// Determine mode
		if editBookmark != nil {
			mode = .edit

			bookmark = editBookmark?.copy() as? OCBookmark // Make a copy of the bookmark
		} else {
			mode = .create

			bookmark = OCBookmark()
		}

		bookmark?.authenticationDataStorage = .memory  // Disconnect bookmark from keychain

		originalBookmark = editBookmark // Save original bookmark (if any)

		// Super init
		super.init(style: .grouped)

		// Name section + row
		nameRow = StaticTableViewRow(textFieldWithAction: { [weak self] (_, sender) in
			if let textField = sender as? UITextField {
				self?.bookmark?.name = (textField.text?.count == 0) ? nil : textField.text
			}
		}, placeholder: "Name".localized, identifier: "row-name-name", accessibilityLabel: "Server name".localized)

		nameSection = StaticTableViewSection(headerTitle: "Name".localized, footerTitle: nil, identifier: "section-name", rows: [ nameRow! ])

		// URL section + row
		urlRow = StaticTableViewRow(textFieldWithAction: { [weak self]  (_, sender) in
			if let textField = sender as? UITextField {
				var placeholderString = "Name".localized
				var changedBookmark = false

				if let normalizedURL = NSURL(username: nil, password: nil, afterNormalizingURLString: textField.text, protocolWasPrepended: nil) {
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

				if self?.bookmark?.certificate != nil {
					self?.bookmark?.certificate = nil
					self?.bookmark?.certificateModificationDate = nil

					changedBookmark = true
				}

				if changedBookmark {
					self?.composeSectionsAndRows(animated: true)
				}

				self?.nameRow?.textField?.attributedPlaceholder = NSAttributedString(string: placeholderString, attributes: [.foregroundColor : Theme.shared.activeCollection.tableRowColors.secondaryLabelColor])
			}
		}, placeholder: "https://", keyboardType: .URL, autocorrectionType: .no, identifier: "row-url-url", accessibilityLabel: "Sever url".localized)

		certificateRow = StaticTableViewRow(rowWithAction: { [weak self] (_, _) in
			if let certificate = self?.bookmark?.certificate {
				if let certificateViewController : ThemeCertificateViewController = ThemeCertificateViewController(certificate: certificate) {
					let navigationController = ThemeNavigationController(rootViewController: certificateViewController)

					self?.present(navigationController, animated: true, completion: nil)
				}
			}
		}, title: "Certificate Details".localized, accessoryType: .disclosureIndicator, identifier: "row-url-certificate")

		urlSection = StaticTableViewSection(headerTitle: "Server URL".localized, footerTitle: nil, identifier: "section-url", rows: [ urlRow! ])

		// Credentials section + rows
		usernameRow = StaticTableViewRow(textFieldWithAction: { [weak self] (_, sender) in
			if (sender as? UITextField) != nil, self?.bookmark?.authenticationData != nil {
				self?.bookmark?.authenticationData = nil
				self?.composeSectionsAndRows(animated: true)
			}
		}, placeholder: "Username".localized, autocorrectionType: .no, identifier: "row-credentials-username", accessibilityLabel: "Server Username".localized)

		passwordRow = StaticTableViewRow(secureTextFieldWithAction: { [weak self] (_, sender) in
			if (sender as? UITextField) != nil, self?.bookmark?.authenticationData != nil {
				self?.bookmark?.authenticationData = nil
				self?.composeSectionsAndRows(animated: true)
			}
		}, placeholder: "Password".localized, autocorrectionType: .no, identifier: "row-credentials-password", accessibilityLabel: "Server Password".localized)

		addPasswordManagerButton()

		tokenInfoRow = StaticTableViewRow(label: "", identifier: "row-credentials-token-info")

		deleteAuthDataButtonRow = StaticTableViewRow(buttonWithAction: { [weak self] (_, _) in
			if self?.bookmark?.authenticationData != nil {
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

		// Continue section + row
		continueButtonRow = StaticTableViewRow(buttonWithAction: { [weak self] (row, sender) in
			Log.log("Event: \(row) \(String(describing: sender))")
			self?.handleContinue()
		}, title: "Continue".localized, identifier: "row-continue-continue")

		continueSection = StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: "section-continue", rows: [ continueButtonRow! ])

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
				self.navigationItem.title = "Add bookmark".localized

				// Support for bookmark default URL
				if let defaultURLString = self.classSetting(forOCClassSettingsKey: .bookmarkDefaultURL) as? String {
					self.bookmark?.url = URL(string: defaultURLString)

					if bookmark != nil {
						updateUI(from: bookmark!) { (_) -> Bool in return(true) }
					}
				}

			case .edit:
				// Fill UI
				if bookmark != nil {
					updateUI(from: bookmark!) { (_) -> Bool in return(true) }
				}

				self.usernameRow?.enabled = false

				self.navigationItem.title = "Edit bookmark".localized

				self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(BookmarkViewController.userActionSave))
		}

		// Support for bookmark URL editable
		if let bookmarkURLEditable = self.classSetting(forOCClassSettingsKey: .bookmarkURLEditable) as? Bool, bookmarkURLEditable == false {
			self.urlRow?.enabled = bookmarkURLEditable

			let vectorImageView = VectorImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))

			Theme.shared.add(tvgResourceFor: "icon-locked")
			vectorImageView.vectorImage = Theme.shared.tvgImage(for: "icon-locked")

			self.urlRow?.cell?.accessoryView = vectorImageView
		}

		// Update contents
		self.composeSectionsAndRows(animated: false)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - View controller events
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.updateInputFocus()
	}

	// MARK: - Continue
	func handleContinue() {
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

		if (bookmark?.url == nil) || (bookmark?.authenticationMethodIdentifier == nil) {
			handleContinueURLProbe(hud: hud, hudCompletion: hudCompletion)
			return
		}

		if bookmark?.authenticationData == nil {
			handleContinueAuthentication(hud: hud, hudCompletion: hudCompletion)
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
					let alertController = UIAlertController(title: "Missing hostname".localized, message: "The entered URL does not include a hostname.", preferredStyle: .alert)

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

				if let connection = OCConnection(bookmark: bookmark) {
					hud?.present(on: self, label: "Contacting server…".localized)

					let previousCertificate = bookmark?.certificate

					connection.prepareForSetup(options: nil) { (issue, _, _, preferredAuthenticationMethods) in
						hudCompletion({
							// Update URL
							self.urlRow?.textField?.text = serverURL.absoluteString

							let continueToNextStep : () -> Void = { [weak self] in
								self?.bookmark?.authenticationMethodIdentifier = preferredAuthenticationMethods?.first
								self?.composeSectionsAndRows(animated: true) {
									self?.updateInputFocus()
								}

								if self?.bookmark?.certificate == previousCertificate,
								   let authMethodIdentifier = self?.bookmark?.authenticationMethodIdentifier,
								   self?.isAuthenticationMethodTokenBased(authMethodIdentifier as OCAuthenticationMethodIdentifier) == true {

									self?.handleContinue()
								}
							}

							if issue != nil {
								// Parse issue for display
								if let displayIssues = issue?.prepareForDisplay() {
									if displayIssues.displayLevel.rawValue >= OCIssueLevel.warning.rawValue {
										// Present issues if the level is >= warning
										let issuesViewController = ConnectionIssueViewController(displayIssues: displayIssues, completion: { [weak self] (response) in
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

										self.present(issuesViewController, animated: true, completion: nil)
									} else {
										// Do not present issues
										issue?.approve()
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
		if let connection = OCConnection(bookmark: bookmark) {
			var options : [OCAuthenticationMethodKey : Any] = [:]

			if let authMethodIdentifier = bookmark?.authenticationMethodIdentifier {
				if isAuthenticationMethodPassphraseBased(authMethodIdentifier as OCAuthenticationMethodIdentifier) {
					options[.usernameKey] = usernameRow?.value ?? ""
					options[.passphraseKey] = passwordRow?.value ?? ""
				}
			}

			options[.presentingViewControllerKey] = self

			hud?.present(on: self, label: "Authenticating…".localized)

			connection.generateAuthenticationData(withMethod: bookmark?.authenticationMethodIdentifier, options: options) { (error, authMethodIdentifier, authMethodData) in
				hudCompletion({
					if error == nil {
						self.bookmark?.authenticationMethodIdentifier = authMethodIdentifier
						self.bookmark?.authenticationData = authMethodData
						self.userActionSave()
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
							self.updateInputFocus(fallbackRow: self.passwordRow)
						} else if nsError?.isOCError(withCode: .authorizationCancelled) == true {
							// User cancelled authorization, no reaction needed
						} else {
							let issuesViewController = ConnectionIssueViewController(displayIssues: issue?.prepareForDisplay(), completion: { [weak self] (response) in
								switch response {
									case .cancel:
										issue?.reject()

									case .approve:
										issue?.approve()
										self?.handleContinue()

									case .dismiss: break
								}
							})

							self.present(issuesViewController, animated: true, completion: nil)
						}
					}
				})
			}
		}
	}

	// MARK: - User actions
	@objc func userActionCancel() {
		self.presentingViewController?.dismiss(animated: true, completion: nil)
	}

	@objc func userActionSave() {
		if isBookmarkComplete(bookmark: self.bookmark) {
			self.bookmark?.authenticationDataStorage = .keychain // Commit auth changes to keychain

			switch mode {
				case .create:
					// Add bookmark
					OCBookmarkManager.shared.addBookmark(bookmark!)
					OCBookmarkManager.shared.saveBookmarks()

				case .edit:
					// Update original bookmark
					originalBookmark?.setValuesFrom(bookmark!)
					OCBookmarkManager.shared.saveBookmarks()
					OCBookmarkManager.shared.postChangeNotification()
			}

			self.presentingViewController?.dismiss(animated: true, completion: nil)
		} else {
			handleContinue()
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
		if bookmark?.certificate != nil {
			if certificateRow != nil, certificateRow?.attached == false {
				urlSection?.add(row: certificateRow!, animated: animated)
			}
		} else {
			if certificateRow != nil, certificateRow?.attached == true {
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
				let authMethodType = authenticationMethodClass.type()

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
							tokenInfoRow?.value = NSString(format:"Authenticated as %@ via %@".localized as NSString, userName, authenticationMethodClass.name())
						} else {
							tokenInfoRow?.value = "Authenticated via".localized + " " + authenticationMethodClass.name()
						}

						if self.bookmark?.authenticationData != nil {
							if tokenInfoRow?.attached == false {
								credentialsSection?.insert(row: tokenInfoRow!, at: 0, animated: animated)
							}

							showCredentialsSection = true
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

		// Continue section: show always
		if isBookmarkComplete(bookmark: self.bookmark) {
			// No continue needed
			if continueSection?.attached == true {
				self.removeSection(continueSection!, animated: animated)
			}
		} else {
			if continueSection?.attached == false {
				self.addSection(continueSection!, animated: animated)
			}
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

			self.nameRow?.textField?.attributedPlaceholder = NSAttributedString(string: placeholderString, attributes: [.foregroundColor : Theme.shared.activeCollection.tableRowColors.secondaryLabelColor])
		}

		// URL
		if urlRow != nil, fieldSelector(urlRow!) {
			if bookmark.originURL != nil {
				urlRow?.value = bookmark.originURL?.absoluteString
			} else if bookmark.url != nil {
				urlRow?.value = bookmark.url?.absoluteString
			} else {
				urlRow?.value = ""
			}
		}

		// Username and password
		var userName : String?
		var password : String?

		if let authMethodIdentifier = bookmark.authenticationMethodIdentifier,
		   isAuthenticationMethodPassphraseBased(authMethodIdentifier as OCAuthenticationMethodIdentifier),
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

	func authenticationMethodTypeForIdentifier(_ authenticationMethodIdentifier: OCAuthenticationMethodIdentifier) -> OCAuthenticationMethodType? {
		if let authenticationMethodClass = OCAuthenticationMethod.registeredAuthenticationMethod(forIdentifier: authenticationMethodIdentifier) {
			return authenticationMethodClass.type()
		}

		return nil
	}

	func isAuthenticationMethodPassphraseBased(_ authenticationMethodIdentifier: OCAuthenticationMethodIdentifier) -> Bool {
		return authenticationMethodTypeForIdentifier(authenticationMethodIdentifier) == OCAuthenticationMethodType.passphrase
	}

	func isAuthenticationMethodTokenBased(_ authenticationMethodIdentifier: OCAuthenticationMethodIdentifier) -> Bool {
		return authenticationMethodTypeForIdentifier(authenticationMethodIdentifier) == OCAuthenticationMethodType.token
	}
}

// MARK: - OCClassSettings support
extension OCClassSettingsIdentifier {
	static let bookmark = OCClassSettingsIdentifier("bookmark")
}

extension OCClassSettingsKey {
	static let bookmarkDefaultURL = OCClassSettingsKey("default-url")
	static let bookmarkURLEditable = OCClassSettingsKey("url-editable")
}

extension BookmarkViewController : OCClassSettingsSupport {
	static let classSettingsIdentifier : OCClassSettingsIdentifier = .bookmark

	static func defaultSettings(forIdentifier identifier: OCClassSettingsIdentifier) -> [OCClassSettingsKey : Any]? {
		if identifier == .bookmark {
			/*
			return [
				.bookmarkDefaultURL : "http://demo.owncloud.org/",
				.bookmarkURLEditable : false
			]
			*/
			return [ : ]
		}

		return nil
	}
}

// MARK: - Keyboard / return key tracking
extension BookmarkViewController : UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if continueButtonRow?.attached == true {
			if !updateInputFocus() {
				handleContinue()
			}

			return false
		}

		return true
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
