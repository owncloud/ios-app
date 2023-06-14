//
//  GradientView.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 21.04.22.
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

public class GradientView : UIView {
	public enum Direction {
		case vertical
		case horizontal

		var startPoint: CGPoint {
			switch self {
				case .vertical: return CGPoint(x: 0.5, y: 0.0)
				case .horizontal: return CGPoint(x: 0.0, y: 0.5)
			}
		}
		var endPoint: CGPoint {
			switch self {
				case .vertical: return CGPoint(x: 0.5, y: 1.0)
				case .horizontal: return CGPoint(x: 1.0, y: 0.5)
			}
		}
	}

	public var colors: [CGColor] {
		didSet {
			gradientLayer?.colors = colors
		}
	}
	public var locations: [NSNumber] {
		didSet {
			gradientLayer?.locations = locations
		}
	}

	var gradientLayer : CAGradientLayer?

	public init(with colors: [CGColor], locations: [NSNumber], direction: Direction = .vertical) {
		self.colors = colors
		self.locations = locations

		super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 20))

		backgroundColor = .clear

		gradientLayer = CAGradientLayer()
		gradientLayer?.colors = colors
		gradientLayer?.locations = locations
		gradientLayer?.startPoint = direction.startPoint
		gradientLayer?.endPoint = direction.endPoint
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override public var bounds: CGRect {
		didSet {
			gradientLayer?.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height)

			if let gradientLayer = gradientLayer, gradientLayer.superlayer == nil {
				self.layer.addSublayer(gradientLayer)
			}
		}
	}

	public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		// Be transparant to touch events
		return nil
	}
}

public class ShadowBarView : GradientView, Themeable {
	public init() {
		super.init(with: [UIColor(hex: 0, alpha: 0).cgColor, UIColor(hex: 0, alpha: 0.10).cgColor, UIColor(hex: 0, alpha: 0.25).cgColor], locations: [0.0, 0.9, 1.0])
		cssSelector = .shadow
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	private var _registered: Bool = false
	public override func didMoveToWindow() {
		super.didMoveToWindow()

		if window != nil, !_registered {
			_registered = true
			Theme.shared.register(client: self, applyImmediately: true)
		}
	}

	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		if let shadowColor = collection.css.getColor(.fill, for: self) {
			self.colors = [shadowColor.withAlphaComponent(0).cgColor, shadowColor.withAlphaComponent(0.1).cgColor, shadowColor.withAlphaComponent(0.25).cgColor]
		}
	}
}
