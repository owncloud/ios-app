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
			window?.rootViewController = navigationController
			window?.addSubview((navigationController.view)!)
			window?.makeKeyAndVisible()
		}

		if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
			if !configure(window: window, with: userActivity) {
			}
		}
	}

	func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
		return scene.userActivity
	}

	func configure(window: UIWindow?, with activity: NSUserActivity) -> Bool {
		if activity.title == ownCloudOpenAccountPath {
			if let bookmarkUUIDString = activity.userInfo?[ownCloudOpenAccountAccountUuidKey] as? String, let bookmarkUUID = UUID(uuidString: bookmarkUUIDString), let bookmark = OCBookmarkManager.shared.bookmark(for: bookmarkUUID) {
				if let navigationController = window?.rootViewController as? ThemeNavigationController, let serverListController = navigationController.topViewController as? ServerListTableViewController {
					serverListController.connect(to: bookmark, animated: false) { (_, _) in
					}
					window?.windowScene?.userActivity = bookmark.openAccountUserActivity
					return true
				}
			}
		} else if activity.title == ownCloudOpenItemPath {
			if let itemLocalID = activity.userInfo?[ownCloudOpenItemUuidKey] as? String, let bookmarkUUIDString = activity.userInfo?[ownCloudOpenAccountAccountUuidKey] as? String, let bookmarkUUID = UUID(uuidString: bookmarkUUIDString), let bookmark = OCBookmarkManager.shared.bookmark(for: bookmarkUUID) {
				if let navigationController = window?.rootViewController as? ThemeNavigationController, let serverListController = navigationController.topViewController as? ServerListTableViewController {

					serverListController.connect(to: bookmark, animated: false) { (completed, clientRootViewController) in
						if completed, let clientViewController = clientRootViewController.filesNavigationController?.topViewController as? ClientQueryViewController, let core = clientRootViewController.core {
							core.retrieveItemFromDatabase(forLocalID: itemLocalID, completionHandler: { (error, _, item) in
								if error == nil, let item = item {
									OnMainThread {
										var parentItems = core.retrieveParentItems(for: item)
										if parentItems.count > 0 {
											parentItems.removeFirst()
										}
										var subController = clientViewController
										for item in parentItems {
											if let controller = self.open(item: item, in: subController) {
												subController = controller
											}
										}
										subController.open(item: item, animated: false)
									}
								}
							})
						}
					}
					window?.windowScene?.userActivity = activity

					return true
				}
			}
		}

		return false
	}

	func open(item: OCItem, in controller: ClientQueryViewController) -> ClientQueryViewController? {
		if let subController = controller.open(item: item, animated: false) {
			return subController
		}

		return nil
	}

}
