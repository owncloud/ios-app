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
import ownCloudSDK
import ownCloudAppShared

@objc(ShareNavigationController)
class ShareNavigationController: AppExtensionNavigationController {
	override func setupViewControllers() {
		if OCVault.hostHasFileProvider {
			self.setViewControllers([ShareViewController(style: .grouped)], animated: false)
		} else {
			let viewController = StaticTableViewController(style: .grouped)
			viewController.addSection(StaticTableViewSection(headerTitle: nil, rows: [
				StaticTableViewRow(message: "The share extension is not available on this system.".localized, title: "Share Extension unavailable".localized, icon: nil, tintIcon: false, style: .warning, titleMessageSpacing: 10, imageSpacing: 0, padding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10), identifier: "error-message")
			]))
			viewController.navigationItem.title = OCAppIdentity.shared.appDisplayName

			self.setViewControllers([viewController], animated: false)
		}
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
