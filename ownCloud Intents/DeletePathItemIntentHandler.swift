//
//  DeletePathItemIntentHandler.swift
//  ownCloudAppShared
//
//  Created by Matthias Hühne on 30.08.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import Intents
import ownCloudSDK
import ownCloudAppShared

@available(iOS 13.0, *)
typealias DeletePathItemCompletionHandler = (DeletePathItemIntentResponse) -> Void

@available(iOS 13.0, *)
public class DeletePathItemIntentHandler: NSObject, DeletePathItemIntentHandling, OCCoreDelegate {
	weak var core : OCCore?
	var completionHandler: DeletePathItemCompletionHandler?

	func complete(with response: DeletePathItemIntentResponse) {
		if let completionHandler = completionHandler {
			self.completionHandler = nil

			if let bookmark = core?.bookmark {
				core = nil

				OCCoreManager.shared.returnCore(for: bookmark, completionHandler: {
					completionHandler(response)
				})
			} else {
				completionHandler(response)
			}
		}
	}

	public func core(_ core: OCCore, handleError error: Error?, issue: OCIssue?) {
		if issue?.authenticationError != nil {
			self.complete(with: DeletePathItemIntentResponse(code: .authenticationFailed, userActivity: nil))
		} else if let error = error, error.isAuthenticationError {
			self.complete(with: DeletePathItemIntentResponse(code: .authenticationFailed, userActivity: nil))
		}
	}

	func handle(intent: DeletePathItemIntent, completion: @escaping DeletePathItemCompletionHandler) {

		guard IntentSettings.shared.isEnabled else {
			completion(DeletePathItemIntentResponse(code: .disabled, userActivity: nil))
			return
		}

		guard !AppLockManager.isPassCodeEnabled else {
			completion(DeletePathItemIntentResponse(code: .authenticationRequired, userActivity: nil))
			return
		}

		guard let path = intent.path, let uuid = intent.account?.uuid else {
			completion(DeletePathItemIntentResponse(code: .failure, userActivity: nil))
			return
		}

		guard let bookmark = OCBookmarkManager.shared.bookmark(for: uuid) else {
			completion(DeletePathItemIntentResponse(code: .accountFailure, userActivity: nil))
			return
		}

		guard IntentSettings.shared.isLicensedFor(bookmark: bookmark) else {
			completion(DeletePathItemIntentResponse(code: .unlicensed, userActivity: nil))
			return
		}

		self.completionHandler = completion

		OCItemTracker(for: bookmark, at: path) { (error, core, item) in
			if error == nil, let targetItem = item, core != nil {
				OCCoreManager.shared.requestCore(for: bookmark, setup: { (core, error) in
					core?.delegate = self
				}, completionHandler: { (core, error) in
					if let core = core, error == nil {
						self.core = core

						let progress = core.delete(targetItem, requireMatch: true, resultHandler: { (error, _, _, _) in
							if error != nil {
								self.complete(with: DeletePathItemIntentResponse(code: (error as NSError?)?.isOCError(withCode: .itemNotFound) == true ? .pathFailure : .failure, userActivity: nil))
							} else {
								self.complete(with: DeletePathItemIntentResponse(code: .success, userActivity: nil))
							}
						})

						if progress == nil {
							self.complete(with: DeletePathItemIntentResponse(code: .failure, userActivity: nil))
						}
					} else {
						self.complete(with: DeletePathItemIntentResponse(code: (error?.isAuthenticationError == true) ? .authenticationFailed : .failure, userActivity: nil))
					}
				})
			} else if core != nil {
				self.complete(with: DeletePathItemIntentResponse(code: (error?.isAuthenticationError == true) ? .authenticationFailed : .pathFailure, userActivity: nil))
			} else {
				self.complete(with: DeletePathItemIntentResponse(code: .failure, userActivity: nil))
			}
		}
	}

	func resolveAccount(for intent: DeletePathItemIntent, with completion: @escaping (AccountResolutionResult) -> Void) {
		if let account = intent.account {
			completion(AccountResolutionResult.success(with: account))
		} else {
			completion(AccountResolutionResult.needsValue())
		}
	}

	func provideAccountOptions(for intent: DeletePathItemIntent, with completion: @escaping ([Account]?, Error?) -> Void) {
		completion(OCBookmarkManager.shared.accountList, nil)
	}

	@available(iOSApplicationExtension 14.0, *)
	func provideAccountOptionsCollection(for intent: DeletePathItemIntent, with completion: @escaping (INObjectCollection<Account>?, Error?) -> Void) {
		completion(INObjectCollection(items: OCBookmarkManager.shared.accountList), nil)
	}

	func resolvePath(for intent: DeletePathItemIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		if let path = intent.path {
			completion(INStringResolutionResult.success(with: path))
		} else {
			completion(INStringResolutionResult.needsValue())
		}
	}
}
