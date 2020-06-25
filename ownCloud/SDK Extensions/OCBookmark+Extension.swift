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

extension OCBookmarkUserInfoKey {
	static var displayName : OCBookmarkUserInfoKey { OCBookmarkUserInfoKey(rawValue: "OCBookmarkDisplayName") }
	static var scanForAuthenticationMethodsRequired : OCBookmarkUserInfoKey { OCBookmarkUserInfoKey(rawValue: "OCBookmarkScanForAuthenticationMethodsRequired") }
}

extension OCBookmark {
	var userName : String? {
		if let authenticationData = self.authenticationData,
		   let authenticationMethodIdentifier = self.authenticationMethodIdentifier,
		   let authenticationMethod = OCAuthenticationMethod.registeredAuthenticationMethod(forIdentifier: authenticationMethodIdentifier),
		   let userName = authenticationMethod.userName(fromAuthenticationData: authenticationData) {
			return userName
		}

		return nil
	}

	var displayName : String? {
		get {
			return self.userInfo.object(forKey: OCBookmarkUserInfoKey.displayName ) as? String
		}

		set {
			self.userInfo[OCBookmarkUserInfoKey.displayName] = newValue
		}
	}

	var shortName: String {
		if self.name != nil {
			return self.name!
		} else {
			var userNamePrefix = ""

			if let displayName = self.displayName {
				userNamePrefix = displayName + "@"
			}

			if userNamePrefix.count == 0 {
				if let userName = self.userName {
					userNamePrefix = userName + "@"
				}
			}

			if self.originURL?.host != nil {
				return userNamePrefix + self.originURL!.host!
			} else if self.url?.host != nil {
				return userNamePrefix + self.url!.host!
			}
		}

		return "bookmark"
	}

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
