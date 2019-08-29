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

public class GetAccountsIntentHandler: NSObject, GetAccountsIntentHandling {

	@available(iOS 12.0, *)
	public func handle(intent: GetAccountsIntent, completion: @escaping (GetAccountsIntentResponse) -> Void) {
		if AppLockHelper().isPassCodeEnabled {
			completion(GetAccountsIntentResponse(code: .authenticationRequired, userActivity: nil))
		} else {
			completion(GetAccountsIntentResponse.success(accountList: OCBookmarkManager.shared.accountList))
		}
	}

	@available(iOS 12.0, *)
	public func confirm(intent: GetAccountsIntent, completion: @escaping (GetAccountsIntentResponse) -> Void) {
        completion(GetAccountsIntentResponse(code: .ready, userActivity: nil))
	}
}

extension GetAccountsIntentResponse {

    @available(iOS 13.0, watchOS 6.0, *)
    public static func success(accountList: [Account]) -> GetAccountsIntentResponse {
        let intentResponse = GetAccountsIntentResponse(code: .success, userActivity: nil)
        intentResponse.accountList = accountList
        return intentResponse
    }

}
