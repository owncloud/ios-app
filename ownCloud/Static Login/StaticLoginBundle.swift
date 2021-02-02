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
import ownCloudApp
import ownCloudAppShared

class StaticLoginBundle: NSObject {
	var organizationLogoImage : UIImage?
	var organizationBackgroundImage : UIImage?
	var organizationName : String?

	var loginThemeStyleID : ThemeStyleIdentifier?

	var profiles : [StaticLoginProfile] = []

	static var defaultBundle : StaticLoginBundle {
		let bundle = StaticLoginBundle()
		let branding = Branding.shared

		if branding.isBranded {
			if let organizationName = branding.organizationName {
				bundle.organizationName = organizationName
			}
			if let logoImage = branding.brandedImageNamed(.loginLogo) {
				bundle.organizationLogoImage = logoImage
			}
			if let backgroundImage = branding.brandedImageNamed(.loginBackground) {
				bundle.organizationBackgroundImage = backgroundImage
			}

			if let profileDefinitions = branding.profileDefinitions {
				let profiles = profileDefinitions.map { (profile) -> StaticLoginProfile? in
					return StaticLoginProfile(from: profile)
				} as? [StaticLoginProfile]

			       bundle.profiles = profiles!
			}
		}

		return bundle
	}
}
