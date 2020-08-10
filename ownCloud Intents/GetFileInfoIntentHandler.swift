//
//  GetFileInfoIntentHandler.swift
//  ownCloudAppShared
//
//  Created by Matthias Hühne on 27.08.19.
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
public class GetFileInfoIntentHandler: NSObject, GetFileInfoIntentHandling {

	public func handle(intent: GetFileInfoIntent, completion: @escaping (GetFileInfoIntentResponse) -> Void) {

		guard IntentSettings.shared.isEnabled else {
			completion(GetFileInfoIntentResponse(code: .disabled, userActivity: nil))
			return
		}

		guard !AppLockManager.isPassCodeEnabled else {
			completion(GetFileInfoIntentResponse(code: .authenticationRequired, userActivity: nil))
			return
		}

		guard let path = intent.path, let uuid = intent.account?.uuid else {
			completion(GetFileInfoIntentResponse(code: .failure, userActivity: nil))
			return
		}

		guard let bookmark = OCBookmarkManager.shared.bookmark(for: uuid) else {
			completion(GetFileInfoIntentResponse(code: .accountFailure, userActivity: nil))
			return
		}

		guard IntentSettings.shared.isLicensedFor(bookmark: bookmark) else {
			completion(GetFileInfoIntentResponse(code: .unlicensed, userActivity: nil))
			return
		}

		OCItemTracker().item(for: bookmark, at: path) { (error, core, item) in
			if error == nil, let targetItem = item {
				let fileInfo = FileInfo(identifier: targetItem.localID, display: targetItem.name ?? "")

				let calendar = Calendar.current
				if let creationDate = targetItem.creationDate {
					let components = calendar.dateTimeComponents(from: creationDate)
					fileInfo.creationDate = components
					fileInfo.creationDateTimestamp = NSNumber(value: creationDate.timeIntervalSince1970)
				}
				if let lastModified = targetItem.lastModified {
					let components = calendar.dateTimeComponents(from: lastModified)
					fileInfo.lastModified = components
					fileInfo.lastModifiedTimestamp = NSNumber(value: lastModified.timeIntervalSince1970)
				}
				fileInfo.isFavorite = targetItem.isFavorite
				fileInfo.mimeType = targetItem.mimeType
				fileInfo.size = NSNumber(value: targetItem.size)

				completion(GetFileInfoIntentResponse.success(fileInfo: fileInfo))
			} else if core != nil {
				completion(GetFileInfoIntentResponse(code: .pathFailure, userActivity: nil))
			} else {
				completion(GetFileInfoIntentResponse(code: .failure, userActivity: nil))
			}
		}
	}

	public func resolveAccount(for intent: GetFileInfoIntent, with completion: @escaping (AccountResolutionResult) -> Void) {
		if let account = intent.account {
			completion(AccountResolutionResult.success(with: account))
		} else {
			completion(AccountResolutionResult.needsValue())
		}
	}

	public func provideAccountOptions(for intent: GetFileInfoIntent, with completion: @escaping ([Account]?, Error?) -> Void) {
		completion(OCBookmarkManager.shared.accountList, nil)
	}

	public func resolvePath(for intent: GetFileInfoIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		if let path = intent.path {
			completion(INStringResolutionResult.success(with: path))
		} else {
			completion(INStringResolutionResult.needsValue())
		}
	}

}

@available(iOS 13.0, *)
extension GetFileInfoIntentResponse {

    public static func success(fileInfo: FileInfo) -> GetFileInfoIntentResponse {
        let intentResponse = GetFileInfoIntentResponse(code: .success, userActivity: nil)
        intentResponse.fileInfo = fileInfo
        return intentResponse
    }
}
