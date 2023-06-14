//
//  AccountConnectionAuthErrorConsumer.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 29.11.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

extension Error {
	var isAccountConnectionAuthenticationError: Bool {
		if let nsError = self as NSError? {
			if nsError.isOCError(withCode: .authorizationFailed) {
				return true
			}

			if nsError.isOCError(withCode: .authorizationNoMethodData) || nsError.isOCError(withCode: .authorizationMissingData) {
				return true
			}

			if nsError.isOCError(withCode: .authorizationMethodNotAllowed) {
				return true
			}
		}

		return false
	}
}

class AccountConnectionAuthErrorConsumer: AccountConnectionConsumer, AccountConnectionCoreErrorHandler, AccountConnectionStatusObserver {
	weak var connection: AccountConnection?

	init(for connection: AccountConnection) {
		self.connection = connection
		super.init()
		self.coreErrorHandler = self
		self.statusObserver = self
	}

	var skipAuthorizationFailure: Bool = false

	var bookmark: OCBookmark? {
		return connection?.bookmark
	}

	public var authenticationFailure: AccountConnection.AuthFailure? {
		didSet {
			if let authenticationFailure {
				connection?.status = .authenticationError(failure: authenticationFailure)
			}
		}
	}

	public func account(connection: AccountConnection, changedStatusTo status: AccountConnection.Status, initial: Bool) {
		if case .noCore = status {
			skipAuthorizationFailure = false
		}
	}

	public func account(connnection: AccountConnection, handleError error: Error?, issue inIssue: OCIssue?) -> Bool {
		guard let connection = connection, let core = connection.core else {
			return false
		}

		var issue = inIssue
		var isAuthFailure : Bool = false
		var authFailureMessage : String?
		var authFailureTitle : String = "Authorization failed".localized
		var authFailureHasEditOption : Bool = true
		var authFailureIgnoreLabel = "Continue offline".localized
		var authFailureIgnoreStyle = UIAlertAction.Style.destructive
		let editBookmark = connection.bookmark
		var nsError = error as NSError?

		Log.debug("Received error \(nsError?.description ?? "nil")), issue \(issue?.description ?? "nil")")

		if let authError = issue?.authenticationError {
			// Turn issues that are just converted authorization errors back into errors and discard the issue
			nsError = authError
			issue = nil
		}

		Log.debug("Received error \(nsError?.description ?? "nil")), issue \(issue?.description ?? "nil")")

		if let nsError = nsError {
			if nsError.isOCError(withCode: .authorizationFailed) {
				if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError, underlyingError.isDAVException, underlyingError.davExceptionMessage == "User disabled" {
					authFailureHasEditOption = false
					authFailureIgnoreStyle = .cancel
					authFailureIgnoreLabel = "Continue offline".localized
					authFailureMessage = "The account has been disabled."
				} else {
					if connection.bookmark.isTokenBased == true {
						authFailureTitle = "Access denied".localized
						authFailureMessage = "The connection's access token has expired or become invalid. Sign in again to re-gain access.".localized

						if let localizedDescription = nsError.userInfo[NSLocalizedDescriptionKey] {
							authFailureMessage = "\(authFailureMessage!)\n\n(\(localizedDescription))"
						}
					} else {
						authFailureMessage = "The server declined access with the credentials stored for this connection.".localized
					}
				}

				isAuthFailure = true
			}

			if nsError.isOCError(withCode: .authorizationNoMethodData) || nsError.isOCError(withCode: .authorizationMissingData) {
				authFailureMessage = "No authentication data has been found for this connection.".localized

				isAuthFailure = true
			}

			if nsError.isOCError(withCode: .authorizationMethodNotAllowed) {
				authFailureMessage = NSString(format: "Authentication with %@ is no longer allowed. Re-authentication needed.".localized as NSString, core.connection.authenticationMethod?.name ?? "??") as String

				isAuthFailure = true
			}

			if isAuthFailure {
				// Make sure only the first auth failure will actually lead to an alert
				// (otherwise alerts could keep getting enqueued while the first alert is being shown,
				// and then be presented even though they're no longer relevant). It's ok to only show
				// an alert for the first auth failure, because the options are "Continue offline" (=> no longer show them)
				// and "Edit" (=> log out, go to bookmark editing)
				var doSkip = false

				OCSynchronized(self) {
					doSkip = skipAuthorizationFailure  // Keep in mind OCSynchronized() contents is running as a block, so "return" in here wouldn't have the desired effect
					skipAuthorizationFailure = true
				}

				if doSkip {
					Log.debug("Skip authorization failure")
					return false
				}
			}
		}

		Log.debug("Handling error \(String(describing: error)) / \(String(describing: issue)) with isAuthFailure=\(isAuthFailure), bookmarkURL= \(String(describing: connection.bookmark.url)), authFailureHasEditOption=\(authFailureHasEditOption), authFailureIgnoreStyle=\(authFailureIgnoreStyle), authFailureIgnoreLabel=\(authFailureIgnoreLabel), authFailureMessage=\(String(describing: authFailureMessage))")

		if isAuthFailure {
			let authFailure = AccountConnection.AuthFailure(bookmark: editBookmark, error: nsError, title: authFailureTitle, message: authFailureMessage, ignoreLabel: authFailureIgnoreLabel, ignoreStyle: authFailureIgnoreStyle, hasEditOption: authFailureHasEditOption, failureResolver: { [weak self] (authFailure, context) in
				self?.attemptLogin(for: authFailure, context: context)
			})

			authenticationFailure = authFailure

			return true
		}

		return false
	}

