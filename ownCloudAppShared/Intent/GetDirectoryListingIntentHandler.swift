//
//  GetDirectoryIntentHandler.swift
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

	public func resolvePath(for intent: GetDirectoryListingIntent, with completion: @escaping (INStringResolutionResult) -> Void) {

		if let path = intent.path {
			completion(INStringResolutionResult.success(with: path))
		} else {
			completion(INStringResolutionResult.needsValue())
		}

	}

	public func provideAccountOptions(for intent: GetDirectoryListingIntent, with completion: @escaping ([Account]?, Error?) -> Void) {
		completion(OCBookmarkManager.shared.accountList, nil)
	}

	public func resolveAccount(for intent: GetDirectoryListingIntent, with completion: @escaping (AccountResolutionResult) -> Void) {
		if let account = intent.account {
			completion(AccountResolutionResult.success(with: account))
		} else {
			completion(AccountResolutionResult.needsValue())
		}
	}

	public func resolveSortType(for intent: GetDirectoryListingIntent, with completion: @escaping (SortingTypeResolutionResult) -> Void) {
		completion(SortingTypeResolutionResult.success(with: intent.sortType))
	}

	public func resolveSortDirection(for intent: GetDirectoryListingIntent, with completion: @escaping (SortingDirectionResolutionResult) -> Void) {
		completion(SortingDirectionResolutionResult.success(with: intent.sortDirection))
	}

	@available(iOS 12.0, *)
	public func handle(intent: GetDirectoryListingIntent, completion: @escaping (GetDirectoryListingIntentResponse) -> Void) {

		if AppLockHelper().isPassCodeEnabled {
			completion(GetDirectoryListingIntentResponse(code: .authenticationRequired, userActivity: nil))
		} else {
			if let path = intent.path, let uuid = intent.account?.uuid {
				let accountBookmark = OCBookmarkManager.shared.bookmark(for: uuid)

				if let bookmark = accountBookmark {
					OCCoreManager.shared.requestCore(for: bookmark, setup: nil, completionHandler: { (core, error) in
						if error == nil {
							self.core = core
							let targetDirectoryQuery = OCQuery(forPath: path)
							targetDirectoryQuery.delegate = self

							if targetDirectoryQuery.sortComparator == nil {
								let sort = SortMethod(rawValue: (intent.sortType.rawValue - 1)) ?? SortMethod.alphabetically

								targetDirectoryQuery.sortComparator = sort.comparator(direction: SortDirection(rawValue: (intent.sortDirection.rawValue - 1)) ?? SortDirection.ascendant)
							}
							core?.start(targetDirectoryQuery)
						} else {
							self.completion?(GetDirectoryListingIntentResponse(code: .failure, userActivity: nil))
						}
					})
				} else {
					completion(GetDirectoryListingIntentResponse(code: .accountFailure, userActivity: nil))
				}
			}

			self.completion = completion
		}
	}

	public func queryHasChangesAvailable(_ query: OCQuery) {
		if query.state == .targetRemoved {
			self.completion?(GetDirectoryListingIntentResponse(code: .pathFailure, userActivity: nil))
			self.completion = nil
		} else if query.state == .idle {
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
