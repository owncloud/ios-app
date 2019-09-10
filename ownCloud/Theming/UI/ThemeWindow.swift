//
//  ThemeWindow.swift
//  ownCloud
//
//  Created by Felix Schwarz on 28.08.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

class ThemeWindow : UIWindow {
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)

		if #available(iOS 13.0, *) {
			if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
				ThemeStyle.considerAppearanceUpdate()
			}
		}
	}
}
