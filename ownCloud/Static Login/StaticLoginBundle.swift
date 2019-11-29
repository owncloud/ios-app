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
						if let profile = profile as? NSDictionary {
							let staticloginProfile = StaticLoginProfile()

							if let identifier = profile["identifier"] as? String {
								staticloginProfile.identifier = identifier
							}
							if let name = profile["name"] as? String {
								staticloginProfile.name = name
							}
							if let prompt = profile["prompt"] as? String {
								staticloginProfile.prompt = prompt
							}
							if let customLogoName = profile["customLogoName"] as? String {
								staticloginProfile.customLogoName = customLogoName
							}
							if let bookmarkName = profile["bookmarkName"] as? String {
								staticloginProfile.bookmarkName = bookmarkName
							}
							if let url = profile["url"] as? String {
								staticloginProfile.url = URL(string: url)
							}
							if let allowedAuthenticationMethods = profile["allowedAuthenticationMethods"] as? NSArray {
								staticloginProfile.allowedAuthenticationMethods = allowedAuthenticationMethods as? [OCAuthenticationMethodIdentifier]
							}
							if let maxBookmarkCount = profile["maxBookmarkCount"] as? Int {
								staticloginProfile.maxBookmarkCount = maxBookmarkCount
							}

							return staticloginProfile
						}

						return nil
						} as! [StaticLoginProfile]
				}
			}
		}

		return bundle
	}
}
