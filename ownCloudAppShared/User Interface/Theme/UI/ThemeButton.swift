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

public enum ThemeButtonCornerRadiusStyle : CGFloat {
	case round = -1
	case small = 5
	case medium = 10
}

@IBDesignable
open class ThemeButton : UIButton, Themeable, ThemeCSSChangeObserver {
	private var themeRegistered = false
	open override func didMoveToWindow() {
		super.didMoveToWindow()

		if !themeRegistered, window != nil {
			// Postpone registration with theme until we actually need to. Makes sure self.applyThemeCollection() can take all properties into account
			Theme.shared.register(client: self, applyImmediately: true)
			themeRegistered = true
		}
	}

	public func cssSelectorsChanged() {
		if superview != nil {
			self.applyThemeCollection(theme: Theme.shared, collection: Theme.shared.activeCollection, event: .update)
		}
	}

	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		updateConfiguration()
	}

	open override func updateConfiguration() {
		guard let configuration else { return }
		let css = activeThemeCSS

		var updatedConfiguration = configuration.updated(for: self)
		var cssSelectors: [ThemeCSSSelector]?

		if !isEnabled {
			// Disabled
			cssSelectors = [.disabled]
		} else {
			if isHighlighted {
				// Highlighted
				cssSelectors = [.highlighted]
			}

			if isSelected {
				// Selected
				if cssSelectors != nil {
					cssSelectors?.append(.selected)
				} else {
					cssSelectors = [.selected]
				}
			}
		}

		updatedConfiguration.baseForegroundColor = css.getColor(.stroke, selectors: cssSelectors, for: self)
		updatedConfiguration.baseBackgroundColor = css.getColor(.fill,   selectors: cssSelectors, for: self)

		self.configuration = updatedConfiguration
	}

	public override var intrinsicContentSize: CGSize {
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
	public var buttonCornerRadius : ThemeButtonCornerRadiusStyle = .medium {
		didSet {
			adjustCornerRadius()
		}
	}

	func adjustCornerRadius() {
		self.layer.cornerRadius = (buttonCornerRadius == .round) ? bounds.size.height/2 : buttonCornerRadius.rawValue
	}

	public override var bounds: CGRect {
		didSet {
			self.adjustCornerRadius()
		}
	}

	public convenience init(withSelectors: [ThemeCSSSelector]) {
		self.init()
		self.cssSelectors = cssSelectors
	}

	public override init(frame: CGRect) {
		super.init(frame: frame)
		styleButton()
	}

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		styleButton()
	}

	public override func prepareForInterfaceBuilder() {
		super.prepareForInterfaceBuilder()
		styleButton()
	}
}
