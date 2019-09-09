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

public class GetFileInfoIntentHandler: NSObject, GetFileInfoIntentHandling {

	var itemTracking : OCCoreItemTracking?

	public func handle(intent: GetFileInfoIntent, completion: @escaping (GetFileInfoIntentResponse) -> Void) {
		if AppLockHelper().isPassCodeEnabled {
			completion(GetFileInfoIntentResponse(code: .authenticationRequired, userActivity: nil))
		} else {
			if let path = intent.path, let uuid = intent.account?.uuid {
				let accountBookmark = OCBookmarkManager.shared.bookmark(for: uuid)

				if let bookmark = accountBookmark {
					OCCoreManager.shared.requestCore(for: bookmark, setup: nil, completionHandler: { (core, error) in
						if error == nil, let core = core {
							self.itemTracking = core.trackItem(atPath: path, trackingHandler: { (error, item, isInitial) in
								if error == nil, let targetItem = item {
									let fileInfo = FileInfo(identifier: targetItem.localID, display: targetItem.name ?? "")

									if let creationDate = targetItem.creationDate {
										let calendar = Calendar.current
										let components = calendar.dateComponents([.day, .month, .year, .hour, .minute, .second], from: creationDate)
										fileInfo.creationDate = components
										fileInfo.creationDateTimestamp = NSNumber(value: creationDate.timeIntervalSince1970)
									}
									if let lastModified = targetItem.lastModified {
										let calendar = Calendar.current
										let components = calendar.dateComponents([.day, .month, .year, .hour, .minute, .second], from: lastModified)
										fileInfo.lastModified = components
										fileInfo.lastModifiedTimestamp = NSNumber(value: lastModified.timeIntervalSince1970)
									}
									fileInfo.isFavorite = targetItem.isFavorite
									fileInfo.mimeType = targetItem.mimeType
									fileInfo.size = NSNumber(value: targetItem.size)

									completion(GetFileInfoIntentResponse.success(fileInfo: fileInfo))
								} else {
									completion(GetFileInfoIntentResponse(code: .pathFailure, userActivity: nil))
								}

								if isInitial {
									self.itemTracking = nil
								}
							})

						} else {
							completion(GetFileInfoIntentResponse(code: .failure, userActivity: nil))
						}
				})
				}
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

extension GetFileInfoIntentResponse {

    @available(iOS 13.0, watchOS 6.0, *)
    public static func success(fileInfo: FileInfo) -> GetFileInfoIntentResponse {
        let intentResponse = GetFileInfoIntentResponse(code: .success, userActivity: nil)
        intentResponse.fileInfo = fileInfo
        return intentResponse
    }
}
