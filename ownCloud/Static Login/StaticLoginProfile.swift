//
//  StaticLoginProfile.swift
//  ownCloud
//
//  Created by Felix Schwarz on 26.11.18.
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
import ownCloudAppShared

typealias StaticLoginProfileIdentifier = String

class StaticLoginProfile: NSObject {
	static let staticLoginProfileIdentifierKey : String = "static-login-profile-identifier"

	var identifier : StaticLoginProfileIdentifier?
	var name : String?
	var promptForPasswordAuth : String?
	var promptForTokenAuth : String?
	var promptForURL : String?
	var promptForHelpURL : String?
	var helpURLButtonString : String?
	var welcome : String?
	var bookmarkName : String?
	var url : URL?
	var urlString : String?
	var helpURL : URL?
	var canConfigureURL : Bool = false
	var allowedAuthenticationMethods : [OCAuthenticationMethodIdentifier]?
	var themeStyleID : ThemeStyleIdentifier?
}
