//
//  ThemeStyle.swift
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

public class ThemeStyle : NSObject {
	public var identifier: String
	public var localizedName: String

	public var lightColor: UIColor
	public var darkColor: UIColor
	public var themeStyle: ThemeCollectionStyle

	public var darkStyleIdentifier: String?

	public var customizedColorsByPath : [String:String]?

	public init(identifier idtfr: String, darkStyleIdentifier darkIdentifier: String? = nil, localizedName name: String, lightColor lColor: UIColor, darkColor dColor: UIColor, themeStyle style: ThemeCollectionStyle = .light, customizedColorsByPath customizations: [String:String]? = nil) {
		self.identifier = idtfr
		self.darkStyleIdentifier = darkIdentifier
		self.localizedName = name
		self.lightColor = lColor
		self.darkColor = dColor
		self.themeStyle = style
		self.customizedColorsByPath = customizations
	}

	public var parsedCustomizedColorsByPath : [String:UIColor]? {
		if let rawColorsByPath = customizedColorsByPath {
			var colorsByPath : [String:UIColor] = [:]

			for (keyPath, rawColor) in rawColorsByPath {
				var color : UIColor?

				if let decodedHexColor = rawColor.colorFromHex {
					color = decodedHexColor
				}

				if color != nil {
					colorsByPath[keyPath] = color
				}
			}

			return colorsByPath
		}

		return nil
	}
}

extension String {
	var colorFromHex : UIColor? {
		if self.hasPrefix("#") {
			switch self.count {
				case 7:
					// Format: #RRGGBB
					if let hexRGB = UInt(self.replacingOccurrences(of: "#", with: ""), radix: 16) {
						return UIColor(hex: hexRGB)
					}
				default: break
			}
		}

		return nil
	}
}

extension ThemeCollection {
	convenience public init(with style: ThemeStyle) {
		self.init(darkBrandColor: style.darkColor, lightBrandColor: style.lightColor, style: style.themeStyle)

		if let customizationColors = style.parsedCustomizedColorsByPath {
			for (keyPath, color) in customizationColors {
				self.setValue(color, forKeyPath: keyPath)
			}
		}
	}
}
