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

enum ThemeCollectionStyle {
	case dark
	case light
	case contrast
}

class ThemeCollection : NSObject {
	// MARK: - Brand colors
	@objc var darkBrandColor: UIColor
	@objc var lightBrandColor: UIColor

	// MARK: - Brand color collection
	@objc var darkBrandColorCollection : ThemeColorCollection
	@objc var lightBrandColorCollection : ThemeColorCollection

	// MARK: - Button / Fill color collections
	@objc var approvalCollection : ThemeColorPairCollection
	@objc var neutralCollection : ThemeColorPairCollection
	@objc var destructiveCollection : ThemeColorPairCollection

	// MARK: - Label colors
	@objc var informativeColor: UIColor
	@objc var successColor: UIColor
	@objc var warningColor: UIColor
	@objc var errorColor: UIColor

	@objc var tintColor : UIColor

	// MARK: - Table views
	@objc var tableBackgroundColor : UIColor
	@objc var tableRowSeparatorColor : UIColor?
	@objc var tableRowColorBarCollection : ThemeColorCollection

	// MARK: - Bars
	@objc var navigationBarColorCollection : ThemeColorCollection
	@objc var toolBarColorCollection : ThemeColorCollection
	@objc var statusBarStyle : UIStatusBarStyle

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
		self.darkBrandColor = darkColor
		self.lightBrandColor = lightColor

		self.darkBrandColorCollection = ThemeColorCollection(
			backgroundColor: darkColor,
			tintColor: lightColor.lighter(0.2),
			labelColor: UIColor.white,
			secondaryLabelColor: UIColor.lightGray,
			symbolColor: UIColor.white,
			filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: darkColor))
		)

		self.lightBrandColorCollection = ThemeColorCollection(
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

		self.approvalCollection = ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: UIColor(hex: 0x1AC763)))
		self.neutralCollection = lightBrandColorCollection.filledColorPairCollection
		self.destructiveCollection = ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: UIColor.red))

		self.tintColor = self.lightBrandColor

		switch style {
			case .dark:
				// Bars
				self.navigationBarColorCollection = self.darkBrandColorCollection
				self.toolBarColorCollection = self.darkBrandColorCollection

				// Table view
				self.tableBackgroundColor = navigationBarColorCollection.backgroundColor!.darker(0.1)
				self.tableRowSeparatorColor = UIColor.black
				self.tableRowColorBarCollection = ThemeColorCollection(
					backgroundColor: tableBackgroundColor,
					tintColor: navigationBarColorCollection.tintColor,
					labelColor: navigationBarColorCollection.labelColor,
					secondaryLabelColor: navigationBarColorCollection.secondaryLabelColor,
					symbolColor: lightColor,
					filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: lightBrandColor))
				)

				// Status Bar
				self.statusBarStyle = .lightContent

			case .light:
				// Bars
				self.navigationBarColorCollection = ThemeColorCollection(
					backgroundColor: nil,
					tintColor: nil,
					labelColor: UIColor.black,
					secondaryLabelColor: UIColor.gray,
					symbolColor: darkColor,
					filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: lightBrandColor))
				)

				self.toolBarColorCollection = self.navigationBarColorCollection

				// Table view
				self.tableBackgroundColor = UIColor.white
				self.tableRowSeparatorColor = nil
				self.tableRowColorBarCollection = ThemeColorCollection(
					backgroundColor: tableBackgroundColor,
					tintColor: nil,
					labelColor: UIColor.black,
					secondaryLabelColor: UIColor.gray,
					symbolColor: darkColor,
					filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: lightBrandColor))
				)

				// Status Bar
				self.statusBarStyle = .default

			case .contrast:
				// Bars
				self.navigationBarColorCollection = self.darkBrandColorCollection
				self.toolBarColorCollection = self.darkBrandColorCollection

				// Table view
				self.tableBackgroundColor = UIColor.white
				self.tableRowSeparatorColor = nil
				self.tableRowColorBarCollection = ThemeColorCollection(
					backgroundColor: tableBackgroundColor,
					tintColor: nil,
					labelColor: UIColor.black,
					secondaryLabelColor: UIColor.gray,
					symbolColor: darkBrandColor,
					filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: lightBrandColor))
				)

				// Status Bar
				self.statusBarStyle = .lightContent

		}
	}

	convenience override init() {
		self.init(darkBrandColor: UIColor(hex: 0x1D293B), lightBrandColor: UIColor(hex: 0x468CC8))
	}
}
