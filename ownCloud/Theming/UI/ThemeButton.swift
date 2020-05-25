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

enum ThemeButtonCornerRadiusStyle : CGFloat {
	case round = -1
	case small = 5
	case medium = 10
}

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

		intrinsicContentSize.width += buttonHorizontalPadding
		intrinsicContentSize.height += buttonVerticalPadding

		return (intrinsicContentSize)
	}

	private func styleButton() {
		adjustCornerRadius()
		self.titleLabel?.font = buttonFont
		self.titleLabel?.adjustsFontForContentSizeCategory = true
	}

	var buttonFont : UIFont = UIFont.preferredFont(forTextStyle: .headline)
	var buttonHorizontalPadding : CGFloat = 30 {
		didSet {
			invalidateIntrinsicContentSize()
		}
	}
	var buttonVerticalPadding : CGFloat = 10 {
	       didSet {
		       invalidateIntrinsicContentSize()
	       }
	}
	var buttonCornerRadius : ThemeButtonCornerRadiusStyle = .medium {
		didSet {
			adjustCornerRadius()
		}
	}

	func adjustCornerRadius() {
		self.layer.cornerRadius = (buttonCornerRadius == .round) ? bounds.size.height/2 : buttonCornerRadius.rawValue
	}

	override var bounds: CGRect {
		didSet {
			self.adjustCornerRadius()
		}
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
