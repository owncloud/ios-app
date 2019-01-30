//
//  UIViewController+Extension.swift
//  ownCloud
//
//  Created by Michael Neuwert on 23.01.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit

extension UIViewController {
    func populateToolbar(with items:[UIBarButtonItem]) {

        if let tabBarController = self.tabBarController as? ClientRootViewController {
            tabBarController.toolbar?.isHidden = false
            tabBarController.tabBar.bringSubviewToFront(tabBarController.toolbar!)
            tabBarController.toolbar?.setItems(items, animated: true)
        }
    }

    func removeToolbar() {
        if let tabBarController = self.tabBarController as? ClientRootViewController {
            tabBarController.toolbar?.isHidden = true
            tabBarController.toolbar?.setItems(nil, animated: true)
        }
    }
}
