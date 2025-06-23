//
//  RecentLocationCell.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 21.05.25.
//  Copyright © 2025 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2025, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

class RecentLocationCell: UniversalItemListCell {
	override func prepareViews() {
		super.prepareViews()
		cssSelectors = [.recentLocation]
	}

	override func updateLayoutConstraints() {
		super.updateLayoutConstraints()

		// Limit title label to one line
		titleLabel.numberOfLines = 1

		// Add constraint to limit width
		let maxWidthConstraint = self.widthAnchor.constraint(lessThanOrEqualToConstant: 240)
		maxWidthConstraint.isActive = true // .. activate it ..

		// Clip contents to avoid very long account names spilling out of the cell
		clipsToBounds = true

		// .. and add it to self.cellConstraints
		var constraints = cellConstraints ?? []
		constraints.append(maxWidthConstraint)
		cellConstraints = constraints
	}

	override func updateConfiguration(using state: UICellConfigurationState) {
		super.updateConfiguration(using: state)

		let collection = Theme.shared.activeCollection
		var backgroundConfig = backgroundConfiguration?.updated(for: state)

		if state.isHighlighted || state.isSelected || (state.cellDropState == .targeted) {
			backgroundConfig?.backgroundColor = collection.css.getColor(.fill, state: [.highlighted], for: self)
		} else {
			backgroundConfig?.backgroundColor = collection.css.getColor(.fill, for: self)
		}

		backgroundConfig?.cornerRadius = 8

		backgroundConfiguration = backgroundConfig
	}
}

extension ThemeCSSSelector {
	static let recentLocation = ThemeCSSSelector(rawValue: "recentLocation")
}
