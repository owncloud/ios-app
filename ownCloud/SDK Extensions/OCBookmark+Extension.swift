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

extension OCBookmark {
	var userName : String? {
		if self.authenticationData != nil,
		   self.authenticationMethodIdentifier != nil,
		   let authenticationMethod = OCAuthenticationMethod.registeredAuthenticationMethod(forIdentifier: self.authenticationMethodIdentifier),
		   authenticationMethod.usesUserName {
		   	return authenticationMethod.userName(fromAuthenticationData: self.authenticationData)
		}

		return nil
	}

	var shortName: String {
		var userNamePrefix = ""

		if let userName = self.userName {
			userNamePrefix = userName + " @ "
		}

		if self.name != nil {
			return self.name
		} else if self.originURL?.host != nil {
			return userNamePrefix + self.originURL.host!
		} else if self.url?.host != nil {
			return userNamePrefix + self.url.host!
		}

		return "bookmark"
	}
}
