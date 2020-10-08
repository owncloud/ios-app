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
			if let organizationName = bundleValues["organizationName"] as? String {
				bundle.organizationName = organizationName
			}
			if let logoImage = UIImage(named: "branding-login-logo.png") {
				bundle.organizationLogoImage = logoImage
			}
			if let backgroundImage = UIImage(named: "branding-login-background.png") {
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
						if let promptForURL = profile["promptForURL"] as? String {
							staticloginProfile.promptForURL = promptForURL
						}
						if let promptForHelpURL = profile["promptForHelpURL"] as? String {
							staticloginProfile.promptForHelpURL = promptForHelpURL
						}
						if let helpURLButtonString = profile["helpURLButtonString"] as? String {
							staticloginProfile.helpURLButtonString = helpURLButtonString
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
						if let helpURL = profile["helpURL"] as? String {
							staticloginProfile.helpURL = URL(string: helpURL)
						}
						if let canConfigureURL = profile["canConfigureURL"] as? Bool {
							staticloginProfile.canConfigureURL = canConfigureURL
						}
						if let allowedAuthenticationMethods = profile["allowedAuthenticationMethods"] as? NSArray {
							staticloginProfile.allowedAuthenticationMethods = allowedAuthenticationMethods as? [OCAuthenticationMethodIdentifier]
						}
						if let allowedHosts = profile["allowedHosts"] as? NSArray {
							staticloginProfile.allowedHosts = allowedHosts as? [String]
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
