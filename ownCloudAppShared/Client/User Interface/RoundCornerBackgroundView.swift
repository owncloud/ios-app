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
	var fillColor: UIColor? {
		didSet {
			setNeedsDisplay()
		}
	}
	var fillColorPicker: ThemeColorPicker? {
		didSet {
			setNeedsDisplay()
		}
	}
	public var fillImage: UIImage? {
		didSet {
			setNeedsDisplay()
		}
	}

	typealias ThemeColorPicker = (_ theme: Theme, _ collection: ThemeCollection, _ event: ThemeEvent) -> UIColor?

	init(with radius: CornerRadius = .standard, fillColor: UIColor? = nil, fillColorPicker: ThemeColorPicker? = nil) {
		self.fillColor = fillColor
		self.cornerRadius = radius

		super.init(frame: .zero)
		translatesAutoresizingMaskIntoConstraints = false
		isOpaque = false

		self.fillColorPicker = fillColorPicker

		if fillColor != nil {
			_registered = true // Do not register for dynamic coloring when a fill color is provided
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override func draw(_ rect: CGRect) {
		let bezierPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: cornerRadius.corners, cornerRadii: cornerRadius.radii)

		if let fillImage {
			func sizeThatFills(srcSize: CGSize, dstSize: CGSize) -> CGSize {
				var fillSize = srcSize

				fillSize.height = fillSize.height * dstSize.width / fillSize.width
				fillSize.width = dstSize.width

				if fillSize.height < dstSize.height {
					fillSize.width = fillSize.width * dstSize.height / fillSize.height
					fillSize.height = dstSize.height
				}

				return fillSize
			}

			let bounds = bounds
			let fillSize = sizeThatFills(srcSize: fillImage.size, dstSize: bounds.size)
			var drawRect: CGRect = CGRect()

			drawRect.origin.x = bounds.origin.x + (bounds.size.width - fillSize.width) / 2.0
			drawRect.origin.y = bounds.origin.y + (bounds.size.height - fillSize.height) / 2.0
			drawRect.size = fillSize

			bezierPath.addClip()
			fillImage.draw(in: drawRect)
		}

		fillColor?.setFill()
		bezierPath.fill()
	}

	private var _registered = false
	public override func didMoveToWindow() {
		super.didMoveToWindow()

		if window != nil, !_registered {
			_registered = true

			Theme.shared.register(client: self, applyImmediately: true)
		}
	}

	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		if let fillColorPicker {
			if let pickedColor = fillColorPicker(theme, collection, event) {
				fillColor = pickedColor
			}
		} else {
			if let cssColor = collection.css.getColor(.fill, for: self) {
				fillColor = cssColor
			}
		}
	}
}
