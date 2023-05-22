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

extension ThemeCSSSelector {
	static let segments = ThemeCSSSelector(rawValue: "segments")
}

public class SegmentView: ThemeView, ThemeCSSAutoSelector {
	public let cssAutoSelectors: [ThemeCSSSelector] = [.segments]

	public enum TruncationMode {
		case none
		case clipTail
		case truncateHead
		case truncateTail
	}

 	open var items: [SegmentViewItem] {
		willSet {
			for item in items {
				item.segmentView = nil
			}
		}

 		didSet {
 			if superview != nil {
				recreateAndLayoutItemViews()
			}
		}
	}
 	open var itemSpacing: CGFloat = 5
 	open var truncationMode: TruncationMode = .none
 	open var insets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
 	open var limitVerticalSpaceUsage: Bool = false

	private var isScrollable: Bool

	public init(with items: [SegmentViewItem], truncationMode: TruncationMode, scrollable: Bool = false, limitVerticalSpaceUsage: Bool = false) {
		isScrollable = scrollable
		self.limitVerticalSpaceUsage = limitVerticalSpaceUsage

		self.items = items

		super.init()

		self.truncationMode = truncationMode
		isOpaque = false
	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func gradientColors(fadeInFromLeft: Bool, baseColor: CGColor? = nil) -> [CGColor] {
		var gradientColors: [CGColor] = [
			CGColor(red: 0, green: 0, blue: 0, alpha: fadeInFromLeft ? 0.0 : 1.0),
			CGColor(red: 0, green: 0, blue: 0, alpha: fadeInFromLeft ? 1.0 : 0.0)
		]

		if let startColor = baseColor?.copy(alpha: fadeInFromLeft ? 0.0 : 1.0),
		   let endColor   = baseColor?.copy(alpha: fadeInFromLeft ? 1.0 : 0.0) {
			gradientColors = [ startColor, endColor ]
		}

		return gradientColors
	}

	func gradientView(fadeInFromLeft: Bool, baseColor: CGColor? = nil) -> GradientView {
		let gradientColors = gradientColors(fadeInFromLeft: fadeInFromLeft, baseColor: baseColor)
		let gradientWidth : CGFloat = 20
		let gradientView = GradientView(with: gradientColors, locations: [0, 1], direction: .horizontal)

		gradientView.translatesAutoresizingMaskIntoConstraints = false
		gradientView.widthAnchor.constraint(equalToConstant: gradientWidth).isActive = true

		return gradientView
	}

	func composeMaskView(leading: Bool) -> UIView {
		let fadeInFromLeft: Bool = (effectiveUserInterfaceLayoutDirection == .leftToRight) ? leading : !leading
		let rootView = UIView(frame: bounds)
		let fillView = UIView()
		let gradientView = gradientView(fadeInFromLeft: fadeInFromLeft)

		fillView.backgroundColor = .black

		fillView.translatesAutoresizingMaskIntoConstraints = false

		var constraints: [NSLayoutConstraint] = [
			fillView.topAnchor.constraint(equalTo: rootView.topAnchor),
			fillView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
			gradientView.topAnchor.constraint(equalTo: rootView.topAnchor),
			gradientView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor)
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
	private var borderMaskView: UIView?
	private var scrollView: UIScrollView?
	private var scrollGradientLeft: GradientView?
	private var scrollGradientRight: GradientView?
	private var scrollViewContentOffset: NSKeyValueObservation?
	public var scrollViewOverlayGradientColor: CGColor? {
		didSet {
			scrollGradientLeft?.colors = gradientColors(fadeInFromLeft: false, baseColor: scrollViewOverlayGradientColor)
			scrollGradientRight?.colors = gradientColors(fadeInFromLeft: true, baseColor: scrollViewOverlayGradientColor)
		}
	}

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
			item.segmentView = self

			if let view = item.view {
				itemViews.append(view)
			}
		}

		// Scroll View
		var hostView: UIView = self

		if isScrollable, scrollView == nil {
			scrollView = UIScrollView(frame: .zero)
			scrollView?.showsVerticalScrollIndicator = false
			scrollView?.showsHorizontalScrollIndicator = false
			scrollView?.translatesAutoresizingMaskIntoConstraints = false

			scrollGradientLeft = gradientView(fadeInFromLeft: false, baseColor: scrollViewOverlayGradientColor)
			scrollGradientRight = gradientView(fadeInFromLeft: true, baseColor: scrollViewOverlayGradientColor)

			if let scrollView {
				hostView = scrollView

				embed(toFillWith: scrollView)
			}

			if let scrollGradientLeft, let scrollGradientRight {
				addSubview(scrollGradientLeft)
				addSubview(scrollGradientRight)

				NSLayoutConstraint.activate([
					scrollGradientLeft.leftAnchor.constraint(equalTo: self.leftAnchor),
					scrollGradientLeft.topAnchor.constraint(equalTo: self.topAnchor),
					scrollGradientLeft.bottomAnchor.constraint(equalTo: self.bottomAnchor),

					scrollGradientRight.rightAnchor.constraint(equalTo: self.rightAnchor),
					scrollGradientRight.topAnchor.constraint(equalTo: self.topAnchor),
					scrollGradientRight.bottomAnchor.constraint(equalTo: self.bottomAnchor)
				])
			}

			scrollViewContentOffset = scrollView?.observe(\.contentOffset, options: .initial, changeHandler: { [weak self] scrollView, _ in
				let bounds = scrollView.bounds
				let contentSize = scrollView.contentSize
				let contentOffset = scrollView.contentOffset

				if let scrollGradientLeft = self?.scrollGradientLeft {
					scrollGradientLeft.isHidden = !(contentOffset.x > 0)
				}

				if let scrollGradientRight = self?.scrollGradientRight {
					scrollGradientRight.isHidden = !(contentSize.width - contentOffset.x > bounds.width)
				}
			})
		}

		// Embed
		hostView.embedHorizontally(views: itemViews, insets: insets, limitHeight: limitVerticalSpaceUsage, spacingProvider: { _, _ in
			return self.itemSpacing
		}, constraintsModifier: { constraintSet in
			// Implement truncation + masking
			var maskView: UIView?

			switch self.truncationMode {
				case .none: break

				case .clipTail:
					constraintSet.lastTrailingOrBottomConstraint?.priority = .defaultHigh

				case .truncateHead:
					if !self.isScrollable {
						constraintSet.firstLeadingOrTopConstraint?.priority = .defaultHigh
						maskView = self.composeMaskView(leading: true)
					}

				case .truncateTail:
					if !self.isScrollable {
						constraintSet.lastTrailingOrBottomConstraint?.priority = .defaultHigh
						maskView = self.composeMaskView(leading: false)
					}
			}

			if let maskView = maskView {
				maskView.translatesAutoresizingMaskIntoConstraints = false
				self.borderMaskView = maskView
				self.embed(toFillWith: maskView)
				self.mask = maskView
			}

			return constraintSet
		})

		// Layout without animation
		UIView.performWithoutAnimation {
			layoutIfNeeded()

			if isScrollable {
				scrollToTruncationTarget()
			}
		}
	}

