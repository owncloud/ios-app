//
//  ThemeCSSLabel.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 20.03.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

open class ThemeCSSLabel: UILabel, Themeable {
	private var _hasRegistered = false

	convenience public init(withSelectors: [ThemeCSSSelector]?) {
		self.init()
		cssSelectors = withSelectors
	}

	open override func didMoveToWindow() {
		super.didMoveToWindow()

		if window != nil, !_hasRegistered {
			_hasRegistered = true
			Theme.shared.register(client: self, applyImmediately: true)
		}
	}

	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		apply(css: collection.css, properties: [.stroke])

		if event == .initial {
			// For some reason, setting .textColor at the time the view moved to the window doesn't seem
			// to be sufficient during launch, so for the initial color setting perform the action once more
			// in the next runloop cycle
			OnMainThread {
				self.apply(css: collection.css, properties: [.stroke])
			}
		}
	}
}
