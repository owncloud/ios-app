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
import ownCloudSDK

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // UIWindowScene delegate

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		if let windowScene = scene as? UIWindowScene {
			window = UIWindow(windowScene: windowScene)
			let serverListTableViewController = ServerListTableViewController(style: UITableView.Style.plain)
			serverListTableViewController.restorationIdentifier = "ServerListTableViewController"
			let navigationController = ThemeNavigationController(rootViewController: serverListTableViewController)
			navigationController.restorationIdentifier = "RootNC"

			if let activity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
				serverListTableViewController.continueFrom(activity: activity)
			}
/*
			if let activity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
				navigationController.restoreUserActivityState(activity)
			}
*/
			window?.rootViewController = navigationController
			window?.addSubview((navigationController.view)!)
			window?.makeKeyAndVisible()
		}
		print("--> scene delegagte \(connectionOptions.userActivities.first) \(session.stateRestorationActivity)")
        if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
			print("--> scene delegagte userActivity")
            if !configure(window: window, with: userActivity) {
                print("-->Failed to restore from \(userActivity)")
            }
        }
    }
/*
    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        return scene.userActivity
    }
*/

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        print("-->-->SceneDelegate stateRestorationActivity")
/*
        if let activity = window?.userActivity {
            activity.userInfo = [:]
            ((window?.rootViewController as? UINavigationController)?.viewControllers.first as? ClientRootViewController)?.updateUserActivityState(activity)

            return activity
        }*/
		if let nc = self.window?.rootViewController as? ThemeNavigationController, let vc = nc.viewControllers.first as? ServerListTableViewController {
			return vc.continuationActivity
		}

        return nil
    }

    // Utilities

    func configure(window: UIWindow?, with activity: NSUserActivity) -> Bool {
        if activity.title == ownCloudOpenAccountPath {
			print("-->--> configure activity.userInfo \(activity.userInfo)")
            if let bookmarkUUIDString = activity.userInfo?[ownCloudOpenAccountAccountUuidKey] as? String, let bookmarkUUID = UUID(uuidString: bookmarkUUIDString), let bookmark = OCBookmarkManager.shared.bookmark(for: bookmarkUUID) {
				print("-->--> configure \(bookmarkUUIDString)")


				if let navigationController = window?.rootViewController as? ThemeNavigationController, let serverListController = navigationController.topViewController as? ServerListTableViewController {
					serverListController.connect(to: bookmark)
					return true
				}
			}
		} else if activity.title == ownCloudOpenItemPath {

			if let navigationController = window?.rootViewController as? ThemeNavigationController {
				print("-->-->>>> \(navigationController.topViewController)")

			}
		}

        return false
    }

}
