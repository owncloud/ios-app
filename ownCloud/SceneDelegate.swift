//
//  SceneDelegate.swift
//  ownCloud
//
//  Created by Matthias Hühne on 08/05/2018.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
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

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // UIWindowScene delegate

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
            if !configure(window: window, with: userActivity) {
                print("Failed to restore from \(userActivity)")
            }
        }
		if let windowScene = scene as? UIWindowScene {
			window = UIWindow(windowScene: windowScene)
			let serverListTableViewController = ServerListTableViewController(style: UITableView.Style.plain)
			let navigationController = ThemeNavigationController(rootViewController: serverListTableViewController)

			window?.rootViewController = navigationController
			window?.addSubview((navigationController.view)!)
			window?.makeKeyAndVisible()
		}
    }

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        return scene.userActivity
    }

    // Utilities

    func configure(window: UIWindow?, with activity: NSUserActivity) -> Bool {
		/*
        if activity.title == GalleryOpenDetailPath {
            if let photoID = activity.userInfo?[GalleryOpenDetailPhotoIdKey] as? String {
                
                if let photoDetailViewController = PhotoDetailViewController.loadFromStoryboard() {
                    photoDetailViewController.photo = Photo(name: photoID)
                    
                    if let navigationController = window?.rootViewController as? UINavigationController {
                        navigationController.pushViewController(photoDetailViewController, animated: false)
                        return true
                    }
                }
            }
        }*/
        return false
    }

}
