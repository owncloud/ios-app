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

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		var navigationController: UINavigationController?

		// Set up logging (incl. stderr redirection) and log launch time, app version, build number and commit
		Log.log("ownCloud \(VendorServices.shared.appVersion) (\(VendorServices.shared.appBuildNumber)) #\(LastGitCommit() ?? "unknown") finished launching with log settings: \(Log.logOptionStatus)")

		// Set up app
		window = UIWindow(frame: UIScreen.main.bounds)

		ThemeStyle.registerDefaultStyles()

		serverListTableViewController = ServerListTableViewController(style: UITableView.Style.plain)

		navigationController = ThemeNavigationController(rootViewController: serverListTableViewController!)

		window?.rootViewController = navigationController!
		window?.addSubview((navigationController?.view)!)
		window?.makeKeyAndVisible()

		AppLockManager.shared.showLockscreenIfNeeded()

		OCHTTPPipelineManager.setupPersistentPipelines() // Set up HTTP pipelines

		FileProviderInterfaceManager.shared.updateDomainsFromBookmarks()

		// Set up background refresh
		application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum + 10)

		// Display Extensions
		OCExtensionManager.shared.addExtension(WebViewDisplayViewController.displayExtension)
		OCExtensionManager.shared.addExtension(PDFViewerViewController.displayExtension)
		OCExtensionManager.shared.addExtension(ImageDisplayViewController.displayExtension)

		// Action Extensions
		OCExtensionManager.shared.addExtension(OpenInAction.actionExtension)
		OCExtensionManager.shared.addExtension(DeleteAction.actionExtension)
		OCExtensionManager.shared.addExtension(MoveAction.actionExtension)
		OCExtensionManager.shared.addExtension(RenameAction.actionExtension)
		OCExtensionManager.shared.addExtension(DuplicateAction.actionExtension)
		OCExtensionManager.shared.addExtension(CreateFolderAction.actionExtension)
		OCExtensionManager.shared.addExtension(CopyAction.actionExtension)
		OCExtensionManager.shared.addExtension(UploadFileAction.actionExtension)
		OCExtensionManager.shared.addExtension(UploadMediaAction.actionExtension)
		OCExtensionManager.shared.addExtension(UnshareAction.actionExtension)

		Theme.shared.activeCollection = ThemeCollection(with: ThemeStyle.preferredStyle)

		// Licenses
		OCExtensionManager.shared.addExtension(OCExtension.license(withIdentifier: "license.libzip", bundleOf: Theme.self, title: "libzip", resourceName: "libzip", fileExtension: "LICENSE"))

		//Disable UI Animation for UITesting (screenshots)
		if let enableUIAnimations = VendorServices.classSetting(forOCClassSettingsKey: .enableUIAnimations) as? Bool {
			UIView.setAnimationsEnabled(enableUIAnimations)
		}

		return true
	}

	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
		return ImportFilesController(url: url).accountOrImportUI()
	}

	func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		Log.debug("AppDelegate: performFetchWithCompletionHandler")

		OnMainThread(after: 2.0) {
			completionHandler(.noData)
		}
	}

	func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
		if window is AppLockWindow {
			return .portrait
		} else {
			return .all
		}
	}

	func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
		Log.debug("AppDelegate: handle events for background URL session with identifier \(identifier)")

		OCCoreManager.shared.handleEvents(forBackgroundURLSession: identifier, completionHandler: completionHandler)
	}
}
