//
//  ThemeView.swift
//  ownCloud
//
//  Created by Felix Schwarz on 27.11.18.
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

open class ThemeView: ThemeCSSView {
	// Important implementation difference: ThemeCSSView makes the initial themeing calls only when moved to a window (=> becomes part of visible view hiearchy), ThemeView did this when moved to a subview (=> may still be in view setup)
	private var hasSetupSubviews = false

	override open func didMoveToSuperview() {
		super.didMoveToSuperview()

		if self.superview != nil {
			if !hasSetupSubviews {
				hasSetupSubviews = true
				setupSubviews()
			}
		}
	}

	open func setupSubviews() {
		// Override point for subclasses
		// Themeing is performed at a later time, when moved into a visible view tree (window)
	}
}
