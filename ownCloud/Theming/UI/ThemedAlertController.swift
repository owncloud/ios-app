//
//  ThemedAlertController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 30.09.19.
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

class ThemedAlertController: UIAlertController, Themeable {
	private var themeRegistered : Bool = false

	override func viewWillAppear(_ animated: Bool) {
		Theme.shared.register(client: self, applyImmediately: true)
		super.viewWillAppear(animated)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		if #available(iOS 13, *) {
			self.overrideUserInterfaceStyle  = collection.interfaceStyle.userInterfaceStyle
		}
	}

	deinit {
		Theme.shared.unregister(client: self)
	}
}
