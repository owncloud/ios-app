//
//  ThemeProvider.swift
//  ownCloud
//
//  Created by Matthias Hühne on 31.07.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2019, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit

class ThemeProvider: NSObject {

	var genericColors : [String : Any]?
	var themes : [ThemeStyle] = []

	init(plist: String) {
		super.init()
		loadThemes(plist: plist)
	}

	func loadThemes(plist: String) {
		if let path = Bundle.main.path(forResource: plist, ofType: "plist") {
			if let themingValues = NSDictionary(contentsOfFile: path), let generic = themingValues["Generic"] as? [String : Any], let themes = themingValues["Themes"] as? [[String : Any]] {
				self.genericColors = generic

				if let darkBrandColor = generic["darkBrandColor"] as? String, let lightBrandColor = generic["lightBrandColor"] as? String {
					for theme in themes {
						if let identifier = theme["Identifier"] as? String, let name = theme["Name"] as? String, let style = theme["ThemeStyle"] as? String, let themeStyle = ThemeCollectionStyle(rawValue: style) {
							let newTheme = ThemeStyle(identifier: identifier, localizedName: name.localized, lightColor: UIColor.init(hex: lightBrandColor), darkColor: UIColor.init(hex: darkBrandColor), themeStyle: themeStyle)
							self.themes.append(newTheme)
						}
					}
				}
			}
		}
	}

}
