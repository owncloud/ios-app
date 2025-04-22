//
//  UIView+EmbedAndLayout.swift
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

public extension UIView {
	typealias SpacingProvider = (_ leadingView: UIView, _ trailingView: UIView) -> CGFloat?
	typealias ConstraintsModifier = (_ constraintSet: ConstraintSet) -> ConstraintSet

	struct ConstraintSet {
		public var firstLeadingOrTopConstraint: NSLayoutConstraint?
		public var lastTrailingOrBottomConstraint: NSLayoutConstraint?
	}

	struct AnchorSet {
		public var leadingAnchor: NSLayoutXAxisAnchor
		public var trailingAnchor: NSLayoutXAxisAnchor

		public var topAnchor: NSLayoutYAxisAnchor
		public var bottomAnchor: NSLayoutYAxisAnchor

		public var centerXAnchor: NSLayoutXAxisAnchor
		public var centerYAnchor: NSLayoutYAxisAnchor

		public init(leadingAnchor: NSLayoutXAxisAnchor, trailingAnchor: NSLayoutXAxisAnchor, topAnchor: NSLayoutYAxisAnchor, bottomAnchor: NSLayoutYAxisAnchor, centerXAnchor: NSLayoutXAxisAnchor, centerYAnchor: NSLayoutYAxisAnchor) {
			self.leadingAnchor = leadingAnchor
			self.trailingAnchor = trailingAnchor
			self.topAnchor = topAnchor
			self.bottomAnchor = bottomAnchor
			self.centerXAnchor = centerXAnchor
			self.centerYAnchor = centerYAnchor
		}
	}

	var defaultAnchorSet : AnchorSet {
		return AnchorSet(leadingAnchor: leadingAnchor, trailingAnchor: trailingAnchor, topAnchor: topAnchor, bottomAnchor: bottomAnchor, centerXAnchor: centerXAnchor, centerYAnchor: centerYAnchor)
	}

	var safeAreaAnchorSet : AnchorSet {
		return AnchorSet(leadingAnchor: safeAreaLayoutGuide.leadingAnchor, trailingAnchor: safeAreaLayoutGuide.trailingAnchor, topAnchor: safeAreaLayoutGuide.topAnchor, bottomAnchor: safeAreaLayoutGuide.bottomAnchor, centerXAnchor: safeAreaLayoutGuide.centerXAnchor, centerYAnchor: safeAreaLayoutGuide.centerYAnchor)
	}

	var safeAreaWithKeyboardAnchorSet : AnchorSet {
		return AnchorSet(leadingAnchor: safeAreaLayoutGuide.leadingAnchor, trailingAnchor: safeAreaLayoutGuide.trailingAnchor, topAnchor: safeAreaLayoutGuide.topAnchor, bottomAnchor: keyboardLayoutGuide.topAnchor, centerXAnchor: safeAreaLayoutGuide.centerXAnchor, centerYAnchor: safeAreaLayoutGuide.centerYAnchor)
	}

	@discardableResult func embedHorizontally(views: [UIView], insets: NSDirectionalEdgeInsets, enclosingAnchors: AnchorSet? = nil, limitHeight: Bool = false, spacingProvider: SpacingProvider? = nil, constraintsModifier: ConstraintsModifier? = nil) -> ConstraintSet {
		var viewIdx : Int = 0
		var previousView: UIView?
		var embedConstraints: [NSLayoutConstraint] = []

		var constraintSet: ConstraintSet = ConstraintSet()
		let anchorSet = enclosingAnchors ?? defaultAnchorSet

		for view in views {
			var leadingConstraint: NSLayoutConstraint?

			// Create leading constraint
			if viewIdx == 0 {
				leadingConstraint = view.leadingAnchor.constraint(equalTo: anchorSet.leadingAnchor, constant: insets.leading)
				constraintSet.firstLeadingOrTopConstraint = leadingConstraint
			} else if let previousView = previousView {
				let spacing : CGFloat = spacingProvider?(previousView, view) ?? 0
				leadingConstraint = view.leadingAnchor.constraint(equalTo: previousView.trailingAnchor, constant: spacing)
			}

			// Add constraints
			// - leading
			if let leadingConstraint = leadingConstraint {
				embedConstraints.append(leadingConstraint)
			}

			// - vertical position + insets
			embedConstraints.append(contentsOf: [
				view.centerYAnchor.constraint(equalTo: anchorSet.centerYAnchor),
				view.topAnchor.constraint(greaterThanOrEqualTo: anchorSet.topAnchor, constant: insets.top),
				view.bottomAnchor.constraint(lessThanOrEqualTo: anchorSet.bottomAnchor, constant: -insets.bottom)
			])

			if limitHeight {
				// Add top/bottom constraints with stricter requirements, but with lower priority, nudging the layout engine to a more compact layout
				embedConstraints.append(contentsOf: [
					view.topAnchor.constraint(equalTo: anchorSet.topAnchor, constant: insets.top).with(priority: .defaultHigh),
					view.bottomAnchor.constraint(equalTo: anchorSet.bottomAnchor, constant: -insets.bottom).with(priority: .defaultHigh)
				])
			}

			// - trailing
			if viewIdx == (views.count-1) {
				let trailingConstraint = view.trailingAnchor.constraint(equalTo: anchorSet.trailingAnchor, constant: -insets.trailing)
				constraintSet.lastTrailingOrBottomConstraint = trailingConstraint
				embedConstraints.append(trailingConstraint)
			}

			// Add subview
			addSubview(view)

			previousView = view
			viewIdx += 1
		}

		// Modify constraints
		if let constraintsModifier = constraintsModifier {
			constraintSet = constraintsModifier(constraintSet)
		}

		// Activate constraints
		NSLayoutConstraint.activate(embedConstraints)

		return constraintSet
	}

