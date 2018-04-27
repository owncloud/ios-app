//
//  ThemeNavigationViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 11.04.18.
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

class ThemeNavigationController: UINavigationController {
	private var themeToken : ThemeApplierToken?

	override var preferredStatusBarStyle : UIStatusBarStyle {
		return Theme.shared.activeCollection.statusBarStyle
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		themeToken = Theme.shared.add(applier: { (_, themeCollection, event) in
			self.applyThemeCollection(themeCollection)
			self.toolbar.applyThemeCollection(themeCollection)

			if event == .update {
				self.setNeedsStatusBarAppearanceUpdate()
			}
		}, applyImmediately: true)
	}

	deinit {
		Theme.shared.remove(applierForToken: themeToken)
	}
}
