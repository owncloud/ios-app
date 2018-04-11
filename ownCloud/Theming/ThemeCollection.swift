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

struct ThemeColorPair {
	var foreground: UIColor
	var background: UIColor
}

struct ThemeColorPairCollection {
	var normal : ThemeColorPair
	var highlighted : ThemeColorPair
	var disabled : ThemeColorPair

	init(fromPair: ThemeColorPair) {
		normal = fromPair
		highlighted = ThemeColorPair(foreground: fromPair.foreground, background: fromPair.background.lighter(0.25))
		disabled = ThemeColorPair(foreground: fromPair.foreground, background: fromPair.background.lighter(0.25))
	}
}

struct ThemeColorCollection {
	var backgroundColor : UIColor?
	var labelColor : UIColor
	var symbolColor : UIColor
	var secondaryLabelColor : UIColor
	var tintColor : UIColor?

	var filledColorPairCollection : ThemeColorPairCollection
}

enum ThemeCollectionStyle {
	case dark
	case light
	case contrast
}

class ThemeCollection {
	// MARK: - Brand colors
	public var darkBrandColor: UIColor
	public var lightBrandColor: UIColor

	// MARK: - Brand color collection
	public var darkBrandColorCollection : ThemeColorCollection
	public var lightBrandColorCollection : ThemeColorCollection

	// MARK: - Button / Fill color collections
	public var approvalCollection : ThemeColorPairCollection
	public var neutralCollection : ThemeColorPairCollection
	public var destructiveCollection : ThemeColorPairCollection

	// MARK: - Label colors
	public var informativeColor: UIColor
	public var successColor: UIColor
	public var warningColor: UIColor
	public var errorColor: UIColor

	public var tintColor : UIColor

	// MARK: - Table views
	public var tableBackgroundColor : UIColor
	public var tableRowSeparatorColor : UIColor?
	public var tableRowColorBarCollection : ThemeColorCollection

	// MARK: - Bars
	public var navigationBarColorCollection : ThemeColorCollection
	public var toolBarColorCollection : ThemeColorCollection
	public var statusBarStyle : UIStatusBarStyle

	// MARK: - Default Collection
	static var defaultCollection : ThemeCollection = ThemeCollection()

	static var darkCollection : ThemeCollection = {
		let collection = ThemeCollection()

		return (collection)
	}()

	init(darkBrandColor darkColor: UIColor, lightBrandColor lightColor: UIColor, style: ThemeCollectionStyle = .dark) {
		self.darkBrandColor = darkColor
		self.lightBrandColor = lightColor

		self.darkBrandColorCollection = ThemeColorCollection(
			backgroundColor: darkColor,
			labelColor: UIColor.white,
			symbolColor: UIColor.white,
			secondaryLabelColor: UIColor.lightGray,
			tintColor: lightColor.lighter(0.2),
			filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: darkColor))
		)

		self.lightBrandColorCollection = ThemeColorCollection(
			backgroundColor: lightColor,
			labelColor: UIColor.white,
			symbolColor: UIColor.white,
			secondaryLabelColor: UIColor.lightGray,
			tintColor: UIColor.white,
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
					labelColor: navigationBarColorCollection.labelColor,
					symbolColor: lightColor,
					secondaryLabelColor: navigationBarColorCollection.secondaryLabelColor,
					tintColor: navigationBarColorCollection.tintColor,
					filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: lightBrandColor))
				)

				// Status Bar
				self.statusBarStyle = .lightContent

			case .light:
				// Bars
				self.navigationBarColorCollection = ThemeColorCollection(
					backgroundColor: nil,
					labelColor: UIColor.black,
					symbolColor: darkColor,
					secondaryLabelColor: UIColor.gray,
					tintColor: nil,
					filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: lightBrandColor))
				)

				self.toolBarColorCollection = self.navigationBarColorCollection

				// Table view
				self.tableBackgroundColor = UIColor.white
				self.tableRowSeparatorColor = nil
				self.tableRowColorBarCollection = ThemeColorCollection(
					backgroundColor: tableBackgroundColor,
					labelColor: UIColor.black,
					symbolColor: darkColor,
					secondaryLabelColor: UIColor.gray,
					tintColor: nil,
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
					labelColor: UIColor.black,
					symbolColor: darkBrandColor,
					secondaryLabelColor: UIColor.gray,
					tintColor: nil,
					filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: lightBrandColor))
				)

				// Status Bar
				self.statusBarStyle = .lightContent

		}
	}

	convenience init() {
		self.init(darkBrandColor: UIColor(hex: 0x1D293B), lightBrandColor: UIColor(hex: 0x468CC8))
	}
}
