//
//  StaticLoginBundle.swift
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

class StaticLoginBundle: NSObject {
	var organizationLogoName : String?
	var organizationBackgroundName : String?
	var organizationName : String?

	var profiles : [StaticLoginProfile] = []

	static var demoBundle : StaticLoginBundle {
		let bundle = StaticLoginBundle()

		let salesProfile = StaticLoginProfile()
		let publicRelationsProfile = StaticLoginProfile()

		bundle.organizationName = "ownCloud"
		bundle.organizationLogoName = "owncloud-logo"
		bundle.organizationBackgroundName = "brand-background.jpg"

		// Sales profile
		salesProfile.identifier = "sales"
		salesProfile.name = "💶 Sales"
		salesProfile.prompt = "Enter your Sales username and password:"

		salesProfile.customLogoName = "sales"
		salesProfile.bookmarkName = "💶 Sales Files"

		salesProfile.url = URL(string: "https://demo.owncloud.org/")
		salesProfile.allowedAuthenticationMethods = [ .basicAuth ]
		salesProfile.maxBookmarkCount = 1

		salesProfile.themeStyleID = "com.owncloud.light"

		// Customer profile
		publicRelationsProfile.identifier = "public-relations"
		publicRelationsProfile.name = "🌍 Public Relations Group"
		publicRelationsProfile.prompt = "Please press \"Continue\" and enter your PR department login and password."

		publicRelationsProfile.customLogoName = "public-relations"
		publicRelationsProfile.bookmarkName = "🌍 Public Relations"

		publicRelationsProfile.url = URL(string: "https://owncloud-io.lan/")
		publicRelationsProfile.allowedAuthenticationMethods = [ .oAuth2 ]
		publicRelationsProfile.maxBookmarkCount = 1

		publicRelationsProfile.themeStyleID = "com.owncloud.dark"

		bundle.profiles = [ salesProfile, publicRelationsProfile ]

		return bundle
	}
}
