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

@available(iOS 13.0, *)
typealias GetFileCompletionHandler = (GetFileIntentResponse) -> Void

@available(iOS 13.0, *)
public class GetFileIntentHandler: NSObject, GetFileIntentHandling {

	public func handle(intent: GetFileIntent, completion: @escaping (GetFileIntentResponse) -> Void) {

		guard !AppLockHelper().isPassCodeEnabled else {
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

		OCItemTracker().item(for: bookmark, at: path) { (error, core, item) in
			if error == nil, let item = item {
				if core?.localCopy(of: item) == nil {
					core?.downloadItem(item, options: [ .returnImmediatelyIfOfflineOrUnavailable : true ], resultHandler: { (error, core, item, file) in
						if error == nil, let item = item, let file = item.file(with: core), let url = file.url {
							let file = INFile(fileURL: url, filename: item.name, typeIdentifier: nil)
							completion(GetFileIntentResponse.success(file: file))
						} else {
							completion(GetFileIntentResponse(code: .failure, userActivity: nil))
						}
					})
				} else if let core = core, let file = item.file(with: core), let url = file.url {
					let file = INFile(fileURL: url, filename: item.name, typeIdentifier: nil)
					completion(GetFileIntentResponse.success(file: file))
				}
			} else if core != nil {
				completion(GetFileIntentResponse(code: .pathFailure, userActivity: nil))
			} else {
				completion(GetFileIntentResponse(code: .failure, userActivity: nil))
			}
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

@available(iOS 13.0, *)
extension GetFileIntentResponse {

    public static func success(file: INFile) -> GetFileIntentResponse {
        let intentResponse = GetFileIntentResponse(code: .success, userActivity: nil)
        intentResponse.file = file
        return intentResponse
    }
}
