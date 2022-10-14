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
		var firstLeadingOrTopConstraint: NSLayoutConstraint?
		var lastTrailingOrBottomConstraint: NSLayoutConstraint?
	}

	@discardableResult func embedHorizontally(views: [UIView], insets: NSDirectionalEdgeInsets, spacingProvider: SpacingProvider? = nil, constraintsModifier: ConstraintsModifier? = nil) -> ConstraintSet {
		var viewIdx : Int = 0
		var previousView: UIView?
		var embedConstraints: [NSLayoutConstraint] = []

		var constraintSet: ConstraintSet = ConstraintSet()

		for view in views {
			var leadingConstraint: NSLayoutConstraint?

			// Create leading constraint
			if viewIdx == 0 {
				leadingConstraint = view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.leading)
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
				view.centerYAnchor.constraint(equalTo: centerYAnchor),
				view.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: insets.top),
				view.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -insets.bottom)
			])

			// - trailing
			if viewIdx == (views.count-1) {
				let trailingConstraint = view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.trailing)
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

	@discardableResult func embedVertically(views: [UIView], insets: NSDirectionalEdgeInsets, spacingProvider: SpacingProvider? = nil, constraintsModifier: ConstraintsModifier? = nil) -> ConstraintSet {
		var viewIdx : Int = 0
		var previousView: UIView?
		var embedConstraints: [NSLayoutConstraint] = []

		var constraintSet: ConstraintSet = ConstraintSet()

		for view in views {
			var topConstraint: NSLayoutConstraint?

			// Create top constraint
			if viewIdx == 0 {
				topConstraint = view.topAnchor.constraint(equalTo: topAnchor, constant: insets.top)
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
			embedConstraints.append(contentsOf: [
				view.centerXAnchor.constraint(equalTo: centerXAnchor),
				view.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: insets.leading),
				view.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -insets.trailing)
			])

			// - bottom
			if viewIdx == (views.count-1) {
				let bottomConstraint = view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom)
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

	func embed(toFillWith view: UIView, insets: NSDirectionalEdgeInsets = .zero) {
		view.translatesAutoresizingMaskIntoConstraints = false

		addSubview(view)

		NSLayoutConstraint.activate([
			view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.leading),
			view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.trailing),
			view.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
			view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom)
		])
	}
}
