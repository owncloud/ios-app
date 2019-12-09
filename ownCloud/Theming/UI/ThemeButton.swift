//
//  ActionButton.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.03.18.
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

@IBDesignable
class ThemeButton : UIButton {
	internal var _themeColorCollection : ThemeColorPairCollection?
	public var themeColorCollection : ThemeColorPairCollection? {
		set(colorCollection) {
			_themeColorCollection = colorCollection

			if _themeColorCollection != nil {
				self.setTitleColor(_themeColorCollection?.normal.foreground, for: .normal)
				self.setTitleColor(_themeColorCollection?.highlighted.foreground, for: .highlighted)
				self.setTitleColor(_themeColorCollection?.disabled.foreground, for: .disabled)

				self.updateBackgroundColor()
			}
		}

		get {
			return _themeColorCollection
		}
	}

	override var isHighlighted: Bool {
		set(newIsHighlighted) {
			super.isHighlighted = newIsHighlighted
			updateBackgroundColor()
		}

		get {
			return super.isHighlighted
		}
	}

	override var isEnabled: Bool {
		set(newIsEnabled) {
			super.isEnabled = newIsEnabled
			updateBackgroundColor()
		}

		get {
			return super.isEnabled
		}
	}

	private func updateBackgroundColor() {
		if _themeColorCollection != nil {
			if !self.isEnabled {
				self.backgroundColor = _themeColorCollection?.disabled.background
			} else {
				if self.isHighlighted {
					self.backgroundColor = _themeColorCollection?.highlighted.background
				} else {
					self.backgroundColor = _themeColorCollection?.normal.background
				}
			}
		}
	}

	override var intrinsicContentSize: CGSize {
		var intrinsicContentSize = super.intrinsicContentSize

		intrinsicContentSize.width += 30
		intrinsicContentSize.height += 10

		return (intrinsicContentSize)
	}

	private func styleButton() {
		self.layer.cornerRadius = 8
		self.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
		self.titleLabel?.adjustsFontForContentSizeCategory = true
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		styleButton()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		styleButton()
	}

	override func prepareForInterfaceBuilder() {
		super.prepareForInterfaceBuilder()
		styleButton()
	}
}
