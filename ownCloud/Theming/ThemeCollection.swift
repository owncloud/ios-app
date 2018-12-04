//
//  ThemeCollection.swift
//  ownCloud
//
//  Created by Felix Schwarz on 10.04.18.
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

class ThemeColorPair : NSObject {
	@objc var foreground: UIColor
	@objc var background: UIColor

	init(foreground fgColor: UIColor, background bgColor: UIColor) {
		foreground = fgColor
		background = bgColor
	}
}

class ThemeColorPairCollection : NSObject {
	@objc var normal : ThemeColorPair
	@objc var highlighted : ThemeColorPair
	@objc var disabled : ThemeColorPair

	init(fromPair: ThemeColorPair) {
		normal = fromPair
		highlighted = ThemeColorPair(foreground: fromPair.foreground, background: fromPair.background.lighter(0.25))
		disabled = ThemeColorPair(foreground: fromPair.foreground, background: fromPair.background.lighter(0.25))
	}
}

class ThemeColorCollection : NSObject {
	@objc var backgroundColor : UIColor?
	@objc var labelColor : UIColor
	@objc var secondaryLabelColor : UIColor
	@objc var symbolColor : UIColor
	@objc var tintColor : UIColor?

	@objc var filledColorPairCollection : ThemeColorPairCollection

	init(backgroundColor bgColor : UIColor?, tintColor tntColor: UIColor?, labelColor lblColor : UIColor, secondaryLabelColor secLabelColor: UIColor, symbolColor symColor: UIColor, filledColorPairCollection filColorPairCollection: ThemeColorPairCollection) {
		backgroundColor = bgColor
		labelColor = lblColor
		symbolColor = symColor
		secondaryLabelColor = secLabelColor
		tintColor = tntColor
		filledColorPairCollection = filColorPairCollection
	}
}

enum ThemeCollectionStyle : String, CaseIterable {
	case dark
	case light
	case contrast

	var name : String {
		switch self {
			case .dark:	return "Dark".localized
			case .light:	return "Light".localized
			case .contrast:	return "Contrast".localized
		}
	}
}

class ThemeCollection : NSObject {
	@objc var identifier : String = UUID().uuidString

	// MARK: - Brand colors
	@objc var darkBrandColor: UIColor
	@objc var lightBrandColor: UIColor

	// MARK: - Brand color collection
	@objc var darkBrandColors : ThemeColorCollection
	@objc var lightBrandColors : ThemeColorCollection

	// MARK: - Button / Fill color collections
	@objc var approvalColors : ThemeColorPairCollection
	@objc var neutralColors : ThemeColorPairCollection
	@objc var destructiveColors : ThemeColorPairCollection

	// MARK: - Label colors
	@objc var informativeColor: UIColor
	@objc var successColor: UIColor
	@objc var warningColor: UIColor
	@objc var errorColor: UIColor

	@objc var tintColor : UIColor

	// MARK: - Table views
	@objc var tableBackgroundColor : UIColor
	@objc var tableGroupBackgroundColor : UIColor
	@objc var tableSeparatorColor : UIColor?
	@objc var tableRowColors : ThemeColorCollection
	@objc var tableRowHighlightColors : ThemeColorCollection

	// MARK: - Bars
	@objc var navigationBarColors : ThemeColorCollection
	@objc var toolbarColors : ThemeColorCollection
	@objc var statusBarStyle : UIStatusBarStyle
	@objc var barStyle : UIBarStyle

	// MARK: - Icon colors
	@objc var iconColors : [String:String]

	// MARK: - Default Collection
	static var defaultCollection : ThemeCollection = {
		let collection = ThemeCollection()

		/*
		Log.log("%@", collection.value(forKeyPath: "tintColor") as! CVarArg)
		Log.log("%@", collection.value(forKeyPath: "toolBarColorCollection.filledColorPairCollection.normal.background") as! CVarArg)
		Log.log("%@", collection.value(forKeyPath: "toolBarColorCollection.filledColorPairCollection.normal.backgrounds") as! CVarArg)
		*/

		return (collection)
	}()

	static var darkCollection : ThemeCollection = {
		let collection = ThemeCollection()

		return (collection)
	}()

