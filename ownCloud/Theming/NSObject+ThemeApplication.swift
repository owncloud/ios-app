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

	case logo
	case title
	case message
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
					themeButton.themeColorCollection = collection.lightBrandColorCollection.filledColorPairCollection
			}
		}

		if self.isKind(of: UINavigationController.self) {
			let navigationController : UINavigationController = (self as? UINavigationController)!

			navigationController.navigationBar.applyThemeCollection(collection, itemStyle: itemStyle)
			navigationController.view.backgroundColor = collection.tableBackgroundColor
		}

		if self.isKind(of: UINavigationBar.self) {
			let navigationBar : UINavigationBar = (self as? UINavigationBar)!

			navigationBar.barTintColor = collection.navigationBarColorCollection.backgroundColor
			navigationBar.backgroundColor = collection.navigationBarColorCollection.backgroundColor
			navigationBar.tintColor = collection.navigationBarColorCollection.tintColor
			navigationBar.titleTextAttributes = [ .foregroundColor :  collection.navigationBarColorCollection.labelColor ]
		}

		if self.isKind(of: UIToolbar.self) {
			let toolbar : UIToolbar = (self as? UIToolbar)!

			toolbar.barTintColor = collection.toolBarColorCollection.backgroundColor
			toolbar.tintColor = collection.toolBarColorCollection.tintColor
		}

		if self.isKind(of: UITabBar.self) {
			let tabBar : UITabBar = (self as? UITabBar)!

			tabBar.barTintColor = collection.toolBarColorCollection.backgroundColor
			tabBar.tintColor = collection.toolBarColorCollection.tintColor
		}

		if self.isKind(of: UITableView.self) {
			let tableView : UITableView = (self as? UITableView)!

			tableView.backgroundColor = collection.tableBackgroundColor
			tableView.separatorColor = collection.tableRowSeparatorColor
		}

		if self.isKind(of: UILabel.self) {
			let label : UILabel = (self as? UILabel)!
			var labelColor : UIColor = collection.tableRowColorBarCollection.labelColor

			switch itemStyle {
				case .title:
					labelColor = collection.tableRowColorBarCollection.labelColor

				case .message:
					labelColor = collection.tableRowColorBarCollection.secondaryLabelColor

				default:
					labelColor = collection.tableRowColorBarCollection.labelColor

			}

			label.textColor = labelColor
		}
	}
}
