//
//  OCBookmark+Extension.swift
//  ownCloud
//
//  Created by Felix Schwarz on 14.04.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2018, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit
import ownCloudSDK
import ownCloudApp

public extension OCBookmarkUserInfoKey {
	static var scanForAuthenticationMethodsRequired : OCBookmarkUserInfoKey { OCBookmarkUserInfoKey(rawValue: "OCBookmarkScanForAuthenticationMethodsRequired") }
}

public extension OCBookmark {
	var isTokenBased : Bool? {
		if let authenticationMethodIdentifier = self.authenticationMethodIdentifier, let authenticationMethodClass = OCAuthenticationMethod.registeredAuthenticationMethod(forIdentifier: authenticationMethodIdentifier) {
			return authenticationMethodClass.type == .token
		}

		return nil
	}

	var scanForAuthenticationMethodsRequired : Bool? {
		get {
			return self.userInfo.object(forKey: OCBookmarkUserInfoKey.scanForAuthenticationMethodsRequired ) as? Bool
		}

		set {
			self.userInfo[OCBookmarkUserInfoKey.scanForAuthenticationMethodsRequired] = newValue
		}
	}
}
