//
//  AccountConnectionErrorHandler.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 28.11.22.
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

public protocol AccountAuthenticationHandlerBookmarkEditingHandler: AnyObject {
	func handleAuthError(for viewController: UIViewController, error: NSError, editBookmark: OCBookmark?, preferredAuthenticationMethods: [OCAuthenticationMethodIdentifier]?)
}

open class AccountConnectionErrorHandler: NSObject, AccountConnectionCoreErrorHandler {
	var connection: AccountConnection
	var consumer: AccountConnectionConsumer?
	var context: ClientContext

	init(for context: ClientContext, connection: AccountConnection? = nil) {
		self.context = context
		self.connection = connection ?? context.accountConnection!

		super.init()

		consumer = AccountConnectionConsumer(owner: self, coreErrorHandler: self)
		self.connection.add(consumer: consumer!)
	}

	deinit {
		connection.remove(consumer: consumer!)
	}

	public func account(connnection: AccountConnection, handleError error: Error?, issue inIssue: OCIssue?) -> Bool {
		var issue = inIssue
		var nsError = error as NSError?

		Log.debug("Received error \(nsError?.description ?? "nil")), issue \(issue?.description ?? "nil")")

		if let authError = issue?.authenticationError {
			// Turn issues that are just converted authorization errors back into errors and discard the issue
			nsError = authError
			issue = nil
		}

		Log.debug("Received error \(nsError?.description ?? "nil")), issue \(issue?.description ?? "nil")")

		if nsError?.isAccountConnectionAuthenticationError == true {
			return false
		} else {
			context.alertQueue?.async { [weak self] (queueCompletionHandler) in
				var presentIssue : OCIssue? = issue
				var queueCompletionHandlerScheduled : Bool = false

				if issue == nil, let error = error {
					presentIssue = OCIssue(forError: error, level: .error, issueHandler: nil)
				}

				if presentIssue != nil {
					var presentViewController : UIViewController?
					var onViewController : UIViewController?

					if let startViewController = self?.context.presentationViewController {
						var hostViewController : UIViewController = startViewController

						while hostViewController.presentedViewController != nil,
						      hostViewController.presentedViewController?.isBeingDismissed == false {
							hostViewController = hostViewController.presentedViewController!
						}

						onViewController = hostViewController
					}

					if let presentIssue = presentIssue, presentIssue.type == .multipleChoice {
						presentViewController = ThemedAlertController(with: presentIssue, completion: queueCompletionHandler)
					} else if let onViewController = onViewController, let presentIssue = presentIssue {
						IssuesCardViewController.present(on: onViewController, issue: presentIssue, bookmark: self?.connection.bookmark, completion: { [weak presentIssue] (response) in
							switch response {
								case .cancel:
									presentIssue?.reject()

								case .approve:
									presentIssue?.approve()

								case .dismiss: break
							}
							queueCompletionHandler()
						})

						queueCompletionHandlerScheduled = true
					}

					if let presentViewController = presentViewController, let onViewController = onViewController {
						queueCompletionHandlerScheduled = true
						onViewController.present(presentViewController, animated: true, completion: nil)
					}
				}

				if !queueCompletionHandlerScheduled {
					queueCompletionHandler()
				}
			}
		}

		return true
	}
}