	init(darkBrandColor darkColor: UIColor, lightBrandColor lightColor: UIColor, style: ThemeCollectionStyle = .dark) {
		var logoFillColor : UIColor?

		self.darkBrandColor = darkColor
		self.lightBrandColor = lightColor

		self.darkBrandColors = ThemeColorCollection(
			backgroundColor: darkColor,
			tintColor: lightColor.lighter(0.2),
			labelColor: UIColor.white,
			secondaryLabelColor: UIColor.lightGray,
			symbolColor: UIColor.white,
			filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: darkColor))
		)

		self.lightBrandColors = ThemeColorCollection(
			backgroundColor: lightColor,
			tintColor: UIColor.white,
			labelColor: UIColor.white,
			secondaryLabelColor: UIColor.lightGray,
			symbolColor: UIColor.white,
			filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: lightBrandColor))
		)

		self.informativeColor = UIColor.darkGray
		self.successColor = UIColor(hex: 0x27AE60)
		self.warningColor = UIColor(hex: 0xF2994A)
		self.errorColor = UIColor(hex: 0xEB5757)

		self.approvalColors = ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: UIColor(hex: 0x1AC763)))
		self.neutralColors = lightBrandColors.filledColorPairCollection
		self.destructiveColors = ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: UIColor.red))

		self.tintColor = self.lightBrandColor

		// Table view
		self.tableBackgroundColor = UIColor.white
		self.tableGroupBackgroundColor = UIColor.groupTableViewBackground
		self.tableSeparatorColor = nil

		self.tableRowColors = ThemeColorCollection(
			backgroundColor: tableBackgroundColor,
			tintColor: nil,
			labelColor: UIColor.black,
			secondaryLabelColor: UIColor.gray,
			symbolColor: darkColor,
			filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: lightBrandColor))
		)

		self.tableRowHighlightColors = ThemeColorCollection(
			backgroundColor: nil,
			tintColor: nil,
			labelColor: UIColor.black,
			secondaryLabelColor: UIColor.gray,
			symbolColor: darkColor,
			filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: lightBrandColor))
		)

		// Styles
		switch style {
			case .dark:
				// Bars
				self.navigationBarColors = self.darkBrandColors
				self.toolbarColors = self.darkBrandColors

				// Table view
				self.tableBackgroundColor = navigationBarColors.backgroundColor!.darker(0.1)
				self.tableGroupBackgroundColor = navigationBarColors.backgroundColor!.darker(0.3)
				self.tableSeparatorColor = UIColor.darkGray
				self.tableRowColors = ThemeColorCollection(
					backgroundColor: tableBackgroundColor,
					tintColor: navigationBarColors.tintColor,
					labelColor: navigationBarColors.labelColor,
					secondaryLabelColor: navigationBarColors.secondaryLabelColor,
					symbolColor: lightColor,
					filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: lightBrandColor))
				)

				self.tableRowHighlightColors = ThemeColorCollection(
					backgroundColor: lightColor.darker(0.2),
					tintColor: UIColor.white,
					labelColor: UIColor.white,
					secondaryLabelColor: UIColor.white,
					symbolColor: darkColor,
					filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: lightBrandColor))
				)

				// Bar styles
				self.statusBarStyle = .lightContent
				self.barStyle = .black

				// Logo fill color
				logoFillColor = UIColor.white

			case .light:
				// Bars
				self.navigationBarColors = ThemeColorCollection(
					backgroundColor: UIColor.white.darker(0.05),
					tintColor: nil,
					labelColor: UIColor.black,
					secondaryLabelColor: UIColor.gray,
					symbolColor: darkColor,
					filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: lightBrandColor))
				)

				self.toolbarColors = self.navigationBarColors

				// Bar styles
				self.statusBarStyle = .default
				self.barStyle = .default

				// Logo fill color
				logoFillColor = UIColor.lightGray

			case .contrast:
				// Bars
				self.navigationBarColors = self.darkBrandColors
				self.toolbarColors = self.darkBrandColors

				// Bar styles
				self.statusBarStyle = .lightContent
				self.barStyle = .black

				// Logo fill color
				logoFillColor = UIColor.lightGray
		}

		let iconSymbolColor = self.tableRowColors.symbolColor.hexString()

		self.iconColors = [
			"folderFillColor" : iconSymbolColor,
			"fileFillColor" : iconSymbolColor,
			"logoFillColor" : logoFillColor?.hexString() ?? "#ffffff",
			"iconFillColor" : tableRowColors.tintColor?.hexString() ?? iconSymbolColor,
			"symbolFillColor" : iconSymbolColor
		]
	}

	convenience override init() {
		self.init(darkBrandColor: UIColor(hex: 0x1D293B), lightBrandColor: UIColor(hex: 0x468CC8))
	}
}
