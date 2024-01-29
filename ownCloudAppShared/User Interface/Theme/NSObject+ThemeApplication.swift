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
import ownCloudSDK

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

	// case logo
	case title
	case message

//	case welcomeTitle
//	case welcomeMessage

	case bigTitle
	case bigMessage

	case system(textStyle: UIFont.TextStyle, weight: UIFont.Weight? = nil)
	case systemSecondary(textStyle: UIFont.TextStyle, weight: UIFont.Weight? = nil)

	case purchase
	case welcome
    	case welcomeInformal

    	case content
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

	var cssState: [ThemeCSSSelector] {
		switch self {
			case .disabled:
				return [.disabled]

			case .highlighted:
				return [.highlighted]

			default:
				return []
		}
	}
}

public extension NSObject {
	func applyThemeCollection(_ collection: ThemeCollection, itemStyle: ThemeItemStyle = .defaultForItem, itemState: ThemeItemState = .normal, cellState: UICellConfigurationState? = nil) {
		let css = collection.css

		if let button = self as? UIButton, (self as? ThemeButton) == nil {
			button.apply(css: css, properties: [.stroke])
		}

		if let navigationController = self as? UINavigationController {
			navigationController.navigationBar.applyThemeCollection(collection)
			navigationController.view.apply(css: css, properties: [.fill])
		}

		if let navigationBar = self as? UINavigationBar {
			let navigationBarAppearance = collection.navigationBarAppearance(navigationBar: navigationBar)
			let navigationBarScrollEdgeAppearance = collection.navigationBarAppearance(navigationBar: navigationBar, scrollEdge: true)

			navigationBar.tintColor = css.getColor(.stroke, for: navigationBar)

			navigationBar.standardAppearance = navigationBarAppearance
			navigationBar.compactAppearance = navigationBarAppearance
			navigationBar.scrollEdgeAppearance = navigationBarScrollEdgeAppearance
		}

		if let toolbar = self as? UIToolbar {
			let backgroundColor = css.getColor(.fill, for: toolbar)
			let tintColor = css.getColor(.stroke, for: toolbar)

			let standardAppearance = UIToolbarAppearance()
			standardAppearance.backgroundColor = backgroundColor
			toolbar.standardAppearance = standardAppearance

			let edgeAppearance = UIToolbarAppearance()
			edgeAppearance.backgroundColor = backgroundColor
			edgeAppearance.shadowColor = .clear
			toolbar.scrollEdgeAppearance = edgeAppearance

			toolbar.barTintColor = backgroundColor
			toolbar.tintColor = tintColor
		}

		if let tableView = self as? UITableView {
			tableView.backgroundColor = css.getColor(.fill, for: tableView)
			tableView.separatorColor = css.getColor(.fill, selectors: [.separator], for: tableView)
		}

		if let collectionView = self as? UICollectionView {
			collectionView.apply(css: css, properties: [.fill])
		}

		if let searchBar = self as? UISearchBar {
			searchBar.tintColor = css.getColor(.stroke, selectors: [.navigationBar], for: searchBar)
			searchBar.barStyle = css.getBarStyle(for: searchBar) ?? .default

			// Ensure search bar icon color is correct
			searchBar.overrideUserInterfaceStyle = collection.css.getUserInterfaceStyle()

			searchBar.searchTextField.applyThemeCollection(collection)
		}

		if let label = self as? UILabel {
			// Change font for any type of label
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

			// Adapt color only for non-ThemeCSSLabel
			let cssLabel = self as? ThemeCSSLabel
			if cssLabel == nil {
				var normalColor : UIColor
				var highlightColor : UIColor
				let disabledColor : UIColor = css.getColor(.stroke, selectors: [.secondary], for: label) ?? .secondaryLabel

				switch itemStyle {
					case .message, .bigMessage, .systemSecondary(textStyle: _, weight: _):
						normalColor = css.getColor(.stroke, selectors: [.secondary], for: label) ?? .secondaryLabel
						highlightColor = css.getColor(.stroke, selectors: [.secondary], state: [.highlighted], for: label) ?? .tertiaryLabel

					default:
						normalColor = css.getColor(.stroke, selectors: [.primary], for: label) ?? .label
						highlightColor = css.getColor(.stroke, selectors: [.primary], state: [.highlighted], for: label) ?? .label
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
		}

		if let textField = self as? UITextField {
			let tintColor = css.getColor(.stroke, for: textField)

			textField.tintColor = tintColor
			textField.textColor = css.getColor(.stroke, selectors: [.label], state: (textField.isEnabled ? [] : [.disabled]), for: textField)
			textField.overrideUserInterfaceStyle = css.getUserInterfaceStyle(for: textField)
			textField.keyboardAppearance = css.getKeyboardAppearance(for: textField)

			if let placeholderString = textField.placeholder, let placeholderTextColor = css.getColor(.stroke, selectors: [.placeholder], for: textField) {
				textField.attributedPlaceholder = NSAttributedString(string: placeholderString, attributes: [.foregroundColor : placeholderTextColor])
			}

			if let clearButton = textField.value(forKey: "clearButton") as? UIButton {
				clearButton.setImage(OCSymbol.icon(forSymbolName: "xmark.circle.fill"), for: .normal)
				clearButton.tintColor = tintColor
			}

			if let searchTextField = textField as? UISearchTextField {
				if let glassIconView = searchTextField.leftView as? UIImageView {
					glassIconView.image = glassIconView.image?.withRenderingMode(.alwaysTemplate)
					glassIconView.tintColor = tintColor
				}
			}
		}

		if let cell = self as? UITableViewCell {
			cell.backgroundColor = css.getColor(.fill, for: cell) // collection.tableRowColors.backgroundColor
			cell.tintColor = css.getColor(.stroke, for: cell) // collection.lightBrandColor

			if cell.selectionStyle != .none {
				if let highlightedBackgroundColor = css.getColor(.fill, state: [.highlighted], for: cell) { // collection.tableRowHighlightColors.backgroundColor
					let backgroundView = UIView()

					backgroundView.backgroundColor = highlightedBackgroundColor

					cell.selectedBackgroundView = backgroundView
				} else {
					cell.selectedBackgroundView = nil
				}
			}

			cell.overrideUserInterfaceStyle  = css.getUserInterfaceStyle(for: cell) // collection.interfaceStyle.userInterfaceStyle
		}

		if let cell = self as? UICollectionViewCell {
			var updateColors = true

			if let listCell = cell as? ThemeableCollectionViewListCell {
				updateColors = listCell.updateColors
			}

			if updateColors {
				var stateSelectors: [ThemeCSSSelector] = []

				if let cellState {
					if cellState.isHighlighted { stateSelectors.append(.highlighted) }
					if cellState.isSelected { stateSelectors.append(.selected) }
				}

				if let fillColor = css.getColor(.fill, selectors: stateSelectors, for: cell) {
					var backgroundConfig = (cellState != nil) ? cell.backgroundConfiguration?.updated(for: cellState!) : cell.backgroundConfiguration
					backgroundConfig?.backgroundColor = fillColor
					cell.backgroundConfiguration = backgroundConfig
				}

				if var cellListConfiguration = cell.contentConfiguration as? UIListContentConfiguration {
					if let textColor = css.getColor(.stroke, selectors: stateSelectors, for: cell) {
						cellListConfiguration.textProperties.color = textColor
					}

					var iconSelectors = stateSelectors
					iconSelectors.append(.icon)

					if let iconColor = css.getColor(.stroke, selectors: iconSelectors, for: cell) {
						cellListConfiguration.imageProperties.tintColor = iconColor
					}
					cell.contentConfiguration = cellListConfiguration
				}

				cell.tintColor = css.getColor(.stroke, selectors: stateSelectors, for: cell)

				cell.overrideUserInterfaceStyle = (css.get(.style, for: cell)?.value as? UIUserInterfaceStyle) ?? .unspecified
			}
		}

		if let segmentedControl = self as? UISegmentedControl {
			if let textColor = css.getColor(.stroke, for: segmentedControl) {
				segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : textColor], for: .normal)
			}

			let tintColor = css.getColor(.fill, for: segmentedControl)
			segmentedControl.tintColor = tintColor

			if let selectedTextColor = css.getColor(.stroke, state: [.selected], for: segmentedControl) {
				segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : selectedTextColor], for: .selected)
			}

			let selectedTintColor = css.getColor(.fill, state: [.selected], for: segmentedControl)
			segmentedControl.selectedSegmentTintColor = selectedTintColor
		}

		if let visualEffectView = self as? UIVisualEffectView {
			visualEffectView.overrideUserInterfaceStyle = collection.css.getUserInterfaceStyle()
		}
	}
}
