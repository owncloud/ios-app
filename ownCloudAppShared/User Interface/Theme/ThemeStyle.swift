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

public typealias ThemeStyleIdentifier = String

public class ThemeStyle : NSObject {
	public var identifier: ThemeStyleIdentifier
	public var localizedName: String

	public var lightColor: UIColor
	public var darkColor: UIColor
	public var themeStyle: ThemeCollectionStyle

	public var darkStyleIdentifier: String?

	public var customColors : NSDictionary?
	public var genericColors : NSDictionary?
	public var styles : NSDictionary?

	public var cssRecordStrings: [String]?

	public init(styleIdentifier: String, darkStyleIdentifier darkIdentifier: String? = nil, localizedName name: String, lightColor lColor: UIColor, darkColor dColor: UIColor, themeStyle style: ThemeCollectionStyle = .light, customColors: NSDictionary? = nil, genericColors: NSDictionary? = nil, interfaceStyles: NSDictionary? = nil, cssRecordStrings: [String]? = nil) {
		self.identifier = styleIdentifier
		self.darkStyleIdentifier = darkIdentifier
		self.localizedName = name
		self.lightColor = lColor
		self.darkColor = dColor
		self.themeStyle = style
		self.customColors = customColors
		self.genericColors = genericColors
		self.styles = interfaceStyles
		self.cssRecordStrings = cssRecordStrings
	}
}

public extension String {
	var colorFromHex : UIColor? {
		if self.hasPrefix("#"), self.count == 7 {
			// Format: #RRGGBB
			if let hexRGB = UInt(self.replacingOccurrences(of: "#", with: ""), radix: 16) {
				return UIColor(hex: hexRGB)
			}
		} else if self.count == 6 {
			// Format: RRGGBB
			if let hexRGB = UInt(self, radix: 16) {
				return UIColor(hex: hexRGB)
			}
		}

		return nil
	}
}

public extension ThemeCSSRecord {
	static func from(_ cssRecordStrings: [String]) -> [ThemeCSSRecord]? {
		// Format: selector1.selector2.property: value
		var records: [ThemeCSSRecord] = []

		let whitespace = CharacterSet.whitespaces

		for recordString in cssRecordStrings {
			let recordString = recordString as NSString
			let separatorIndex = recordString.range(of: ":").location

			if separatorIndex != -1 {
				let selectionAndPropertyPart = recordString.substring(to: separatorIndex)
				let valuePart = recordString.substring(from: separatorIndex+1).trimmingCharacters(in: whitespace)

				if let record = ThemeCSSRecord(with: selectionAndPropertyPart, value: valuePart) {
					records.append(record)
				}
			}
		}

		return records.count > 0 ? records : nil
	}
}

public extension ThemeCollection {
	convenience init(with style: ThemeStyle) {
		self.init(darkBrandColor: style.darkColor, lightBrandColor: style.lightColor, style: style.themeStyle, customColors: style.customColors, genericColors: style.genericColors, interfaceStyles: style.styles)

		if let cssRecordStrings = style.cssRecordStrings, let records = ThemeCSSRecord.from(cssRecordStrings) {
			css.add(records: records)
		}
	}
}
