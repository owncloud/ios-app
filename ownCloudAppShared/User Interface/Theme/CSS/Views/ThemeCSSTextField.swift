//
//  ThemeCSSTextField.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 27.03.23.
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

public class ThemeCSSTextField: UITextField, Themeable {
	private var hasRegistered : Bool = false

	override open func didMoveToWindow() {
		super.didMoveToWindow()

		if window != nil, !hasRegistered {
			hasRegistered = true
			Theme.shared.register(client: self, applyImmediately: true)
		}
	}

	override open var isEnabled: Bool {
		didSet {
			if hasRegistered {
				applyThemeCollection(theme: Theme.shared, collection: Theme.shared.activeCollection, event: .update)
			}
		}
	}

	open func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.applyThemeCollection(collection)
	}
}
