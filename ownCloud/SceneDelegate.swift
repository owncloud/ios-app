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
import ownCloudAppShared

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: ThemeWindow?

	// UIWindowScene delegate
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		if let windowScene = scene as? UIWindowScene {
			window = ThemeWindow(windowScene: windowScene)
			var navigationController: UINavigationController?

			if VendorServices.shared.isBranded, VendorServices.shared.hasBrandedLogin {
				let staticLoginViewController = StaticLoginViewController(with: StaticLoginBundle.defaultBundle)
				navigationController = ThemeNavigationController(rootViewController: staticLoginViewController)
				navigationController?.setNavigationBarHidden(true, animated: false)
			} else {
				let serverListTableViewController = ServerListTableViewController(style: .plain)
				serverListTableViewController.restorationIdentifier = "ServerListTableViewController"

				navigationController = ThemeNavigationController(rootViewController: serverListTableViewController)
			}
			window?.rootViewController = navigationController
			window?.addSubview((navigationController!.view)!)
			window?.makeKeyAndVisible()
		}

		// Was the app launched with registered URL scheme?
		if let urlContext = connectionOptions.urlContexts.first {
			if urlContext.url.matchesAppScheme {
				openPrivateLink(url: urlContext.url, in: scene)
			}
		} else  if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
			if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
				OnMainThread {
					self.scene(scene, continue: userActivity)
				}
			} else {
				configure(window: window, with: userActivity)
			}
		}
	}

	private func set(scene: UIScene, inForeground: Bool) {
		if let windowScene = scene as? UIWindowScene {
			for window in windowScene.windows {
				if let themeWindow = window as? ThemeWindow {
					themeWindow.themeWindowInForeground = true
				}
			}
		}
	}

	func sceneWillEnterForeground(_ scene: UIScene) {
		self.set(scene: scene, inForeground: true)
	}

	func sceneDidEnterBackground(_ scene: UIScene) {
		self.set(scene: scene, inForeground: false)
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
			if urlContext.url.matchesAppScheme {
				openPrivateLink(url: urlContext.url, in: scene)
            }
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL else {
                return
        }

		guard let windowScene = scene as? UIWindowScene else { return }

		guard let window =  windowScene.windows.first else { return }

		url.resolveAndPresent(in: window)
    }

	private func openPrivateLink(url:URL, in scene:UIScene?) {
		if url.privateLinkItemID() != nil {

			guard let windowScene = scene as? UIWindowScene else { return }

			guard let window =  windowScene.windows.first else { return }

			url.resolveAndPresent(in: window)
		}
	}
}
