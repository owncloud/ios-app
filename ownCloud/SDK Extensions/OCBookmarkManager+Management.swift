//
//  OCBookmarkManager+Management.swift
//  ownCloud
//
//  Created by Felix Schwarz on 22.11.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudAppShared
import ownCloudSDK

extension OCBookmarkManager {
	public func manage(bookmark: OCBookmark, presentOn hostViewController: UIViewController, completion manageCompletion: (() -> Void)? = nil) {
		if !OCBookmarkManager.attemptLock(bookmark: bookmark, presentErrorOn: hostViewController, action: { bookmark, lockActionCompletion in
			let viewController = BookmarkInfoViewController(bookmark)
			viewController.completionHandler = {
				lockActionCompletion()
			}

			let navigationController : ThemeNavigationController = ThemeNavigationController(rootViewController: viewController)
			navigationController.modalPresentationStyle = .overFullScreen

			hostViewController.present(navigationController, animated: true, completion: {
				manageCompletion?()
			})
		}) {
			manageCompletion?()
		}
	}
}
