//
//  ThemeCSS+SystemColors.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 26.07.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

extension ThemeCSSAddress {
	func cssComponents() -> ([ThemeCSSSelector]?, ThemeCSSProperty?) {
		var components = components(separatedBy: ".")
		if components.count >= 2 {
			let propertyName = components.removeLast()
			let selectors = components.compactMap { (str) in return ThemeCSSSelector(rawValue: str) }

			return (selectors, ThemeCSSProperty(rawValue: propertyName))
		}

		return (nil, nil)
	}
}

extension ThemeCSS {
	func add(color: UIColor, address: ThemeCSSAddress) {
		let (selectors, property) = address.cssComponents()

		if let selectors, let property {
			self.add(record: ThemeCSSRecord(selectors: selectors, property: property, value: color))
		}
	}

	func addSystemColors() {
		add(color: .systemBlue,		address: "os.color.blue")
		add(color: .systemBrown,	address: "os.color.brown")
		add(color: .systemCyan,		address: "os.color.cyan")
		add(color: .systemGreen,	address: "os.color.green")
		add(color: .systemIndigo,	address: "os.color.indigo")
		add(color: .systemMint,		address: "os.color.mint")
		add(color: .systemOrange,	address: "os.color.orange")
		add(color: .systemPink,		address: "os.color.pink")
		add(color: .systemPurple,	address: "os.color.purple")
		add(color: .systemRed,		address: "os.color.red")
		add(color: .systemTeal,		address: "os.color.teal")
		add(color: .systemYellow,	address: "os.color.yellow")
		add(color: .systemGray,		address: "os.color.gray1")
		add(color: .systemGray2,	address: "os.color.gray2")
		add(color: .systemGray3,	address: "os.color.gray3")
		add(color: .systemGray4,	address: "os.color.gray4")
		add(color: .systemGray5,	address: "os.color.gray5")
		add(color: .systemGray6,	address: "os.color.gray6")

		add(color: .clear,		address: "os.color.clear") // transparent
	}
}
