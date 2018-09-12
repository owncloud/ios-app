//
//  AppDelegate.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 07/03/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	var serverListTableViewController: ServerListTableViewController?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		var navigationController: UINavigationController?

		window = UIWindow(frame: UIScreen.main.bounds)

		serverListTableViewController = ServerListTableViewController(style: UITableViewStyle.plain)

		navigationController = ThemeNavigationController(rootViewController: serverListTableViewController!)

		window?.rootViewController = navigationController!
		window?.addSubview((navigationController?.view)!)
		window?.makeKeyAndVisible()

		AppLockManager.shared.showLockscreenIfNeeded()

		FileProviderInterfaceManager.shared.updateDomainsFromBookmarks()

		application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum + 10)

		Log.debug("Minimum fetch refresh time: \(UIApplicationBackgroundFetchIntervalMinimum)")

		let pdfExtension = OCDisplayExtension.normalPDFExtension(identifier: "normalPDFViewer")
		let imageExtension = OCDisplayExtension.webViewExtension(identifier: "imageViewer")

		OCExtensionManager.shared.addExtension(pdfExtension)
		OCExtensionManager.shared.addExtension(imageExtension)

		return true
	}

	func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
		if window is AppLockWindow {
			return .portrait
		} else {
			return .all
		}
	}

	func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
		OCCoreManager.shared.handleEvents(forBackgroundURLSession: identifier, completionHandler: completionHandler)
	}
}
