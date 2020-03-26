//
//  LegacyCredentials.swift
//  ownCloud
//
//  Created by Michael Neuwert on 24.03.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
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

import Foundation

@objc(OCCredentialsDto)
class OCCredentialsDto : NSObject, NSCoding {
	
	enum AuthenticationMethod : Int, RawRepresentable {
		case unknown = 0
		case none = 1
		case basicHttpAuth = 2
		case bearerToken = 3
		case samlWebSSO = 4
	}
	
	var userId: String?
	var baseURL: String?
	var userName: String?
	var accessToken: String?
	var authenticationMethod: AuthenticationMethod = .unknown

	//optionals credentials used with oauth2
	var refreshToken: String?
	var expiresIn: String?
	var tokenType: String?

	var userDisplayName: String?
	
	func encode(with coder: NSCoder) {
		coder.encode(self.userId, forKey: "userId")
		coder.encode(self.baseURL, forKey: "baseURL")
		coder.encode(self.userName, forKey: "userName")
		coder.encode(self.accessToken, forKey: "accessToken")
		coder.encode(self.refreshToken, forKey: "refreshToken")
		coder.encode(self.expiresIn, forKey: "expiresIn")
		coder.encode(self.tokenType, forKey: "tokenType")
		coder.encode(self.userDisplayName, forKey: "userDisplayName")
		coder.encode(self.authenticationMethod, forKey: "authenticationMethod")
	}
	
	required init?(coder: NSCoder) {
		self.userId = coder.decodeObject(forKey: "userId") as? String
		self.baseURL = coder.decodeObject(forKey: "baseURL") as? String
		self.userName = coder.decodeObject(forKey: "userName") as? String
		self.accessToken = coder.decodeObject(forKey: "accessToken") as? String
		self.refreshToken = coder.decodeObject(forKey: "refreshToken") as? String
		self.expiresIn = coder.decodeObject(forKey: "expiresIn") as? String
		self.tokenType = coder.decodeObject(forKey: "tokenType") as? String
		self.userDisplayName = coder.decodeObject(forKey: "userDisplayName") as? String
		
		let authMethodValue = coder.decodeInteger(forKey: "authenticationMethod")
		if  let authMethod = AuthenticationMethod(rawValue: authMethodValue) {
			self.authenticationMethod = authMethod
		}
	}
}
