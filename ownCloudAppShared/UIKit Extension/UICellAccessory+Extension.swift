//
//  UICellAccessory+Extension.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 21.04.23.
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
import ownCloudSDK

public extension UICellAccessory {
	static func button(image: UIImage?, accessibilityLabel: String?, cssSelectors: [ThemeCSSSelector]? = [.accessory], placement: Placement = .trailing(), size: CGSize? = CGSize(width: 32, height: 42), action: UIAction? = nil) -> UICellAccessory {
		let button = ThemeCSSButton(withSelectors: cssSelectors)

		button.setImage(image, for: .normal)
		button.contentMode = .center
		button.isPointerInteractionEnabled = true
		button.accessibilityLabel = accessibilityLabel

		if let action {
			button.addAction(action, for: .primaryActionTriggered)
		}

		if let size {
			button.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height) // Avoid _UITemporaryLayoutWidths auto-layout warnings
			button.widthAnchor.constraint(equalToConstant: size.width).isActive = true
			button.heightAnchor.constraint(equalToConstant: size.height).isActive = true
		}

		return .customView(configuration: UICellAccessory.CustomViewConfiguration(customView: button, placement: placement))
	}

	static func borderedButton(image: UIImage? = nil, title: String? = nil, accessibilityLabel: String? = nil, cssSelectors: [ThemeCSSSelector]? = [.accessory], placement: Placement = .trailing(displayed: .whenNotEditing), action: UIAction? = nil, menu: UIMenu? = nil) -> (UIButton, UICellAccessory) {
		let button = UIButton()

		button.setTitle(title, for: .normal)
		button.setImage(image, for: .normal)
		button.contentMode = .center
		button.isPointerInteractionEnabled = true
		button.accessibilityLabel = accessibilityLabel

		if let action {
			button.addAction(action, for: .primaryActionTriggered)
		}

		if let menu {
			button.showsMenuAsPrimaryAction = true
			button.menu = menu
		}

		button.cssSelectors = cssSelectors

		if image != nil, (title != nil || menu != nil) {
			var configuration = UIAccessibility.isDarkerSystemColorsEnabled ? UIButton.Configuration.bordered() : UIButton.Configuration.borderedTinted()
			configuration.buttonSize = .small
			configuration.imagePadding = 5
			configuration.cornerStyle = .large

			if UIAccessibility.isDarkerSystemColorsEnabled {
				configuration.background.backgroundColor = .clear
				configuration.background.strokeColor = button.getThemeCSSColor(.stroke)
			}

			button.configuration = configuration.updated(for: button)
		}

		button.applyThemeCollection(Theme.shared.activeCollection)

		return (button, .customView(configuration: UICellAccessory.CustomViewConfiguration(customView: button, placement: placement)))
	}
}
