//
//  GetAccountsIntentHandler.swift
//  ownCloud
//
//  Created by Matthias Hühne on 29.09.19.
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
public class GetAccountIntentHandler: NSObject, GetAccountIntentHandling {

	public func handle(intent: GetAccountIntent, completion: @escaping (GetAccountIntentResponse) -> Void) {

		guard !AppLockHelper().isPassCodeEnabled else {
			completion(GetAccountIntentResponse(code: .authenticationRequired, userActivity: nil))
			return
		}

		guard let uuid = intent.accountUUID else {
			completion(GetAccountIntentResponse(code: .failure, userActivity: nil))
			return
		}

		guard let accountBookmark = OCBookmarkManager.shared.accountBookmark(for: uuid) else {
			completion(GetAccountIntentResponse(code: .accountFailure, userActivity: nil))
			return
		}

		completion(GetAccountIntentResponse.success(account: accountBookmark))
	}

	public func resolveAccountUUID(for intent: GetAccountIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		if let account = intent.accountUUID {
			completion(INStringResolutionResult.success(with: account))
		} else {
			completion(INStringResolutionResult.needsValue())
		}
	}

	public func confirm(intent: GetAccountIntent, completion: @escaping (GetAccountIntentResponse) -> Void) {
        completion(GetAccountIntentResponse(code: .ready, userActivity: nil))
	}
}

@available(iOS 13.0, *)
extension GetAccountIntentResponse {

    public static func success(account: Account) -> GetAccountIntentResponse {
        let intentResponse = GetAccountIntentResponse(code: .success, userActivity: nil)
        intentResponse.account = account
        return intentResponse
    }

}
