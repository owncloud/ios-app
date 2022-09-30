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
	typealias ConstraintsModifier = (_ constraintSet: HorizontalConstraintSet) -> HorizontalConstraintSet

	struct HorizontalConstraintSet {
		var firstLeadingConstraint: NSLayoutConstraint?
		var lastTrailingConstraint: NSLayoutConstraint?
	}

	@discardableResult func embedHorizontally(views: [UIView], insets: NSDirectionalEdgeInsets, spacingProvider: SpacingProvider? = nil, constraintsModifier: ConstraintsModifier? = nil) -> HorizontalConstraintSet {
		var viewIdx : Int = 0
		var previousView: UIView?
		var embedConstraints: [NSLayoutConstraint] = []

		var constraintSet: HorizontalConstraintSet = HorizontalConstraintSet()

		for view in views {
			var leadingConstraint: NSLayoutConstraint?

			// Create leading constraint
			if viewIdx == 0 {
				leadingConstraint = view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.leading)
				constraintSet.firstLeadingConstraint = leadingConstraint
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
				constraintSet.lastTrailingConstraint = trailingConstraint
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
