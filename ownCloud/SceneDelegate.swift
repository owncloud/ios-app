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
		// Set up HTTP pipelines
		OCHTTPPipelineManager.setupPersistentPipelines()
		
		if let windowScene = scene as? UIWindowScene {
			window = ThemeWindow(windowScene: windowScene)
			var navigationController: UINavigationController?

			if VendorServices.shared.isBranded {
				let staticLoginViewController = StaticLoginViewController(with: StaticLoginBundle.defaultBundle)
				navigationController = ThemeNavigationController(rootViewController: staticLoginViewController)
				navigationController?.setNavigationBarHidden(true, animated: false)
			} else {
				var serverListTableViewController : ServerListTableViewController?
				if OCBookmarkManager.shared.bookmarks.count == 1 {
					serverListTableViewController = StaticLoginSingleAccountServerListViewController(style: .insetGrouped)
				} else {
					serverListTableViewController = ServerListTableViewController(style: .plain)
				}

				guard let serverListTableViewController = serverListTableViewController else { return }

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
			} else {
				ImportFilesController.shared.importFile(ImportFile(url: urlContext.url, fileIsLocalCopy: urlContext.options.openInPlace))
			}
		} else  if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
			if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
				OnMainThread {
					self.scene(scene, continue: userActivity)
				}
			} else {
				configure(window: window, with: userActivity)
			}
		} else if ServerListTableViewController.classSetting(forOCClassSettingsKey: .accountAutoConnect) as? Bool ?? false, let bookmark = OCBookmarkManager.shared.bookmarks.first {
			connect(to: bookmark)
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
		if let bookmarkUUIDString = activity.userInfo?[OCBookmark.ownCloudOpenAccountAccountUuidKey] as? String,
		   let bookmarkUUID = UUID(uuidString: bookmarkUUIDString),
		   let bookmark = OCBookmarkManager.shared.bookmark(for: bookmarkUUID) {
			if activity.title == OCBookmark.ownCloudOpenAccountPath {
				connect(to: bookmark)

				return true
			} else if activity.title == OpenItemUserActivity.ownCloudOpenItemPath {
				guard let itemLocalID = activity.userInfo?[OpenItemUserActivity.ownCloudOpenItemUuidKey] as? String else {
					return false
				}

				// At first connect to the bookmark for the item
				connect(to: bookmark, lastVisibleItemId: itemLocalID, activity: activity)

				return true
			}
		} else if activity.activityType == ServerListTableViewController.showServerListActivityType {
			// Show server list
			window?.windowScene?.userActivity = activity

			return true
		}

		return false
	}

	func connect(to bookmark: OCBookmark, lastVisibleItemId: String? = nil, activity: NSUserActivity? = nil) {
		if let navigationController = window?.rootViewController as? ThemeNavigationController,
		   let serverListController = navigationController.topViewController as? StateRestorationConnectProtocol {
			serverListController.connect(to: bookmark, lastVisibleItemId: lastVisibleItemId, animated: false, present: nil)
			window?.windowScene?.userActivity = activity ?? bookmark.openAccountUserActivity
		}
	}

	func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		if let firstURL = URLContexts.first?.url { // Ensure the set isn't empty
			if !OCAuthenticationBrowserSessionCustomScheme.handleOpen(firstURL), // No custom scheme URL handling for this URL
			   firstURL.matchesAppScheme {  // + URL matches app scheme
				openPrivateLink(url: firstURL, in: scene)
			} else {
				if firstURL.isFileURL, // Ensure the URL is a file URL
				   ImportFilesController.shared.importAllowed(alertUserOtherwise: true) { // Ensure import is allowed
					URLContexts.forEach { (urlContext) in
						ImportFilesController.shared.importFile(ImportFile(url: urlContext.url, fileIsLocalCopy: urlContext.options.openInPlace))
					}
				}
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
