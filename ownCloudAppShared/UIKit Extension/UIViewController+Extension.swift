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

public extension UIViewController {

	var topMostViewController: UIViewController {

		if let presented = self.presentedViewController, presented.isBeingDismissed == false {
			 return presented.topMostViewController
		 }

		 if let navigation = self as? UINavigationController {
			 return navigation.visibleViewController?.topMostViewController ?? navigation
		 }

		 if let tab = self as? UITabBarController {
			 return tab.selectedViewController?.topMostViewController ?? tab
		 }

		 return self
	 }

	@objc @discardableResult func openURL(_ url: URL) -> Bool {
		var responder: UIResponder? = self.navigationController
		while responder != nil {
			if let application = responder as? UIApplication {
				return application.perform(#selector(openURL(_:)), with: url) != nil
			}
			responder = responder?.next
		}
		return true
	}
}
