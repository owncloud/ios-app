//
//  CreateFolderIntentHandler.swift
//  ownCloudAppShared
//
//  Created by Matthias Hühne on 31.07.19.
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
typealias CreateFolderCompletionHandler = (CreateFolderIntentResponse) -> Void

@available(iOS 13.0, *)
public class CreateFolderIntentHandler: NSObject, CreateFolderIntentHandling, OCCoreDelegate {
	weak var core : OCCore?
	var completionHandler: CreateFolderCompletionHandler?

	func complete(with response: CreateFolderIntentResponse) {
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
			self.complete(with: CreateFolderIntentResponse(code: .authenticationFailed, userActivity: nil))
		} else if let error = error, error.isAuthenticationError {
			self.complete(with: CreateFolderIntentResponse(code: .authenticationFailed, userActivity: nil))
		}
	}

	func handle(intent: CreateFolderIntent, completion: @escaping (CreateFolderIntentResponse) -> Void) {

		guard IntentSettings.shared.isEnabled else {
			completion(CreateFolderIntentResponse(code: .disabled, userActivity: nil))
			return
		}

		guard !AppLockManager.isPassCodeEnabled else {
			completion(CreateFolderIntentResponse(code: .authenticationRequired, userActivity: nil))
			return
		}

		guard let path = intent.path?.pathRepresentation, let uuid = intent.account?.uuid, let name = intent.name else {
			completion(CreateFolderIntentResponse(code: .failure, userActivity: nil))
			return
		}

		guard let bookmark = OCBookmarkManager.shared.bookmark(for: uuid) else {
			completion(CreateFolderIntentResponse(code: .accountFailure, userActivity: nil))
			return
		}

		guard IntentSettings.shared.isLicensedFor(bookmark: bookmark) else {
			completion(CreateFolderIntentResponse(code: .unlicensed, userActivity: nil))
			return
		}

		self.completionHandler = completion

		OCItemTracker(for: bookmark, at: path, waitOnlineTimeout: 5) { (error, core, item) in
			if error == nil, let targetItem = item {
				let folderPath = String(format: "%@%@", path, name)
				// Check, if the folder already exists in the given path
				OCItemTracker(for: bookmark, at: folderPath, waitOnlineTimeout: 5) { (error, core, folderPathItem) in
					if error == nil, folderPathItem == nil, let core = core {
						let waitForCompletion = intent.waitForCompletion as? Bool ?? false
						let bookmark = core.bookmark

						OCCoreManager.shared.requestCore(for: bookmark, setup: { (core, error) in
							core?.delegate = self
						}, completionHandler: { (core, error) in
							if let core = core {
								self.core = core

								let handleCompletion = { (error: Error?, item: OCItem?) in
									if error != nil {
										self.complete(with: CreateFolderIntentResponse(code: .failure, userActivity: nil))
									} else {
										self.complete(with: CreateFolderIntentResponse.success(path: item?.path ?? ""))
									}
								}

								if core.createFolder(name, inside: targetItem, options: nil, placeholderCompletionHandler: waitForCompletion ? nil : handleCompletion, resultHandler: waitForCompletion ? { (error, _, item, _) in
									handleCompletion(error, item)
								} : nil) == nil {
									self.complete(with: CreateFolderIntentResponse(code: .failure, userActivity: nil))
								}
							} else if error?.isAuthenticationError == true {
								self.complete(with: CreateFolderIntentResponse(code: .authenticationFailed, userActivity: nil))
							} else {
								self.complete(with: CreateFolderIntentResponse(code: .failure, userActivity: nil))
							}
						})
					} else if core != nil {
						self.complete(with: CreateFolderIntentResponse(code: (error?.isAuthenticationError == true) ? .authenticationFailed : .folderExistsFailure, userActivity: nil))
					} else {
						self.complete(with: CreateFolderIntentResponse(code: .failure, userActivity: nil))
					}
				}
			} else if core != nil {
				self.complete(with: CreateFolderIntentResponse(code: .pathFailure, userActivity: nil))
			} else {
				self.complete(with: CreateFolderIntentResponse(code: .failure, userActivity: nil))
			}
		}
	}

	func resolveName(for intent: CreateFolderIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		if let name = intent.name {
			completion(INStringResolutionResult.success(with: name))
		} else {
			completion(INStringResolutionResult.needsValue())
		}
	}

	func resolveAccount(for intent: CreateFolderIntent, with completion: @escaping (AccountResolutionResult) -> Void) {
		if let account = intent.account {
			completion(AccountResolutionResult.success(with: account))
		} else {
			completion(AccountResolutionResult.needsValue())
		}
	}

	func provideAccountOptions(for intent: CreateFolderIntent, with completion: @escaping ([Account]?, Error?) -> Void) {
		completion(OCBookmarkManager.shared.accountList, nil)
	}

	@available(iOSApplicationExtension 14.0, *)
	func provideAccountOptionsCollection(for intent: CreateFolderIntent, with completion: @escaping (INObjectCollection<Account>?, Error?) -> Void) {
		completion(INObjectCollection(items: OCBookmarkManager.shared.accountList), nil)
	}

	func resolvePath(for intent: CreateFolderIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		if let path = intent.path {
			completion(INStringResolutionResult.success(with: path))
		} else {
			completion(INStringResolutionResult.needsValue())
		}
	}

	func resolveWaitForCompletion(for intent: CreateFolderIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) {
		var waitForCompletion = false
		if let doWait = intent.waitForCompletion?.boolValue {
			waitForCompletion = doWait
		}
		completion(INBooleanResolutionResult.success(with: waitForCompletion))
	}
}

@available(iOS 13.0, *)
extension CreateFolderIntentResponse {

    public static func success(path: String) -> CreateFolderIntentResponse {
        let intentResponse = CreateFolderIntentResponse(code: .success, userActivity: nil)
        intentResponse.path = path
        return intentResponse
    }
}
