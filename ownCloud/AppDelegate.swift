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
import CrashReporter

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	private let delayForLinkResolution = 0.2

	var window: ThemeWindow?
	var serverListTableViewController: ServerListTableViewController?
	var staticLoginViewController : StaticLoginViewController?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		var navigationController: UINavigationController?
		var rootViewController : UIViewController?

		// Set up logging (incl. stderr redirection) and log launch time, app version, build number and commit
		Log.log("ownCloud \(VendorServices.shared.appVersion) (\(VendorServices.shared.appBuildNumber)) #\(LastGitCommit() ?? "unknown") finished launching with log settings: \(Log.logOptionStatus)")

		// Set up notification categories
		NotificationManager.shared.registerCategories()

		// Set up license management
		OCLicenseManager.shared.setupLicenseManagement()

		// Set up app
		window = ThemeWindow(frame: UIScreen.main.bounds)

		ThemeStyle.registerDefaultStyles()

		if VendorServices.shared.isBranded {
			staticLoginViewController = StaticLoginViewController(with: StaticLoginBundle.defaultBundle)
			navigationController = ThemeNavigationController(rootViewController: staticLoginViewController!)
			navigationController?.setNavigationBarHidden(true, animated: false)
			rootViewController = navigationController
		} else {
			serverListTableViewController = ServerListTableViewController(style: .plain)

			navigationController = ThemeNavigationController(rootViewController: serverListTableViewController!)
			rootViewController = navigationController
		}

		// Only set up window on non-iPad devices and not on macOS 11 (Apple Silicon) which is >= iOS 14
		if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
			// do not set the rootViewController for iOS app on Mac
		} else {
			window?.rootViewController = rootViewController!
			window?.makeKeyAndVisible()
		}

		ImportFilesController.removeImportDirectory()

		if AppLockManager.supportedOnDevice {
			AppLockManager.shared.showLockscreenIfNeeded()
		}

		OCHTTPPipelineManager.setupPersistentPipelines() // Set up HTTP pipelines

		FileProviderInterfaceManager.shared.updateDomainsFromBookmarks()

		ScheduledTaskManager.shared.setup()

		MediaUploadQueue.shared.setup()
		AppStatistics.shared.update()

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
		OCExtensionManager.shared.addExtension(UploadCameraMediaAction.actionExtension)
		OCExtensionManager.shared.addExtension(UnshareAction.actionExtension)
		OCExtensionManager.shared.addExtension(BackgroundFetchUpdateTaskAction.taskExtension)
		OCExtensionManager.shared.addExtension(InstantMediaUploadTaskExtension.taskExtension)
		OCExtensionManager.shared.addExtension(MakeAvailableOfflineAction.actionExtension)
		OCExtensionManager.shared.addExtension(MakeUnavailableOfflineAction.actionExtension)
		OCExtensionManager.shared.addExtension(CollaborateAction.actionExtension)
		OCExtensionManager.shared.addExtension(LinksAction.actionExtension)
		OCExtensionManager.shared.addExtension(FavoriteAction.actionExtension)
		OCExtensionManager.shared.addExtension(UnfavoriteAction.actionExtension)
		OCExtensionManager.shared.addExtension(DisplayExifMetadataAction.actionExtension)
		OCExtensionManager.shared.addExtension(PresentationModeAction.actionExtension)
		if #available(iOS 13.0, *) {
			if UIDevice.current.isIpad {
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
		OCExtensionManager.shared.addExtension(OCExtension.license(withIdentifier: "license.libzip", bundleOf: AppDelegate.self, title: "libzip", resourceName: "libzip", fileExtension: "LICENSE"))
		OCExtensionManager.shared.addExtension(OCExtension.license(withIdentifier: "license.plcrashreporter", bundleOf: AppDelegate.self, title: "PLCrashReporter", resourceName: "PLCrashReporter", fileExtension: "LICENSE"))

		// Initially apply theme based on light / dark mode
		ThemeStyle.considerAppearanceUpdate()

		//Disable UI Animation for UITesting (screenshots)
		if let enableUIAnimations = VendorServices.classSetting(forOCClassSettingsKey: .enableUIAnimations) as? Bool {
			UIView.setAnimationsEnabled(enableUIAnimations)
		}

		// Set background refresh interval
		guard #available(iOS 13, *) else {
			UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
			return true
		}

        // If the app was re-installed, make sure to wipe keychain data. Since iOS 10.3 keychain entries are not deleted if the app is deleted, but since everything else is lost,
        // it might lead to some inconsistency in the app state. Nevertheless we shall be careful here and consider that prior versions of the app didn't have the flag created upon
        // very first app launch in UserDefaults. Thus we will check few more factors: no bookmarks configured and no passcode is set
        if OCBookmarkManager.shared.bookmarks.count == 0 && AppLockManager.shared.lockEnabled == false {
            VendorServices.shared.onFirstLaunch {
                OCAppIdentity.shared.keychain?.wipe()
            }
        }

		setupAndHandleCrashReports()

		return true
	}

	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
		if url.matchesAppScheme {
			guard let window = UserInterfaceContext.shared.currentWindow else { return false }

			openPrivateLink(url: url, in: window)

		} else {
			var copyBeforeUsing = true
			if let shouldOpenInPlace = options[UIApplication.OpenURLOptionsKey.openInPlace] as? Bool {
				copyBeforeUsing = !shouldOpenInPlace
			}

			ImportFilesController.shared.importFile(ImportFile(url: url, fileIsLocalCopy: copyBeforeUsing))
		}

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

	func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
		guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
			let url = userActivity.webpageURL else {
				return false
		}

		guard let window = UserInterfaceContext.shared.currentWindow else { return false }

		openPrivateLink(url: url, in: window)

		return true
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

	private func openPrivateLink(url:URL, in window:UIWindow) {
		if UIApplication.shared.applicationState == .background {
			// If the app is already running, just start link resolution
			url.resolveAndPresent(in: window)
		} else {
			// Delay a resolution of private link on cold launch, since it could be that we would otherwise interfer
			// with activities of the just instantiated ServerListTableViewController
			OnMainThread(after:delayForLinkResolution) {
				url.resolveAndPresent(in: window)
			}
		}
	}
}

extension UserInterfaceContext : UserInterfaceContextProvider {
	public func provideRootView() -> UIView? {
		return (UIApplication.shared.delegate as? AppDelegate)?.window
	}

	public func provideCurrentWindow() -> UIWindow? {
		return UIApplication.shared.windows.first as? ThemeWindow
	}
}

extension AppDelegate {
	func setupAndHandleCrashReports() {
		let configuration = PLCrashReporterConfig.defaultConfiguration()
		guard let crashReporter = PLCrashReporter(configuration: configuration) else {
			return
		}

		if crashReporter.hasPendingCrashReport() {
			if let crashData = try? crashReporter.loadPendingCrashReportDataAndReturnError(), let crashReport = try? PLCrashReport(data: crashData) {
				if let report = PLCrashReportTextFormatter.stringValue(for: crashReport, with: PLCrashReportTextFormatiOS) {
					Log.error(tagged: ["CRASH_REPORTER"], report)
				}
			}
			crashReporter.purgePendingCrashReport()
		}

		crashReporter.enable()
	}
}
