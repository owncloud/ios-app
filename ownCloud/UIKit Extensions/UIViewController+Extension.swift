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

        if let tabBarController = self.tabBarController {
            let tabBarHeight = tabBarController.tabBar.bounds.height
            UIView.animate(withDuration: TimeInterval(UINavigationController.hideShowBarDuration), animations: {
                tabBarController.tabBar.transform = CGAffineTransform(translationX: 0, y: tabBarHeight)
            }, completion: { (completed) in
                if completed {
                    tabBarController.tabBar.isHidden = true
                    self.navigationController?.toolbar.transform = CGAffineTransform(translationX: 0, y: tabBarHeight)
                    self.navigationController?.setToolbarItems(items, animated: false)
                    self.navigationController?.setToolbarHidden(false, animated: true)
                }
            })
        } else {
            self.navigationController?.setToolbarItems(items, animated: false)
            self.navigationController?.setToolbarHidden(false, animated: true)
        }
    }

    func removeToolbar() {
        self.navigationController?.setToolbarHidden(true, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(UINavigationController.hideShowBarDuration)) {
            self.navigationController?.setToolbarItems(nil, animated: false)
            if let tabBarController = self.tabBarController {
                tabBarController.tabBar.isHidden = false
                UIView.animate(withDuration: TimeInterval(UINavigationController.hideShowBarDuration), animations: {
                    tabBarController.tabBar.transform = .identity
                })
            }
        }
    }
}
