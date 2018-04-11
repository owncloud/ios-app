//
//  NSObject+ThemeApplication.swift
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

enum ThemeItemStyle {
	case defaultForItem

	case success
	case informal
	case warning
	case error

	case approval
	case neutral
	case destructive
}

extension NSObject {
	func applyThemeCollection(_ collection: ThemeCollection, itemStyle: ThemeItemStyle = .defaultForItem) {
		if self.isKind(of: ThemeButton.self) {
			let themeButton : ThemeButton = (self as? ThemeButton)!

			switch itemStyle {
				case .approval:
					themeButton.themeColorCollection = collection.approvalCollection

				case .neutral:
					themeButton.themeColorCollection = collection.neutralCollection

				case .destructive:
					themeButton.themeColorCollection = collection.destructiveCollection

				default:
					themeButton.themeColorCollection = collection.lightBrandCollection
			}
		}

		if self.isKind(of: UINavigationController.self) {
			let navigationController : UINavigationController = (self as? UINavigationController)!

			navigationController.navigationBar.applyThemeCollection(collection, itemStyle: itemStyle)
		}

		if self.isKind(of: UINavigationBar.self) {
			let navigationBar : UINavigationBar = (self as? UINavigationBar)!

			navigationBar.barTintColor = collection.darkBrandColor
			navigationBar.backgroundColor = collection.darkBrandColor
			navigationBar.tintColor = collection.darkBrandTintColor
			navigationBar.titleTextAttributes = [ .foregroundColor :  collection.darkBrandLabelColor ]
		}
	}
}
