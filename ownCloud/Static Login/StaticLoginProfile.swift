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

public typealias StaticLoginProfileIdentifier = String

public class StaticLoginProfile: NSObject {
	public static let staticLoginProfileIdentifierKey : String = "static-login-profile-identifier"

	public var identifier : StaticLoginProfileIdentifier?
	public var name : String?
	public var promptForPasswordAuth : String?
	public var promptForTokenAuth : String?
	public var welcome : String?
	public var bookmarkName : String?
	public var url : URL?
	public var allowedAuthenticationMethods : [OCAuthenticationMethodIdentifier]?
	public var themeStyleID : ThemeStyleIdentifier?
}
