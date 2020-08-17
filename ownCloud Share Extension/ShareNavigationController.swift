//
//  ShareNavigationController.swift
//  ownCloud Share Extension
//
//  Created by Matthias Hühne on 10.03.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2020, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudAppShared

@objc(ShareNavigationController)
class ShareNavigationController: AppExtensionNavigationController {
	override func setupViewControllers() {
		self.setViewControllers([ShareViewController(style: .grouped)], animated: false)
	}
}

extension UserInterfaceContext : UserInterfaceContextProvider {
	public func provideRootView() -> UIView? {
		return AppExtensionNavigationController.mainNavigationController?.view
	}

	public func provideCurrentWindow() -> UIWindow? {
		return AppExtensionNavigationController.mainNavigationController?.view.window
	}
}
