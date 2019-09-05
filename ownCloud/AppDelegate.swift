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

		ImportFilesController.removeImportDirectory()

		AppLockManager.shared.showLockscreenIfNeeded()

		OCHTTPPipelineManager.setupPersistentPipelines() // Set up HTTP pipelines

		FileProviderInterfaceManager.shared.updateDomainsFromBookmarks()

		// Set up background refresh
		application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum + 10)

		// Display Extensions
		OCExtensionManager.shared.addExtension(WebViewDisplayViewController.displayExtension)
		OCExtensionManager.shared.addExtension(PDFViewerViewController.displayExtension)
		OCExtensionManager.shared.addExtension(ImageDisplayViewController.displayExtension)
		OCExtensionManager.shared.addExtension(MediaDisplayViewController.displayExtension)

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

	@available(iOS 13.0, *)
	func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {

		print("--> appdelegetat \(options.userActivities)")

        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
		var copyBeforeUsing = true
		if let shouldOpenInPlace = options[UIApplication.OpenURLOptionsKey.openInPlace] as? Bool {
			copyBeforeUsing = !shouldOpenInPlace
		}

		return ImportFilesController(url: url, copyBeforeUsing: copyBeforeUsing).accountUI()
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

    func application(_ application: UIApplication, viewControllerWithRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        print("AppDelegate viewControllerWithRestorationIdentifierPath")

        return nil // We don't want any UI hierarchy saved
    }

    func application(_ application: UIApplication, willEncodeRestorableStateWith coder: NSCoder) {
        print("AppDelegate willEncodeRestorableStateWith")

        if #available(iOS 13.0, *) {
            // no-op
        } else {
            // This is the important link for iOS 12 and earlier
            // If some view in your app sets a user activity on its window,
            // here we give the view hierarchy a chance to update the user
            // activity with whatever state info it needs to record so it can
            // later be restored to restore the app to its previous state.
            if let activity = window?.userActivity {
                activity.userInfo = [:]
                ((window?.rootViewController as? ThemeNavigationController)?.viewControllers.first as? ServerListTableViewController)?.updateUserActivityState(activity)

                // Now save off the updated user activity
                let wrap = NSUserActivityWrapper(activity)
                coder.encode(wrap, forKey: "userActivity")
            }
        }
    }

    func application(_ application: UIApplication, didDecodeRestorableStateWith coder: NSCoder) {
        print("-->AppDelegate didDecodeRestorableStateWith")

        // If we find a stored user activity, load it and give it to the view
        // hierarchy so the UI can be restored to its previous state
        if let wrap = coder.decodeObject(forKey: "userActivity") as? NSUserActivityWrapper {
            ((window?.rootViewController as? ThemeNavigationController)?.viewControllers.first as? ServerListTableViewController)?.restoreUserActivityState(wrap.userActivity)
        }
    }

    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        print("AppDelegate shouldSaveApplicationState")

        if #available(iOS 13.0, *) {
            return false
        } else {
            // Enabled just so we can persist the NSUserActivity if there is one
            return true
        }
    }

    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        print("AppDelegate shouldRestoreApplicationState")

        if #available(iOS 13.0, *) {
            return false
        } else {
            return true
        }
    }

    // MARK: UISceneSession Lifecycle
/*
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        print("AppDelegate configurationForConnecting")

        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
*/
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        print("AppDelegate didDiscardSceneSessions")
    }
}
