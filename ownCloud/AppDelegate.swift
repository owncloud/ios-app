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
import ownCloudApp
import ownCloudAppShared

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: ThemeWindow?
	var serverListTableViewController: ServerListTableViewController?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		var navigationController: UINavigationController?

		// Set up logging (incl. stderr redirection) and log launch time, app version, build number and commit
		Log.log("ownCloud \(VendorServices.shared.appVersion) (\(VendorServices.shared.appBuildNumber)) #\(LastGitCommit() ?? "unknown") finished launching with log settings: \(Log.logOptionStatus)")

		// Set up license management
		OCLicenseManager.shared.setupLicenseManagement()

		// Set up app
		window = ThemeWindow(frame: UIScreen.main.bounds)

		ThemeStyle.registerDefaultStyles()

		serverListTableViewController = ServerListTableViewController(style: .plain)

		navigationController = ThemeNavigationController(rootViewController: serverListTableViewController!)

		window?.rootViewController = navigationController!
		window?.addSubview((navigationController?.view)!)
		window?.makeKeyAndVisible()

		ImportFilesController.removeImportDirectory()

		AppLockManager.shared.showLockscreenIfNeeded()

		OCHTTPPipelineManager.setupPersistentPipelines() // Set up HTTP pipelines

		FileProviderInterfaceManager.shared.updateDomainsFromBookmarks()

		ScheduledTaskManager.shared.setup()

		// Display Extensions
		OCExtensionManager.shared.addExtension(WebViewDisplayViewController.displayExtension)
		OCExtensionManager.shared.addExtension(PDFViewerViewController.displayExtension)
		OCExtensionManager.shared.addExtension(PreviewViewController.displayExtension)
		OCExtensionManager.shared.addExtension(MediaDisplayViewController.displayExtension)
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
		OCExtensionManager.shared.addExtension(BackgroundFetchUpdateTaskAction.taskExtension)
		OCExtensionManager.shared.addExtension(InstantMediaUploadTaskExtension.taskExtension)
		OCExtensionManager.shared.addExtension(MakeAvailableOfflineAction.actionExtension)
		OCExtensionManager.shared.addExtension(MakeUnavailableOfflineAction.actionExtension)
		OCExtensionManager.shared.addExtension(CollaborateAction.actionExtension)
		OCExtensionManager.shared.addExtension(LinksAction.actionExtension)
		OCExtensionManager.shared.addExtension(FavoriteAction.actionExtension)
		OCExtensionManager.shared.addExtension(UnfavoriteAction.actionExtension)
		if #available(iOS 13.0, *) {
			if UIDevice.current.isIpad() {
				// iPad & iOS 13+ only
				OCExtensionManager.shared.addExtension(DiscardSceneAction.actionExtension)
				OCExtensionManager.shared.addExtension(OpenSceneAction.actionExtension)
			}

			// iOS 13+ only
			OCExtensionManager.shared.addExtension(ScanAction.actionExtension)
			OCExtensionManager.shared.addExtension(DocumentEditingAction.actionExtension)

			//TODO: Enable in version 1.4 after testing this feature
			//OCExtensionManager.shared.addExtension(MediaEditingAction.actionExtension)
		}

		// Task extensions
		OCExtensionManager.shared.addExtension(BackgroundFetchUpdateTaskAction.taskExtension)
		OCExtensionManager.shared.addExtension(InstantMediaUploadTaskExtension.taskExtension)
		OCExtensionManager.shared.addExtension(PendingMediaUploadTaskExtension.taskExtension)

		// Theming
		Theme.shared.activeCollection = ThemeCollection(with: ThemeStyle.preferredStyle)

		// Licenses
		OCExtensionManager.shared.addExtension(OCExtension.license(withIdentifier: "license.libzip", bundleOf: Theme.self, title: "libzip", resourceName: "libzip", fileExtension: "LICENSE"))

		// Initially apply theme based on light / dark mode
		ThemeStyle.considerAppearanceUpdate()

		//Disable UI Animation for UITesting (screenshots)
		if let enableUIAnimations = VendorServices.classSetting(forOCClassSettingsKey: .enableUIAnimations) as? Bool {
			UIView.setAnimationsEnabled(enableUIAnimations)
		}

		// Set background refresh interval
		UIApplication.shared.setMinimumBackgroundFetchInterval(
			UIApplication.backgroundFetchIntervalMinimum)

		return true
	}

	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
		var copyBeforeUsing = true
		if let shouldOpenInPlace = options[UIApplication.OpenURLOptionsKey.openInPlace] as? Bool {
			copyBeforeUsing = !shouldOpenInPlace
		}

		ImportFilesController(url: url, copyBeforeUsing: copyBeforeUsing).accountUI()

		return true
	}

	func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		ScheduledTaskManager.shared.backgroundFetch(completionHandler: completionHandler)
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

	// MARK: UISceneSession Lifecycle
	@available(iOS 13.0, *)
	func application(_ application: UIApplication,
					 configurationForConnecting connectingSceneSession: UISceneSession,
					 options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	@available(iOS 13.0, *)
	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
	}
}
