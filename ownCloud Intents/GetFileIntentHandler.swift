//
//  GetFileIntentHandler.swift
//  ownCloudAppShared
//
//  Created by Matthias Hühne on 30.07.19.
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
typealias GetFileCompletionHandler = (GetFileIntentResponse) -> Void

@available(iOS 13.0, *)
public class GetFileIntentHandler: NSObject, GetFileIntentHandling, OCCoreDelegate {
	weak var core : OCCore?
	var completionHandler: GetFileCompletionHandler?

	func complete(with response: GetFileIntentResponse) {
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
			self.complete(with: GetFileIntentResponse(code: .authenticationFailed, userActivity: nil))
		} else if let error = error, error.isAuthenticationError {
			self.complete(with: GetFileIntentResponse(code: .authenticationFailed, userActivity: nil))
		}
	}

	func handle(intent: GetFileIntent, completion: @escaping (GetFileIntentResponse) -> Void) {

		guard IntentSettings.shared.isEnabled else {
			completion(GetFileIntentResponse(code: .disabled, userActivity: nil))
			return
		}

		guard !AppLockManager.isPassCodeEnabled else {
			completion(GetFileIntentResponse(code: .authenticationRequired, userActivity: nil))
			return
		}

		guard let path = intent.path, let uuid = intent.account?.uuid else {
			completion(GetFileIntentResponse(code: .failure, userActivity: nil))
			return
		}

		guard let bookmark = OCBookmarkManager.shared.bookmark(for: uuid) else {
			completion(GetFileIntentResponse(code: .accountFailure, userActivity: nil))
			return
		}

		guard IntentSettings.shared.isLicensedFor(bookmark: bookmark) else {
			completion(GetFileIntentResponse(code: .unlicensed, userActivity: nil))
			return
		}

		self.completionHandler = completion

		OCItemTracker(for: bookmark, at: path, waitOnlineTimeout: 5) { (error, core, item) in
			if error == nil, let item = item {
				if core?.localCopy(of: item) == nil {
					OCCoreManager.shared.requestCore(for: bookmark, setup: { (core, error) in
						core?.delegate = self
					}, completionHandler: { (core, error) in
						if let core = core {
							self.core = core

							OnBackgroundQueue {
								core.downloadItem(item, options: nil /* [ .returnImmediatelyIfOfflineOrUnavailable : true ] */, resultHandler: { (error, core, item, file) in
									if error == nil, let item = item, let file = item.file(with: core), let url = file.url {
										let file = INFile(fileURL: url, filename: item.name, typeIdentifier: nil)
										self.complete(with: GetFileIntentResponse.success(file: file))
									} else if let error = error, error.isAuthenticationError {
										self.complete(with: GetFileIntentResponse(code: .authenticationFailed, userActivity: nil))
									} else if let error = error as NSError?, error.isOCError(withCode: .itemNotAvailableOffline) {
										self.complete(with: GetFileIntentResponse(code: (core.connectionStatus == .online) ? .authenticationFailed : .fileNotAvailableOffline, userActivity: nil))
									} else {
										self.complete(with: GetFileIntentResponse(code: .failure, userActivity: nil))
									}
								})
							}
						} else {
							self.complete(with: GetFileIntentResponse(code: .failure, userActivity: nil))
						}
					})
				} else if let core = core, let file = item.file(with: core), let url = file.url {
					let file = INFile(fileURL: url, filename: item.name, typeIdentifier: nil)
					self.complete(with: GetFileIntentResponse.success(file: file))
				}
			} else if core != nil {
				if core?.connectionStatus == .online {
					self.complete(with: GetFileIntentResponse(code: .pathFailure, userActivity: nil))
				}
			} else if let error = error, error.isAuthenticationError {
				self.complete(with: GetFileIntentResponse(code: .authenticationFailed, userActivity: nil))
			} else {
				self.complete(with: GetFileIntentResponse(code: .failure, userActivity: nil))
			}
		}
	}

	func resolvePath(for intent: GetFileIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		if let path = intent.path {
			completion(INStringResolutionResult.success(with: path))
		} else {
			completion(INStringResolutionResult.needsValue())
		}
	}

	func provideAccountOptions(for intent: GetFileIntent, with completion: @escaping ([Account]?, Error?) -> Void) {
		completion(OCBookmarkManager.shared.accountList, nil)
	}

	@available(iOSApplicationExtension 14.0, *)
	func provideAccountOptionsCollection(for intent: GetFileIntent, with completion: @escaping (INObjectCollection<Account>?, Error?) -> Void) {
		completion(INObjectCollection(items: OCBookmarkManager.shared.accountList), nil)
	}

	func resolveAccount(for intent: GetFileIntent, with completion: @escaping (AccountResolutionResult) -> Void) {
		if let account = intent.account {
			completion(AccountResolutionResult.success(with: account))
		} else {
			completion(AccountResolutionResult.needsValue())
		}
	}
}

@available(iOS 13.0, *)
extension GetFileIntentResponse {

    public static func success(file: INFile) -> GetFileIntentResponse {
        let intentResponse = GetFileIntentResponse(code: .success, userActivity: nil)
        intentResponse.file = file
        return intentResponse
    }
}