	func attemptLogin(for authFailure: AccountConnection.AuthFailure, context: ClientContext) {
		guard let bookmark = context.accountConnection?.bookmark, let bookmarkURL = bookmark.url else {
			return
		}

		// Clone bookmark
		let clonedBookmark = OCBookmark(for: bookmarkURL)

		// Carry over permission for plain HTTP connections
		clonedBookmark.userInfo[OCBookmarkUserInfoKey.allowHTTPConnection] =  bookmark.userInfo[OCBookmarkUserInfoKey.allowHTTPConnection]

		// Create connection
		let connection = OCConnection(bookmark: clonedBookmark)

		if let cookieSupportEnabled = OCCore.classSetting(forOCClassSettingsKey: .coreCookieSupportEnabled) as? Bool, cookieSupportEnabled == true {
			connection.cookieStorage = OCHTTPCookieStorage()
			Log.debug("Created cookie storage \(String(describing: connection.cookieStorage)) for client root view auth method detection")
		}

		connection.prepareForSetup(options: nil, completionHandler: { [weak self] (issue, suggestedURL, supportedMethods, preferredMethods, generationOptions) in
			Log.debug("Preparing for handling authentication error: issue=\(issue?.description ?? "nil"), suggestedURL=\(suggestedURL?.absoluteString ?? "nil"), supportedMethods: \(supportedMethods?.description ?? "nil"), preferredMethods: \(preferredMethods?.description ?? "nil"), existingAuthMethod: \(context.accountConnection?.bookmark.authenticationMethodIdentifier?.rawValue ?? "nil"))")

			if let preferredMethods = preferredMethods, preferredMethods.count > 0 {
				if let existingAuthMethod = context.accountConnection?.bookmark.authenticationMethodIdentifier, !preferredMethods.contains(existingAuthMethod), let bookmark = context.accountConnection?.bookmark {
					// Authentication method no longer supported
					bookmark.scanForAuthenticationMethodsRequired = true // Mark bookmark as requiring a scan for available authentication methods before editing
					OCBookmarkManager.shared.updateBookmark(bookmark)
				}
			} else {
				// Supported authentication methods unclear -> rescan
				if let bookmark = context.accountConnection?.bookmark {
					bookmark.scanForAuthenticationMethodsRequired = true // Mark bookmark as requiring a scan for available authentication methods before editing
					OCBookmarkManager.shared.updateBookmark(bookmark)
				}
			}

			context.alertQueue?.async { [weak self] (queueCompletionHandler) in
				self?.presentAuthAlert(for: authFailure, preferredAuthenticationMethods: preferredMethods, context: context, completionHandler: queueCompletionHandler)
			}
		})
	}

	func presentAuthAlert(for authFailure: AccountConnection.AuthFailure, preferredAuthenticationMethods: [OCAuthenticationMethodIdentifier]?, context: ClientContext, completionHandler: @escaping () -> Void) {
		let alertController = ThemedAlertController(title: authFailure.title,
							message: authFailure.message,
							preferredStyle: .alert)

		alertController.addAction(UIAlertAction(title: authFailure.ignoreLabel, style: authFailure.ignoreStyle, handler: { (_) in
			completionHandler()
		}))

		if authFailure.hasEditOption {
			let action = UIAlertAction(title: "Sign in".localized, style: .default, handler: { [weak self] (_) in
				completionHandler()

				var notifyAuthDelegate = true

				if let bookmark = self?.connection?.bookmark {
					// var authenticationUpdater: AccountConnectionAuthenticationUpdater.Type?
					// let updater = authenticationUpdater?.init(with: bookmark, preferredAuthenticationMethods: preferredAuthenticationMethods)
					let updater = AccountAuthenticationUpdater(with: bookmark, preferredAuthenticationMethods: preferredAuthenticationMethods)

					if updater.canUpdateInline, let self = self, let viewController = context.presentationViewController {
						notifyAuthDelegate = false

						updater.updateAuthenticationData(on: viewController, completion: { (error) in
							if error == nil {
								OCSynchronized(self) {
									self.skipAuthorizationFailure = false // Auth failure fixed -> allow new failures to prompt for sign in again
								}
								self.connection?.updateConnectionStatusSummary() // Trigger status summary update to clear connection._authFailureStatus
							} else if let nsError = error as NSError?, !nsError.isOCError(withCode: .authorizationCancelled) {
								// Error updating authentication -> inform the user and provide option to retry
								context.alertQueue?.async { [weak self] (queueCompletionHandler) in
									let newAuthFail = AccountConnection.AuthFailure(bookmark: authFailure.bookmark, error: error as NSError?, title: "Error".localized, message: error?.localizedDescription, ignoreLabel: authFailure.ignoreLabel, ignoreStyle: authFailure.ignoreStyle, hasEditOption: authFailure.hasEditOption)

									self?.presentAuthAlert(for: newAuthFail, preferredAuthenticationMethods: preferredAuthenticationMethods, context: context, completionHandler: queueCompletionHandler)
								}
							}
						})
					}
				}

				if notifyAuthDelegate {
					if let authDelegate = context.bookmarkEditingHandler, let presentationViewController = context.presentationViewController, let nsError = authFailure.error {
						self?.connection?.disconnect(consumer: nil, completion: { error in
							authDelegate.handleAuthError(for: presentationViewController, error: nsError, editBookmark: authFailure.bookmark, preferredAuthenticationMethods: preferredAuthenticationMethods)
						})
					} else {
						context.alertQueue?.async({ [weak context] (queueCompletionHandler) in
							let alertController = ThemedAlertController(title: "Authentication failed".localized,
												    message: "Please open the app and select the account to re-authenticate.".localized,
												    preferredStyle: .alert)

							alertController.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: { _ in
								queueCompletionHandler()
							}))

							context?.present(alertController, animated: true)
						})
					}

					completionHandler()
				}
			})

			alertController.addAction(action)
		}

		context.present(alertController, animated: true, completion: nil)
	}
}
