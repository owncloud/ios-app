//
//  ThemeStyle+DefaultStyles.swift
//  ownCloud
//
//  Created by Felix Schwarz on 29.10.18.
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

// MARK: - ownCloud brand colors
extension UIColor {
	static var ownCloudLightColor : UIColor { return UIColor(hex: 0x468CC8) }
	static var ownCloudDarkColor : UIColor { return UIColor(hex: 0x1D293B) }
}

extension ThemeStyle {
	static public var ownCloudLight : ThemeStyle {
		return (ThemeStyle(identifier: "com.owncloud.light", darkStyleIdentifier: "com.owncloud.dark", localizedName: "Light".localized, lightColor: .ownCloudLightColor, darkColor: .ownCloudDarkColor, themeStyle: .light))
	}

	static public var ownCloudDark : ThemeStyle {
		return (ThemeStyle(identifier: "com.owncloud.dark", localizedName: "Dark".localized, lightColor: .ownCloudLightColor, darkColor: .ownCloudDarkColor, themeStyle: .dark))
	}

	static public var ownCloudClassic : ThemeStyle {
		return (ThemeStyle(identifier: "com.owncloud.classic", darkStyleIdentifier: "com.owncloud.dark", localizedName: "Classic".localized, lightColor: .ownCloudLightColor, darkColor: .ownCloudDarkColor, themeStyle: .contrast))
	}
}
