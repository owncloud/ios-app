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
open class ThemeButton : UIButton {
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

	override public var isHighlighted: Bool {
		set(newIsHighlighted) {
			super.isHighlighted = newIsHighlighted
			updateBackgroundColor()
		}

		get {
			return super.isHighlighted
		}
	}

	override public var isEnabled: Bool {
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

	override public var intrinsicContentSize: CGSize {
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

	public var buttonFont : UIFont = UIFont.preferredFont(forTextStyle: .headline)
	public var buttonHorizontalPadding : CGFloat = 30 {
		didSet {
			invalidateIntrinsicContentSize()
		}
	}
	public var buttonVerticalPadding : CGFloat = 10 {
	       didSet {
		       invalidateIntrinsicContentSize()
	       }
	}
	public var buttonCornerRadius : CGFloat = 5 {
		didSet {
			adjustCornerRadius()
		}
	}

	public func adjustCornerRadius() {
		self.layer.cornerRadius = (buttonCornerRadius < 0) ? bounds.size.height/2 : buttonCornerRadius
	}

	override public var bounds: CGRect {
		didSet {
			self.adjustCornerRadius()
		}
	}

	override public init(frame: CGRect) {
		super.init(frame: frame)
		styleButton()
	}

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		styleButton()
	}

	override public func prepareForInterfaceBuilder() {
		super.prepareForInterfaceBuilder()
		styleButton()
	}
}
