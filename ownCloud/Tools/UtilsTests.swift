//
//  UtilsTesting.swift
//  ownCloud
//
//  Created by Javier Gonzalez on 06/11/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import Foundation
import ownCloudSDK

class UtilsTests {

	static func deleteAllBookmarks() {

		if let bookmarks:[OCBookmark] = OCBookmarkManager.shared?.bookmarks as? [OCBookmark] {
			for bookmark:OCBookmark in bookmarks {
				OCCoreManager.shared.scheduleOfflineOperation({ (inBookmark, completionHandler) in
					if let bookmark = inBookmark {
						let vault : OCVault = OCVault(bookmark: bookmark)

						vault.erase(completionHandler: { (_, error) in
							DispatchQueue.main.async {
								if error == nil {
									OCBookmarkManager.shared.removeBookmark(bookmark)
								} else {
									print("Error deleting bookmarks")
								}
							}
						})
					}
				}, for: bookmark)
			}
		}

		OCBookmarkManager.shared.bookmarks.removeAllObjects()
	}

	static func removePasscode() {
		AppLockManager.shared.passcode = nil
		AppLockManager.shared.lockEnabled = false
		AppLockManager.shared.biometricalSecurityEnabled = false
	}

	static func launchUI() {
		var navigationController: UINavigationController?
		let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate

		ThemeStyle.registerDefaultStyles()

		appDelegate.serverListTableViewController = ServerListTableViewController(style: UITableViewStyle.plain)
		navigationController = ThemeNavigationController(rootViewController: appDelegate.serverListTableViewController!)

		appDelegate.window?.rootViewController = navigationController!
		appDelegate.window?.addSubview((navigationController?.view)!)
		appDelegate.window?.makeKeyAndVisible()
	}
}
