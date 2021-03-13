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
import ownCloudAppShared

@available(iOS 13.0, *)
typealias GetDirectoryListingCompletionHandler = (GetDirectoryListingIntentResponse) -> Void

@available(iOS 13.0, *)
public class GetDirectoryListingIntentHandler: NSObject, GetDirectoryListingIntentHandling, OCQueryDelegate, OCCoreDelegate {
	weak var core : OCCore?
	var completionHandler : GetDirectoryListingCompletionHandler?

	func complete(with response: GetDirectoryListingIntentResponse) {
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

	func resolvePath(for intent: GetDirectoryListingIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		if let path = intent.path {
			completion(INStringResolutionResult.success(with: path))
		} else {
			completion(INStringResolutionResult.needsValue())
		}
	}

	func provideAccountOptions(for intent: GetDirectoryListingIntent, with completion: @escaping ([Account]?, Error?) -> Void) {
		completion(OCBookmarkManager.shared.accountList, nil)
	}

	@available(iOSApplicationExtension 14.0, *)
	func provideAccountOptionsCollection(for intent: GetDirectoryListingIntent, with completion: @escaping (INObjectCollection<Account>?, Error?) -> Void) {
		completion(INObjectCollection(items: OCBookmarkManager.shared.accountList), nil)
	}

	func resolveAccount(for intent: GetDirectoryListingIntent, with completion: @escaping (AccountResolutionResult) -> Void) {
		if let account = intent.account {
			completion(AccountResolutionResult.success(with: account))
		} else {
			completion(AccountResolutionResult.needsValue())
		}
	}

	func resolveSortType(for intent: GetDirectoryListingIntent, with completion: @escaping (SortingTypeResolutionResult) -> Void) {
		completion(SortingTypeResolutionResult.success(with: intent.sortType))
	}

	func resolveSortDirection(for intent: GetDirectoryListingIntent, with completion: @escaping (SortingDirectionResolutionResult) -> Void) {
		completion(SortingDirectionResolutionResult.success(with: intent.sortDirection))
	}

	func handle(intent: GetDirectoryListingIntent, completion: @escaping (GetDirectoryListingIntentResponse) -> Void) {

		guard IntentSettings.shared.isEnabled else {
			completion(GetDirectoryListingIntentResponse(code: .disabled, userActivity: nil))
			return
		}

		guard !AppLockManager.isPassCodeEnabled else {
			completion(GetDirectoryListingIntentResponse(code: .authenticationRequired, userActivity: nil))
			return
		}

		guard let path = intent.path?.pathRepresentation, let uuid = intent.account?.uuid else {
			completion(GetDirectoryListingIntentResponse(code: .failure, userActivity: nil))
			return
		}

		guard let bookmark = OCBookmarkManager.shared.bookmark(for: uuid) else {
			completion(GetDirectoryListingIntentResponse(code: .accountFailure, userActivity: nil))
			return
		}

		guard IntentSettings.shared.isLicensedFor(bookmark: bookmark) else {
			completion(GetDirectoryListingIntentResponse(code: .unlicensed, userActivity: nil))
			return
		}

		completionHandler = completion

		OCCoreManager.shared.requestCore(for: bookmark, setup: { (core, error) in
			core?.delegate = self
		}, completionHandler: { (core, error) in
			self.core = core

			if error == nil {
				let targetDirectoryQuery = OCQuery(forPath: path)
				targetDirectoryQuery.delegate = self

				if targetDirectoryQuery.sortComparator == nil {
					let sort = SortMethod(rawValue: (intent.sortType.rawValue - 1)) ?? SortMethod.alphabetically

					targetDirectoryQuery.sortComparator = sort.comparator(direction: SortDirection(rawValue: (intent.sortDirection.rawValue - 1)) ?? SortDirection.ascendant)
				}
				core?.start(targetDirectoryQuery)
			} else {
				self.complete(with: GetDirectoryListingIntentResponse(code: .failure, userActivity: nil))
			}
		})
	}

	public func queryHasChangesAvailable(_ query: OCQuery) {
		if query.state == .targetRemoved {
			self.complete(with: GetDirectoryListingIntentResponse(code: .pathFailure, userActivity: nil))
		} else if query.state == .idle {
			var directoryListing : [String] = []
			if let results = query.queryResults {
				directoryListing = results.compactMap { return $0.path }
			}

			self.complete(with: GetDirectoryListingIntentResponse.success(directoryListing: directoryListing))
		}
	}

	public func query(_ query: OCQuery, failedWithError error: Error) {
		self.complete(with: GetDirectoryListingIntentResponse(code: .failure, userActivity: nil))
	}

	public func core(_ core: OCCore, handleError error: Error?, issue: OCIssue?) {
		if issue?.authenticationError != nil {
			self.complete(with: GetDirectoryListingIntentResponse(code: .authenticationFailed, userActivity: nil))
		} else if let error = error, error.isAuthenticationError {
			self.complete(with: GetDirectoryListingIntentResponse(code: .authenticationFailed, userActivity: nil))
		}
	}
}

@available(iOS 13.0, *)
extension GetDirectoryListingIntentResponse {
	public static func success(directoryListing: [String]) -> GetDirectoryListingIntentResponse {
		let intentResponse = GetDirectoryListingIntentResponse(code: .success, userActivity: nil)
		intentResponse.directoryListing = directoryListing
		return intentResponse
	}
}
