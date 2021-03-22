//
//  UIWindow+Extension.swift
//  ownCloud
//
//  Created by Michael Neuwert on 31.01.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
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
import ownCloudSDK
import ownCloudAppShared

extension UIWindow {
    func display(itemWithID Identifier:String, in bookmark:OCBookmark) {
        if let rootViewController = self.rootViewController as? ThemeNavigationController {
            rootViewController.popToRootViewController(animated: false)
            if let serverListController = rootViewController.topViewController as? ServerListTableViewController {
                if serverListController.presentedViewController != nil {
                    serverListController.dismiss(animated: false, completion: {
                        serverListController.connect(to: bookmark, lastVisibleItemId: Identifier, animated: false)
                    })
                } else {
                    serverListController.connect(to: bookmark, lastVisibleItemId: Identifier, animated: false)
                }
            }
        }
    }
}
