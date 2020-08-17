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
import ownCloudAppShared

@available(iOS 13.0, *)
public class GetAccountsIntentHandler: NSObject, GetAccountsIntentHandling {

	public func handle(intent: GetAccountsIntent, completion: @escaping (GetAccountsIntentResponse) -> Void) {

		guard IntentSettings.shared.isEnabled else {
			completion(GetAccountsIntentResponse(code: .disabled, userActivity: nil))
			return
		}

		// if enabled, but not a valid license
		//completion(GetAccountIntentResponse(code: .unlicensed, userActivity: nil))

		guard !AppLockManager.isPassCodeEnabled else {
			completion(GetAccountsIntentResponse(code: .authenticationRequired, userActivity: nil))
			return
		}

		completion(GetAccountsIntentResponse.success(accountList: OCBookmarkManager.shared.accountList))
	}

	public func confirm(intent: GetAccountsIntent, completion: @escaping (GetAccountsIntentResponse) -> Void) {
        completion(GetAccountsIntentResponse(code: .ready, userActivity: nil))
	}
}

@available(iOS 13.0, *)
extension GetAccountsIntentResponse {

    public static func success(accountList: [Account]) -> GetAccountsIntentResponse {
        let intentResponse = GetAccountsIntentResponse(code: .success, userActivity: nil)
        intentResponse.accountList = accountList
        return intentResponse
    }

}
