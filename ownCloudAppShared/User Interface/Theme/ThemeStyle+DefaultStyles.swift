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
	static var ownCloudLightColor : UIColor { return UIColor(hex: 0x4E85C8) }
    static var ownCloudDarkColor : UIColor { return UIColor(hex: 0x041E42) }
    static var ownCloudWebDarkColor : UIColor { return UIColor(hex: 0x292929) }
    static var ownCloudWebDarkLabelColor : UIColor { return UIColor(hex: 0xDADCDF) }
    static var ownCloudWebDarkFolderColor : UIColor { return UIColor(red: 44, green: 101, blue: 255) }
}

extension ThemeStyle {
	static public var ownCloudLight : ThemeStyle {
		return (ThemeStyle(styleIdentifier: "com.owncloud.light", darkStyleIdentifier: "com.owncloud.dark", localizedName: "Light".localized, lightColor: .ownCloudLightColor, darkColor: .ownCloudDarkColor, themeStyle: .light))
	}

	static public var ownCloudDark : ThemeStyle {
		return (ThemeStyle(styleIdentifier: "com.owncloud.dark", localizedName: "Dark Blue".localized, lightColor: .ownCloudLightColor, darkColor: .ownCloudDarkColor, themeStyle: .dark))
	}
    
    static public var ownCloudWebDark : ThemeStyle {
        return (ThemeStyle(styleIdentifier: "com.owncloud.web.dark", darkStyleIdentifier: "com.owncloud.web.dark", localizedName: "Dark Web".localized, lightColor: .ownCloudWebDarkLabelColor, darkColor: .ownCloudWebDarkColor, themeStyle: .dark, customColors: ["Icon.folderFillColor" : UIColor.ownCloudWebDarkFolderColor.hexString(), "Fill.neutralColors.normal.foreground" : UIColor.ownCloudWebDarkColor.hexString()]))
    }
    
    static public var ownCloudDarkBlack : ThemeStyle {
        return (ThemeStyle(styleIdentifier: "com.owncloud.dark.black", darkStyleIdentifier: "com.owncloud.dark.black", localizedName: "Dark Black".localized, lightColor: .lightGray, darkColor: .black, themeStyle: .dark, customColors: ["Icon.folderFillColor" : UIColor.ownCloudWebDarkFolderColor.hexString(), "Toolbar.tintColor" : UIColor.white.hexString(), "NavigationBar.tintColor" : UIColor(white: 0.888, alpha: 1.0) .hexString(), "Fill.neutralColors.normal.foreground" : UIColor.ownCloudWebDarkColor.hexString()]))
    }
    
    static public var ownCloudClassic : ThemeStyle {
        return (ThemeStyle(styleIdentifier: "com.owncloud.classic", darkStyleIdentifier: "com.owncloud.dark", localizedName: "Classic".localized, lightColor: .ownCloudLightColor, darkColor: .ownCloudDarkColor, themeStyle: .contrast))
    }
}
