//
//  GetAccountsIntentHandler.swift
//  ownCloud
//
//  Created by Matthias Hühne on 24.07.19.
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

typealias GetDirectoryListingCompletionHandler = (GetDirectoryListingIntentResponse) -> Void

public class GetDirectoryListingIntentHandler: NSObject, GetDirectoryListingIntentHandling, OCQueryDelegate {

	var core : OCCore?
	var completion : GetDirectoryListingCompletionHandler?

	public func resolveAccountUUID(for intent: GetDirectoryListingIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		if let accountUUID = intent.accountUUID {
			completion(INStringResolutionResult.success(with: accountUUID))
		} else {
			completion(INStringResolutionResult.needsValue())
		}
	}
/*
	public func resolveAccount(for intent: GetDirectoryListingIntent, with completion: @escaping (AccountResolutionResult) -> Void) {

		if let account = intent.account {
			completion(AccountResolutionResult.success(with: account))
		} else {
			completion(AccountResolutionResult.needsValue())
		}
	}
*/
	public func resolvePath(for intent: GetDirectoryListingIntent, with completion: @escaping (INStringResolutionResult) -> Void) {

		if let path = intent.path {
			completion(INStringResolutionResult.success(with: path))
		} else {
			completion(INStringResolutionResult.needsValue())
		}

	}

	@available(iOS 12.0, *)
	public func handle(intent: GetDirectoryListingIntent, completion: @escaping (GetDirectoryListingIntentResponse) -> Void) {
		if let path = intent.path, let uuid = intent.accountUUID {

			var accountBookmark : OCBookmark?
			for bookmark in OCBookmarkManager.shared.bookmarks {
				if bookmark.uuid.uuidString == uuid {
					accountBookmark = bookmark
					break
				}
			}

			if let bookmark = accountBookmark {
				OCCoreManager.shared.requestCore(for: bookmark, setup: { (core, error) in
				}) { (core, error) in
					if error == nil {
						self.core = core
						let targetDirectoryQuery = OCQuery(forPath: path)
						targetDirectoryQuery.delegate = self
						core?.start(targetDirectoryQuery)
					} else {
						self.completion?(GetDirectoryListingIntentResponse(code: .failure, userActivity: nil))
					}
				}
			}
		}

		self.completion = completion
	}

	public func queryHasChangesAvailable(_ query: OCQuery) {
		var directoryListing : [String] = []
		if let results = query.queryResults {
			for item in results {
				if let path = item.path {
					directoryListing.append(path)
				}
			}
		}

		self.completion?(GetDirectoryListingIntentResponse.success(directoryListing: directoryListing))
		self.completion = nil
	}

	public func query(_ query: OCQuery, failedWithError error: Error) {
		self.completion?(GetDirectoryListingIntentResponse(code: .failure, userActivity: nil))
	}

	@available(iOS 12.0, *)
	public func confirm(intent: GetDirectoryListingIntent, completion: @escaping (GetDirectoryListingIntentResponse) -> Void) {
        completion(GetDirectoryListingIntentResponse(code: .ready, userActivity: nil))
	}
}

extension GetDirectoryListingIntentResponse {

    @available(iOS 13.0, watchOS 6.0, *)
    public static func success(directoryListing: [String]) -> GetDirectoryListingIntentResponse {
        let intentResponse = GetDirectoryListingIntentResponse(code: .success, userActivity: nil)
        intentResponse.directoryListing = directoryListing
        return intentResponse
    }
}
