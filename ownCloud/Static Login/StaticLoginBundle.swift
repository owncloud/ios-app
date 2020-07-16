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
import ownCloudAppShared

class StaticLoginBundle: NSObject {
	var organizationLogoImage : UIImage?
	var organizationBackgroundImage : UIImage?
	var organizationName : String?

	var loginThemeStyleID : ThemeStyleIdentifier?

	var profiles : [StaticLoginProfile] = []

	static var defaultBundle : StaticLoginBundle {
		let bundle = StaticLoginBundle()

		if let bundleValues = VendorServices.shared.brandingProperties {
			if let logoImage = UIImage(named: "Branding-logo.png"), let backgroundImage = UIImage(named: "Branding-background.png"), let organizationName = bundleValues["organizationName"] as? String {
				bundle.organizationName = organizationName
				bundle.organizationLogoImage = logoImage
				bundle.organizationBackgroundImage = backgroundImage
			}

			if let profileValues = bundleValues["Profiles"] as? NSArray {
				let profiles = profileValues.map { (profile) -> StaticLoginProfile? in
					if let profile = profile as? NSDictionary {
						let staticloginProfile = StaticLoginProfile()

						if let identifier = profile["identifier"] as? String {
							staticloginProfile.identifier = identifier
						}
						if let name = profile["name"] as? String {
							staticloginProfile.name = name
						}
						if let prompt = profile["promptForTokenAuth"] as? String {
							staticloginProfile.promptForTokenAuth = prompt
						}
						if let promptForPasswordAuth = profile["promptForPasswordAuth"] as? String {
							staticloginProfile.promptForPasswordAuth = promptForPasswordAuth
						}
						if let promptForTokenAuth = profile["promptForTokenAuth"] as? String {
							staticloginProfile.promptForTokenAuth = promptForTokenAuth
						}
						if let welcome = profile["welcome"] as? String {
							staticloginProfile.welcome = welcome
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

						return staticloginProfile
					}

					return nil
				} as? [StaticLoginProfile]

			       bundle.profiles = profiles!
			}
		}

		return bundle
	}
}