	@discardableResult func embedVertically(views: [UIView], insets: NSDirectionalEdgeInsets, enclosingAnchors: AnchorSet? = nil, spacingProvider: SpacingProvider? = nil, centered: Bool = true, constraintsModifier: ConstraintsModifier? = nil) -> ConstraintSet {
		var viewIdx : Int = 0
		var previousView: UIView?
		var embedConstraints: [NSLayoutConstraint] = []

		var constraintSet: ConstraintSet = ConstraintSet()
		let anchorSet = enclosingAnchors ?? defaultAnchorSet

		for view in views {
			var topConstraint: NSLayoutConstraint?

			// Create top constraint
			if viewIdx == 0 {
				topConstraint = view.topAnchor.constraint(equalTo: anchorSet.topAnchor, constant: insets.top)
				constraintSet.firstLeadingOrTopConstraint = topConstraint
			} else if let previousView = previousView {
				let spacing : CGFloat = spacingProvider?(previousView, view) ?? 0
				topConstraint = view.topAnchor.constraint(equalTo: previousView.bottomAnchor, constant: spacing)
			}

			// Add constraints
			// - top
			if let topConstraint = topConstraint {
				embedConstraints.append(topConstraint)
			}

			// - horizontal position + insets
			if centered {
				embedConstraints.append(contentsOf: [
					view.centerXAnchor.constraint(equalTo: anchorSet.centerXAnchor),
					view.leadingAnchor.constraint(greaterThanOrEqualTo: anchorSet.leadingAnchor, constant: insets.leading),
					view.trailingAnchor.constraint(lessThanOrEqualTo: anchorSet.trailingAnchor, constant: -insets.trailing)
				])
			} else {
				embedConstraints.append(contentsOf: [
					view.leadingAnchor.constraint(equalTo: anchorSet.leadingAnchor, constant: insets.leading),
					view.trailingAnchor.constraint(equalTo: anchorSet.trailingAnchor, constant: -insets.trailing)
				])
			}

			// - bottom
			if viewIdx == (views.count-1) {
				let bottomConstraint = view.bottomAnchor.constraint(equalTo: anchorSet.bottomAnchor, constant: -insets.bottom)
				constraintSet.lastTrailingOrBottomConstraint = bottomConstraint
				embedConstraints.append(bottomConstraint)
			}

			// Add subview
			addSubview(view)

			previousView = view
			viewIdx += 1
		}

		// Modify constraints
		if let constraintsModifier = constraintsModifier {
			constraintSet = constraintsModifier(constraintSet)
		}

		// Activate constraints
		NSLayoutConstraint.activate(embedConstraints)

		return constraintSet
	}

	@discardableResult func embed(toFillWith view: UIView, insets: NSDirectionalEdgeInsets = .zero, enclosingAnchors: AnchorSet? = nil) -> [NSLayoutConstraint] {
		view.translatesAutoresizingMaskIntoConstraints = false

		addSubview(view)

		var constraints : [NSLayoutConstraint]
		let anchorSet = enclosingAnchors ?? defaultAnchorSet

		constraints = [
			view.leadingAnchor.constraint(equalTo: anchorSet.leadingAnchor, constant: insets.leading),
			view.trailingAnchor.constraint(equalTo: anchorSet.trailingAnchor, constant: -insets.trailing),
			view.topAnchor.constraint(equalTo: anchorSet.topAnchor, constant: insets.top),
			view.bottomAnchor.constraint(equalTo: anchorSet.bottomAnchor, constant: -insets.bottom)
		]

		NSLayoutConstraint.activate(constraints)

		return constraints
	}

	@discardableResult func embed(centered view: UIView, minimumInsets insets: NSDirectionalEdgeInsets = .zero, fixedSize: CGSize? = nil, minimumSize: CGSize? = nil, maximumSize: CGSize? = nil, enclosingAnchors: AnchorSet? = nil, constraintsOnly: Bool = false) -> [NSLayoutConstraint] {
		if !constraintsOnly {
			view.translatesAutoresizingMaskIntoConstraints = false

			addSubview(view)
		}

		var constraints: [NSLayoutConstraint]
		let anchorSet = enclosingAnchors ?? defaultAnchorSet

		constraints = [
			view.leadingAnchor.constraint(greaterThanOrEqualTo: anchorSet.leadingAnchor, constant: insets.leading),
			view.trailingAnchor.constraint(lessThanOrEqualTo: anchorSet.trailingAnchor, constant: -insets.trailing),
			view.topAnchor.constraint(greaterThanOrEqualTo: anchorSet.topAnchor, constant: insets.top),
			view.bottomAnchor.constraint(lessThanOrEqualTo: anchorSet.bottomAnchor, constant: -insets.bottom),
			view.centerXAnchor.constraint(equalTo: anchorSet.centerXAnchor),
			view.centerYAnchor.constraint(equalTo: anchorSet.centerYAnchor)
		]

		if let fixedSize {
			constraints += [
				view.widthAnchor.constraint(equalToConstant: fixedSize.width).with(priority: .defaultHigh),
				view.heightAnchor.constraint(equalToConstant: fixedSize.height).with(priority: .defaultHigh)
			]
		}

		if let minimumSize {
			constraints += [
				view.widthAnchor.constraint(greaterThanOrEqualToConstant: minimumSize.width),
				view.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumSize.height)
			]
		}

		if let maximumSize {
			constraints += [
				view.widthAnchor.constraint(lessThanOrEqualToConstant: maximumSize.width),
				view.heightAnchor.constraint(lessThanOrEqualToConstant: maximumSize.height)
			]
		}

		if !constraintsOnly {
			NSLayoutConstraint.activate(constraints)
		}

		return constraints
	}
}
