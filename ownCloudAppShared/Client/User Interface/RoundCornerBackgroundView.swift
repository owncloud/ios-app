//
//  RoundCornerBackgroundView.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 21.09.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

public struct CornerRadius {
	var radii: CGSize
	var corners: UIRectCorner

	static let standard : CornerRadius = .identical(with: 10)

	static func identical(with radius: CGFloat) -> CornerRadius {
		return CornerRadius(radii: CGSize(width: radius, height: radius), corners: .allCorners)
	}
	static func topOnly(with radius: CGFloat) -> CornerRadius {
		return CornerRadius(radii: CGSize(width: radius, height: radius), corners: [.topLeft, .topRight])
	}
	static func bottomOnly(with radius: CGFloat) -> CornerRadius {
		return CornerRadius(radii: CGSize(width: radius, height: radius), corners: [.bottomLeft, .bottomRight])
	}
}

public class RoundCornerBackgroundView: UIView, Themeable {
	var cornerRadius: CornerRadius {
		didSet {
			setNeedsDisplay()
		}
	}
	var fillColor: UIColor {
		didSet {
			setNeedsDisplay()
		}
	}
	var fillColorPicker: ThemeColorPicker? {
		didSet {
			setNeedsDisplay()
		}
	}

	typealias ThemeColorPicker = (_ theme: Theme, _ collection: ThemeCollection, _ event: ThemeEvent) -> UIColor?

	init(with radius: CornerRadius = .standard, fillColor: UIColor = .systemGroupedBackground, fillColorPicker: ThemeColorPicker? = nil) {
		self.fillColor = fillColor
		self.cornerRadius = radius

		super.init(frame: .zero)
		translatesAutoresizingMaskIntoConstraints = false
		isOpaque = false

		self.fillColorPicker = fillColorPicker

		if fillColorPicker != nil {
			Theme.shared.register(client: self, applyImmediately: true)
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override func draw(_ rect: CGRect) {
		let bezierPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: cornerRadius.corners, cornerRadii: cornerRadius.radii)
		fillColor.setFill()
		bezierPath.fill()
	}

	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		if let fillColorPicker = fillColorPicker {
			if let pickedColor = fillColorPicker(theme, collection, event) {
				fillColor = pickedColor
			}
		}
	}
}
