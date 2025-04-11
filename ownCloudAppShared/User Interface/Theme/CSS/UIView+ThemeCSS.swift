//
//  UIView+ThemeCSS.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 20.03.23.
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

public extension UIView {
	func apply(css: ThemeCSS, selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, properties: [ThemeCSSProperty]) {
		for property in properties {
			switch property {
				case .fill:
					if let color = css.getColor(property, selectors: selectors, state: stateSelectors, for: self) {
						if let button = self as? UIButton {
							var buttonConfig = button.configuration
							buttonConfig?.baseBackgroundColor = color
							button.configuration = buttonConfig
						} else {
							backgroundColor = color
						}
					}

				case .stroke:
					if let color = css.getColor(property, selectors: selectors, state: stateSelectors, for: self) {
						if let label = self as? UILabel {
							label.textColor = color
						} else if let textField = self as? UITextField {
							textField.textColor = color
						} else if let textField = self as? UITextView {
							textField.textColor = color
						} else if let button = self as? UIButton {
							var buttonConfig = button.configuration
							buttonConfig?.baseForegroundColor = color
							button.configuration = buttonConfig

							button.tintColor = color
							button.setTitleColor(color, for: .normal)
						} else {
							tintColor = color
						}
					}

				case .cornerRadius:
					if let radius = css.getCGFloat(property, selectors: selectors, state: stateSelectors, for: self) {
						layer.cornerRadius = radius
					}

				case .keyboardAppearance:
					let keyboardAppearance = css.getKeyboardAppearance(selectors: selectors, state: stateSelectors, for: self)

					if let textField = self as? UITextField {
						textField.keyboardAppearance = keyboardAppearance
					}

				default: break
			}
		}
	}

	func withPadding() -> UIView {
		let paddingView = UIView()
		paddingView.translatesAutoresizingMaskIntoConstraints = false
		if self as? UITextField != nil {
			// Space around text fields
			paddingView.embed(toFillWith: self, insets: NSDirectionalEdgeInsets(top: 10, leading: 18, bottom: 10, trailing: 18))
		} else {
			// Space around all other views
			paddingView.embed(toFillWith: self, insets: NSDirectionalEdgeInsets(top: 10, leading: 18, bottom: 10, trailing: 18))
		}
		return paddingView
	}
}
