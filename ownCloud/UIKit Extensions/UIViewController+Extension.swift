//
//  UIViewController+Extension.swift
//  ownCloud
//
//  Created by Michael Neuwert on 23.01.2019.
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

extension UIViewController {
	func populateToolbar(with items:[UIBarButtonItem]) {
		if let tabBarController = self.tabBarController as? ClientRootViewController {
			tabBarController.toolbar?.isHidden = false
			tabBarController.tabBar.isHidden = true
			tabBarController.toolbar?.setItems(items, animated: true)
		}
	}

	func removeToolbar() {
		if let tabBarController = self.tabBarController as? ClientRootViewController {
			tabBarController.toolbar?.isHidden = true
			tabBarController.tabBar.isHidden = false
			tabBarController.toolbar?.setItems(nil, animated: true)
		}
	}

	func topMostViewController() -> UIViewController {

		 if let presented = self.presentedViewController {
			 return presented.topMostViewController()
		 }

		 if let navigation = self as? UINavigationController {
			 return navigation.visibleViewController?.topMostViewController() ?? navigation
		 }

		 if let tab = self as? UITabBarController {
			 return tab.selectedViewController?.topMostViewController() ?? tab
		 }

		 return self
	 }
}
