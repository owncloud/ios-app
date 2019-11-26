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

	var loginThemeStyleID : ThemeStyleIdentifier?

	var profiles : [StaticLoginProfile] = []

	static var demoBundle : StaticLoginBundle {
		let bundle = StaticLoginBundle()

		if let path = Bundle.main.path(forResource: "Branding", ofType: "plist") {
			if let themingValues = NSDictionary(contentsOfFile: path) {
				if let bundleValues = themingValues["Bundle"] as? NSDictionary, let organizationLogoName = bundleValues["organizationLogoName"] as? String, let organizationBackgroundName = bundleValues["organizationBackgroundName"] as? String, let organizationName = bundleValues["organizationName"] as? String {
					bundle.organizationName = organizationName
					bundle.organizationLogoName = organizationLogoName
					bundle.organizationBackgroundName = organizationBackgroundName
				}

				if let profileValues = themingValues["Profiles"] as? NSArray {
					bundle.profiles = profileValues.map { (profile) -> StaticLoginProfile? in
						if let profile = profile as? NSDictionary, let identifier = profile["identifier"] as? String, let name = profile["name"] as? String, let prompt = profile["prompt"] as? String, let customLogoName = profile["customLogoName"] as? String, let bookmarkName = profile["bookmarkName"] as? String, let url = profile["url"] as? String, let allowedAuthenticationMethods = profile["allowedAuthenticationMethods"] as? NSArray {
							let staticloginProfile = StaticLoginProfile()
							staticloginProfile.identifier = identifier
							staticloginProfile.name = name
							staticloginProfile.prompt = prompt
							staticloginProfile.customLogoName = customLogoName
							staticloginProfile.bookmarkName = bookmarkName
							staticloginProfile.url = URL(string: url)

							let foo = allowedAuthenticationMethods.map { (authenticationMethodTypeIdentifier) -> OCAuthenticationMethodType? in
								if let authenticationMethodTypeIdentifier = authenticationMethodTypeIdentifier as? String {
									let authenticationMethod = OCAuthenticationMethodIdentifier(rawValue: authenticationMethodTypeIdentifier)
									return OCAuthenticationMethod().authenticationMethodTypeForIdentifier(authenticationMethod)
								}
								return nil
							}
							print("foo \(foo)")

							return staticloginProfile
						}

						return nil
						} as! [StaticLoginProfile]
				}
			}
		}

/*
		let salesProfile = StaticLoginProfile()
		let publicRelationsProfile = StaticLoginProfile()


		bundle.loginThemeStyleID = "com.owncloud.dark"

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
*/
		return bundle
	}
}
