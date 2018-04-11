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

struct ThemeColorCollection {
	var normal : ThemeColorPair
	var highlighted : ThemeColorPair
	var disabled : ThemeColorPair

	init(fromPair: ThemeColorPair) {
		normal = fromPair
		highlighted = ThemeColorPair(foreground: fromPair.foreground, background: fromPair.background.lighter(0.25))
		disabled = ThemeColorPair(foreground: fromPair.foreground, background: fromPair.background.lighter(0.25))
	}
}

class ThemeCollection {
	// MARK: - Brand colors
	public var darkBrandColor: UIColor
	public var lightBrandColor: UIColor

	// MARK: - Adjacent brand color
	public var darkBrandLabelColor : UIColor
	public var lightBrandLabelColor : UIColor

	public var darkBrandTintColor : UIColor
	public var lightBrandTintColor : UIColor

	// MARK: - Button / Fill color collections
	public var approvalCollection : ThemeColorCollection
	public var neutralCollection : ThemeColorCollection
	public var destructiveCollection : ThemeColorCollection

	public var darkBrandCollection : ThemeColorCollection
	public var lightBrandCollection : ThemeColorCollection

	// MARK: - Label colors
	public var informativeColor: UIColor
	public var successColor: UIColor
	public var warningColor: UIColor
	public var errorColor: UIColor

	public var tintColor : UIColor

	// MARK: - Status Bar
	public var statusBarStyle : UIStatusBarStyle

	// MARK: - Default Collection
	static var defaultCollection : ThemeCollection = ThemeCollection()

	static var darkCollection : ThemeCollection = {
		let collection = ThemeCollection()

		return (collection)
	}()

	init() {
		self.darkBrandColor = UIColor(hex: 0x1D293B)
		self.lightBrandColor = UIColor(hex: 0x468CC8)

		self.darkBrandLabelColor = UIColor.white
		self.lightBrandLabelColor = UIColor.white

		self.darkBrandTintColor = UIColor.white
		self.lightBrandTintColor = UIColor.white

		self.informativeColor = UIColor.darkGray
		self.successColor = UIColor(hex: 0x27AE60)
		self.warningColor = UIColor(hex: 0xF2994A)
		self.errorColor = UIColor(hex: 0xEB5757)

		self.tintColor = self.lightBrandColor

		self.approvalCollection = ThemeColorCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: UIColor(hex: 0x1AC763)))
		self.neutralCollection = ThemeColorCollection(fromPair: ThemeColorPair(foreground: lightBrandLabelColor, background: lightBrandColor))
		self.destructiveCollection = ThemeColorCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: UIColor.red))

		self.lightBrandCollection = ThemeColorCollection(fromPair: ThemeColorPair(foreground: lightBrandLabelColor, background: lightBrandColor))
		self.darkBrandCollection = ThemeColorCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: darkBrandColor))

		self.statusBarStyle = .lightContent
	}
}
