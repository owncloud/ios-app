//
//  SegmentView.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 29.09.22.
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

public class SegmentView: ThemeView {
	public enum TruncationMode {
		case none
		case clipTail
		case truncateHead
		case truncateTail
	}

 	open var items: [SegmentViewItem] {
 		didSet {
 			if superview != nil {
				recreateAndLayoutItemViews()
			}
		}
	}
 	open var itemSpacing: CGFloat = 5
 	open var truncationMode: TruncationMode = .none
 	open var insets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

	public init(with items: [SegmentViewItem], truncationMode: TruncationMode) {
		self.items = items

		super.init()

		self.truncationMode = truncationMode
		isOpaque = false
	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func composeMaskView(leading: Bool) -> UIView {
		let fadeInFromLeft: Bool = (effectiveUserInterfaceLayoutDirection == .leftToRight) ? leading : !leading
		let gradientColors: [CGColor] = [
			CGColor(red: 0, green: 0, blue: 0, alpha: fadeInFromLeft ? 0.0 : 1.0),
			CGColor(red: 0, green: 0, blue: 0, alpha: fadeInFromLeft ? 1.0 : 0.0)
		]
		let rootView = UIView(frame: bounds)
		let fillView = UIView()
		let gradientWidth : CGFloat = 20
		let gradientView = GradientView(with: gradientColors, locations: [0, 1], direction: .horizontal)

		fillView.backgroundColor = .black

		fillView.translatesAutoresizingMaskIntoConstraints = false
		gradientView.translatesAutoresizingMaskIntoConstraints = false

		var constraints: [NSLayoutConstraint] = [
			fillView.topAnchor.constraint(equalTo: rootView.topAnchor),
			fillView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
			gradientView.topAnchor.constraint(equalTo: rootView.topAnchor),
			gradientView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
			gradientView.widthAnchor.constraint(equalToConstant: gradientWidth)
		]

		rootView.addSubview(fillView)
		rootView.addSubview(gradientView)

		if fadeInFromLeft {
			constraints.append(contentsOf: [
				gradientView.leftAnchor.constraint(equalTo: rootView.leftAnchor),
				gradientView.rightAnchor.constraint(equalTo: fillView.leftAnchor),
				fillView.rightAnchor.constraint(equalTo: rootView.rightAnchor)
			])
		} else {
			constraints.append(contentsOf: [
				fillView.leftAnchor.constraint(equalTo: rootView.leftAnchor),
				fillView.rightAnchor.constraint(equalTo: gradientView.leftAnchor),
				gradientView.rightAnchor.constraint(equalTo: rootView.rightAnchor)
			])
		}

		NSLayoutConstraint.activate(constraints)

		return rootView
	}

	private var itemViews: [UIView] = []

	override open func setupSubviews() {
		super.setupSubviews()
		recreateAndLayoutItemViews()
	}

	func recreateAndLayoutItemViews() {
		// Remove existing views
		for itemView in itemViews {
			itemView.removeFromSuperview()
		}

		itemViews.removeAll()

		// Create new views
		for item in items {
			if let view = item.view {
				itemViews.append(view)
			}
		}

		// Embed
		embedHorizontally(views: itemViews, insets: insets, spacingProvider: { _, _ in
			return self.itemSpacing
		}, constraintsModifier: { constraintSet in
			// Implement truncation + masking
			var maskView: UIView?

			switch self.truncationMode {
				case .none: break

				case .clipTail:
					constraintSet.lastTrailingConstraint?.priority = .defaultHigh

				case .truncateHead:
					constraintSet.firstLeadingConstraint?.priority = .defaultHigh
					maskView = self.composeMaskView(leading: true)

				case .truncateTail:
					constraintSet.lastTrailingConstraint?.priority = .defaultHigh
					maskView = self.composeMaskView(leading: false)
			}

			if let maskView = maskView {
				maskView.translatesAutoresizingMaskIntoConstraints = false
				self.embed(toFillWith: maskView)
				self.mask = maskView
			}

			return constraintSet
		})
	}
}
