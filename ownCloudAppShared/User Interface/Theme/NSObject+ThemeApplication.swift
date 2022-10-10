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

public enum ThemeItemStyle {
	case defaultForItem

	case success
	case informal
	case warning
	case error

	case approval
	case neutral
	case destructive
	case cancel

	case logo
	case title
	case message

	case welcomeTitle
	case welcomeMessage

	case bigTitle
	case bigMessage

	case system(textStyle: UIFont.TextStyle, weight: UIFont.Weight? = nil)
	case systemSecondary(textStyle: UIFont.TextStyle, weight: UIFont.Weight? = nil)

	case purchase
	case welcome
}

public enum ThemeItemState {
	case normal
	case highlighted
	case disabled

	public init(selected: Bool) {
		if selected {
			self = .highlighted
		} else {
			self = .normal
		}
	}
}

public protocol ThemeableSectionHeader : AnyObject {
	var sectionHeaderColor : UIColor? { get set }
}

public protocol ThemeableSectionFooter : AnyObject {
	var sectionFooterColor : UIColor? { get set }
}

public extension NSObject {
	func applyThemeCollection(_ collection: ThemeCollection, itemStyle: ThemeItemStyle = .defaultForItem, itemState: ThemeItemState = .normal) {
		if let themeButton = self as? ThemeButton {
			switch itemStyle {
				case .approval:
					themeButton.themeColorCollection = collection.approvalColors

				case .neutral:
					themeButton.themeColorCollection = collection.neutralColors

				case .destructive:
					themeButton.themeColorCollection = collection.destructiveColors

				case .bigTitle:
					themeButton.themeColorCollection = collection.neutralColors
					themeButton.titleLabel?.font = UIFont.systemFont(ofSize: 34)

				case .purchase:
					themeButton.themeColorCollection = collection.purchaseColors

				case .welcome:
					themeButton.themeColorCollection = collection.loginColors.filledColorPairCollection

				case .informal:
					themeButton.themeColorCollection = collection.informalColors.filledColorPairCollection

				case .cancel:
					themeButton.themeColorCollection = collection.cancelColors.filledColorPairCollection

				default:
					themeButton.themeColorCollection = collection.lightBrandColors.filledColorPairCollection
			}
		} else if let button = self as? UIButton {
			button.tintColor = collection.navigationBarColors.tintColor
		}

		if let navigationController = self as? UINavigationController {
			navigationController.navigationBar.applyThemeCollection(collection, itemStyle: itemStyle)
			navigationController.view.backgroundColor = collection.tableBackgroundColor
		}

		if let navigationBar = self as? UINavigationBar {
			navigationBar.barTintColor = collection.navigationBarColors.backgroundColor
			navigationBar.backgroundColor = collection.navigationBarColors.backgroundColor
			navigationBar.tintColor = collection.navigationBarColors.tintColor
			navigationBar.titleTextAttributes = [ .foregroundColor :  collection.navigationBarColors.labelColor ]
			navigationBar.largeTitleTextAttributes = [ .foregroundColor :  collection.navigationBarColors.labelColor ]
			navigationBar.isTranslucent = false

			let navigationBarAppearance = collection.navigationBarAppearance

			navigationBar.standardAppearance = navigationBarAppearance
			navigationBar.compactAppearance = navigationBarAppearance
			navigationBar.scrollEdgeAppearance = navigationBarAppearance
		}

		if let toolbar = self as? UIToolbar {
			toolbar.barTintColor = collection.toolbarColors.backgroundColor
			toolbar.tintColor = collection.toolbarColors.tintColor
		}

		if let tabBar = self as? UITabBar {
			tabBar.barTintColor = collection.toolbarColors.backgroundColor
			tabBar.tintColor = collection.toolbarColors.tintColor
			tabBar.unselectedItemTintColor = collection.toolbarColors.secondaryLabelColor

			let appearance = UITabBarAppearance()
			appearance.backgroundColor = collection.toolbarColors.backgroundColor

			tabBar.standardAppearance = appearance
			tabBar.scrollEdgeAppearance = appearance
		}

		if let tableView = self as? UITableView {
			tableView.backgroundColor = tableView.style == .grouped ? collection.tableGroupBackgroundColor : collection.tableBackgroundColor
			tableView.separatorColor = collection.tableSeparatorColor

			if let themeableSectionHeaderTableView = tableView as? ThemeableSectionHeader {
				themeableSectionHeaderTableView.sectionHeaderColor = collection.tableSectionHeaderColor
			}

			if let themeableSectionFooterTableView = tableView as? ThemeableSectionFooter {
				themeableSectionFooterTableView.sectionFooterColor = collection.tableSectionFooterColor
			}
		}

		if let collectionView = self as? UICollectionView {
			collectionView.backgroundColor = collection.tableBackgroundColor
		}

		if let searchBar = self as? UISearchBar {
			searchBar.tintColor = collection.searchBarColors.tintColor
			searchBar.barStyle = collection.barStyle

			searchBar.searchTextField.textColor = collection.searchBarColors.labelColor
			// Ensure search bar icon color is correct
			searchBar.overrideUserInterfaceStyle = collection.interfaceStyle.userInterfaceStyle
			searchBar.searchTextField.backgroundColor = collection.searchBarColors.backgroundColor

			if let glassIconView = searchBar.searchTextField.leftView as? UIImageView {
				glassIconView.image = glassIconView.image?.withRenderingMode(.alwaysTemplate)
				glassIconView.tintColor = collection.searchBarColors.secondaryLabelColor
			}
			if let clearButton = searchBar.searchTextField.value(forKey: "clearButton") as? UIButton {
				clearButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
				clearButton.tintColor = collection.searchBarColors.secondaryLabelColor
			}
		}

		if let label = self as? UILabel {
			var normalColor : UIColor = collection.tableRowColors.labelColor
			var highlightColor : UIColor = collection.tableRowHighlightColors.labelColor
			let disabledColor : UIColor = collection.tableRowColors.secondaryLabelColor

			switch itemStyle {
				case .title, .bigTitle, .system(textStyle: _, weight: _):
					normalColor = collection.tableRowColors.labelColor
					highlightColor = collection.tableRowHighlightColors.labelColor

				case .welcomeTitle:
					normalColor = collection.loginColors.labelColor
					highlightColor = collection.loginColors.labelColor

				case .welcomeMessage:
					normalColor = collection.loginColors.secondaryLabelColor
					highlightColor = collection.loginColors.secondaryLabelColor

				case .message, .bigMessage, .systemSecondary(textStyle: _, weight: _):
					normalColor = collection.tableRowColors.secondaryLabelColor
					highlightColor = collection.tableRowHighlightColors.secondaryLabelColor

				case .logo:
					normalColor = collection.navigationBarColors.labelColor
					highlightColor = collection.navigationBarColors.secondaryLabelColor

				default:
					normalColor = collection.tableRowColors.labelColor
					highlightColor = collection.tableRowHighlightColors.labelColor
			}

			switch itemStyle {
				case .bigTitle:
					label.font = UIFont.boldSystemFont(ofSize: 34)

				case .bigMessage:
					label.font = UIFont.systemFont(ofSize: 17)

				case .system(let txtStyle, let txtWeight):
					if let txtWeight = txtWeight {
						label.font = UIFont.preferredFont(forTextStyle: txtStyle, with: txtWeight)
					} else {
						label.font = UIFont.preferredFont(forTextStyle: txtStyle)
					}

				case .systemSecondary(let txtStyle, let txtWeight):
					if let txtWeight = txtWeight {
						label.font = UIFont.preferredFont(forTextStyle: txtStyle, with: txtWeight)
					} else {
						label.font = UIFont.preferredFont(forTextStyle: txtStyle)
					}

				default:
				break
			}

			switch itemState {
				case .normal:
					label.textColor = normalColor

				case .highlighted:
					label.textColor = highlightColor

				case .disabled:
					label.textColor = disabledColor
			}
		}

		if let searchTextField = self as? UISearchTextField {
			searchTextField.tintColor = collection.searchBarColors.tintColor
			searchTextField.textColor = collection.searchBarColors.labelColor
			searchTextField.overrideUserInterfaceStyle = collection.interfaceStyle.userInterfaceStyle

			if let glassIconView = searchTextField.leftView as? UIImageView {
				glassIconView.image = glassIconView.image?.withRenderingMode(.alwaysTemplate)
				glassIconView.tintColor = collection.searchBarColors.secondaryLabelColor
			}
			if let clearButton = searchTextField.value(forKey: "clearButton") as? UIButton {
				clearButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
				clearButton.tintColor = collection.searchBarColors.secondaryLabelColor
			}
		} else if let textField = self as? UITextField {
			textField.textColor = collection.tableRowColors.labelColor
		}

		if let cell = self as? UITableViewCell {
			cell.backgroundColor = collection.tableRowColors.backgroundColor
			cell.tintColor = collection.lightBrandColor

			if cell.selectionStyle != .none {
				if collection.tableRowHighlightColors.backgroundColor != nil {
					let backgroundView = UIView()

					backgroundView.backgroundColor = collection.tableRowHighlightColors.backgroundColor

					cell.selectedBackgroundView = backgroundView
				} else {
					cell.selectedBackgroundView = nil
				}
			}

			cell.overrideUserInterfaceStyle  = collection.interfaceStyle.userInterfaceStyle
		}

		if let cell = self as? UICollectionViewListCell {
			var backgroundConfig = cell.backgroundConfiguration
			backgroundConfig?.backgroundColor = collection.tableRowColors.backgroundColor
			cell.backgroundConfiguration = backgroundConfig

			cell.tintColor = collection.lightBrandColor

			cell.overrideUserInterfaceStyle  = collection.interfaceStyle.userInterfaceStyle
		}

		if let progressView = self as? UIProgressView {
			progressView.tintColor = collection.tintColor
			progressView.trackTintColor = collection.tableSeparatorColor
		}

		if let segmentedControl = self as? UISegmentedControl {
			var tintColor = collection.tintColor

			if let navigationTintColor = collection.navigationBarColors.tintColor {
				tintColor = navigationTintColor
			}

			segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : tintColor], for: .normal)
			segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : collection.navigationBarColors.backgroundColor!], for: .selected)
			segmentedControl.selectedSegmentTintColor = tintColor
		}

		if let visualEffectView = self as? UIVisualEffectView {
			visualEffectView.overrideUserInterfaceStyle = collection.interfaceStyle.userInterfaceStyle
		}
	}
}
