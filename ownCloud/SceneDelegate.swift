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

	var window: ThemeWindow?

	// UIWindowScene delegate
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		if let windowScene = scene as? UIWindowScene {
			window = ThemeWindow(windowScene: windowScene)

			let serverListTableViewController = ServerListTableViewController(style: .plain)
			serverListTableViewController.restorationIdentifier = "ServerListTableViewController"

			let navigationController = ThemeNavigationController(rootViewController: serverListTableViewController)
			window?.rootViewController = navigationController
			window?.addSubview((navigationController.view)!)
			window?.makeKeyAndVisible()
		}

        if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
            if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
                OnMainThread {
                    self.scene(scene, continue: userActivity)
                }
            } else {
                configure(window: window, with: userActivity)
            }
        }
	}

	func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
		return scene.userActivity
	}

    @discardableResult func configure(window: ThemeWindow?, with activity: NSUserActivity) -> Bool {
		guard let bookmarkUUIDString = activity.userInfo?[ownCloudOpenAccountAccountUuidKey] as? String, let bookmarkUUID = UUID(uuidString: bookmarkUUIDString), let bookmark = OCBookmarkManager.shared.bookmark(for: bookmarkUUID), let navigationController = window?.rootViewController as? ThemeNavigationController, let serverListController = navigationController.topViewController as? ServerListTableViewController else {
			return false
		}

		if activity.title == ownCloudOpenAccountPath {
			serverListController.connect(to: bookmark, lastVisibleItemId: nil, animated: false)
			window?.windowScene?.userActivity = bookmark.openAccountUserActivity

			return true
		} else if activity.title == ownCloudOpenItemPath {
			guard let itemLocalID = activity.userInfo?[ownCloudOpenItemUuidKey] as? String else {
				return false
			}

			// At first connect to the bookmark for the item
			serverListController.connect(to: bookmark, lastVisibleItemId: itemLocalID, animated: false)
			window?.windowScene?.userActivity = activity

			return true
        }

		return false
	}

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let urlContext = URLContexts.first {
            if urlContext.url.scheme == "owncloud" {

				if urlContext.url.privateLinkItemID() != nil {
                    urlContext.url.retrieveLinkedItem(with: { (item, bookmark, _) in
                        if let itemID = item?.localID, let bookmark = bookmark, let windowScene = scene as? UIWindowScene {
                            windowScene.windows.first?.display(itemWithID: itemID, in: bookmark)
                        }
                    }, replaceScheme: true)
                }
            } else {
                ImportFilesController(url: urlContext.url, copyBeforeUsing: urlContext.options.openInPlace).accountUI()
            }
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL else {
                return
        }

        url.retrieveLinkedItem(with: { (item, bookmark, error) in

			guard let windowScene = scene as? UIWindowScene else { return }

			guard let window =  windowScene.windows.first else { return }

			if item == nil {
				let alert = UIAlertController.alertControllerForLinkResolution(error: error)
				window.rootViewController?.present(alert, animated: true)
			} else {
				if let itemID = item?.localID, let bookmark = bookmark {
					windowScene.windows.first?.display(itemWithID: itemID, in: bookmark)
				}
			}
        })
    }
}
