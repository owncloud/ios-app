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

@available(iOS 13.0, watchOS 6.0, *)
typealias GetFileCompletionHandler = (GetFileIntentResponse) -> Void

@available(iOS 13.0, watchOS 6.0, *)
public class GetFileIntentHandler: NSObject, GetFileIntentHandling {

	var core : OCCore?
	var completion : GetFileCompletionHandler?
	var itemTracking : OCCoreItemTracking?

	public func handle(intent: GetFileIntent, completion: @escaping (GetFileIntentResponse) -> Void) {

		if AppLockHelper().isPassCodeEnabled {
			completion(GetFileIntentResponse(code: .authenticationRequired, userActivity: nil))
		} else {
			if let path = intent.path, let uuid = intent.account?.uuid {
				let accountBookmark = OCBookmarkManager.shared.bookmark(for: uuid)

				if let bookmark = accountBookmark {
					OCCoreManager.shared.requestCore(for: bookmark, setup: nil, completionHandler: { (core, error) in
						if error == nil {
							self.core = core
							self.itemTracking = self.core?.trackItem(atPath: path, trackingHandler: { (error, item, isInitial) in
								if let item = item {
									if core?.localCopy(of: item) == nil {
										core?.downloadItem(item, options: [ .returnImmediatelyIfOfflineOrUnavailable : true ], resultHandler: { (error, core, item, file) in
											if error == nil {
												if let item = item, let file = item.file(with: core) {
													if let url = file.url {
														let file = INFile(fileURL: url, filename: item.name, typeIdentifier: item.mimeType)

														self.completion?(GetFileIntentResponse.success(file: file))
														self.completion = nil
													}
												}
											} else {
												self.completion?(GetFileIntentResponse(code: .failure, userActivity: nil))
												self.completion = nil
											}
										})
									} else {
										if let core = core, let file = item.file(with: core) {
											if let url = file.url {
												let file = INFile(fileURL: url, filename: item.name, typeIdentifier: item.mimeType)

												self.completion?(GetFileIntentResponse.success(file: file))
												self.completion = nil
											}
										}
									}

								} else {
									self.completion?(GetFileIntentResponse(code: .pathFailure, userActivity: nil))
									self.completion = nil
								}

								if isInitial {
									self.itemTracking = nil
								}
							})
						} else {
							self.completion?(GetFileIntentResponse(code: .failure, userActivity: nil))
						}
					})
				} else {
					completion(GetFileIntentResponse(code: .accountFailure, userActivity: nil))
				}
			}

			self.completion = completion
		}
	}

	public func resolvePath(for intent: GetFileIntent, with completion: @escaping (INStringResolutionResult) -> Void) {

		if let path = intent.path {
			completion(INStringResolutionResult.success(with: path))
		} else {
			completion(INStringResolutionResult.needsValue())
		}
	}

	public func provideAccountOptions(for intent: GetFileIntent, with completion: @escaping ([Account]?, Error?) -> Void) {
		completion(OCBookmarkManager.shared.accountList, nil)
	}

	public func resolveAccount(for intent: GetFileIntent, with completion: @escaping (AccountResolutionResult) -> Void) {
		if let account = intent.account {
			completion(AccountResolutionResult.success(with: account))
		} else {
			completion(AccountResolutionResult.needsValue())
		}
	}
}

@available(iOS 13.0, watchOS 6.0, *)
extension GetFileIntentResponse {

    public static func success(file: INFile) -> GetFileIntentResponse {
        let intentResponse = GetFileIntentResponse(code: .success, userActivity: nil)
        intentResponse.file = file
        return intentResponse
    }
}