	func scrollToTruncationTarget() {
		switch truncationMode {
			case .truncateTail:
				if let contentWidth = scrollView?.contentSize.width {
					scrollView?.scrollRectToVisible(CGRect(x: contentWidth-1, y: 0, width: 1, height: 1), animated: false)
				}

			case .truncateHead:
				scrollView?.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)

			default: break
		}
	}

//	private var allViewsFullyVisible: Bool = false {
//		didSet {
//			if allViewsFullyVisible != oldValue, let borderMaskView {
//				if allViewsFullyVisible {
//					borderMaskView.removeFromSuperview()
//					mask = nil
//				} else {
////					embed(toFillWith: borderMaskView)
////					mask = borderMaskView
//				}
//			}
//		}
//	}
//
//	private func evaluateBorderMaskNecessity() {
//		if borderMaskView != nil, !isScrollable {
//			if let lastViewFrame = items.last?.view?.frame,
//			   let firstViewFrame = items.first?.view?.frame {
//				let bounds = bounds
//
//				if firstViewFrame.origin.x >= bounds.origin.x,
//				   (lastViewFrame.origin.x + lastViewFrame.size.width) <= (bounds.origin.x + bounds.size.width) {
//					allViewsFullyVisible = true
//				} else {
//					allViewsFullyVisible = false
//				}
//			}
//		}
//	}
//
//	public override func didMoveToWindow() {
//		super.didMoveToWindow()
//
//		OnMainThread {
//			self.evaluateBorderMaskNecessity()
//		}
//	}
//
//	public override func layoutSubviews() {
//		super.layoutSubviews()
//		self.evaluateBorderMaskNecessity()
//	}

	public override var bounds: CGRect {
		didSet {
			OnMainThread {
				self.scrollToTruncationTarget()
				// self.evaluateBorderMaskNecessity()
			}
		}
	}
}
