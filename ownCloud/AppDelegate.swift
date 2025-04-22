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

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Set up logging (incl. stderr redirection) and log launch time, app version, build number and commit
		Log.log("ownCloud \(VendorServices.shared.appVersion) (\(VendorServices.shared.appBuildNumber)) #\(GitInfo.app.versionInfo) finished launching with log settings: \(Log.logOptionStatus)")

		// Set up notification categories
		NotificationManager.shared.registerCategories()

		// Set up license management
		OCLicenseManager.shared.setupLicenseManagement()

		// Set up HTTP pipelines
		OCHTTPPipelineManager.setupPersistentPipelines()

		// Set up app
		ThemeStyle.registerDefaultStyles()

		CollectionViewCellProvider.registerStandardImplementations()
		CollectionViewSupplementaryCellProvider.registerStandardImplementations()

		ImportFilesController.removeImportDirectory()

		if AppLockManager.supportedOnDevice {
			AppLockManager.shared.showLockscreenIfNeeded()
		}

		FileProviderInterfaceManager.shared.updateDomainsFromBookmarks()

		ScheduledTaskManager.shared.setup()

		MediaUploadQueue.shared.setup()
		AppStatistics.shared.update()

		// Display Extensions
		OCExtensionManager.shared.addExtension(ShortcutFileDisplayViewController.displayExtension)
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
		OCExtensionManager.shared.addExtension(AvailableOfflineAction.actionExtension)
		OCExtensionManager.shared.addExtension(CollaborateAction.actionExtension)
		OCExtensionManager.shared.addExtension(FavoriteAction.actionExtension)
		OCExtensionManager.shared.addExtension(UnfavoriteAction.actionExtension)
		OCExtensionManager.shared.addExtension(DisplayExifMetadataAction.actionExtension)
		OCExtensionManager.shared.addExtension(PresentationModeAction.actionExtension)
		OCExtensionManager.shared.addExtension(PDFGoToPageAction.actionExtension)
		OCExtensionManager.shared.addExtension(ImportPasteboardAction.actionExtension)
		OCExtensionManager.shared.addExtension(CutAction.actionExtension)
		OCExtensionManager.shared.addExtension(CreateDocumentAction.actionExtension)
		OCExtensionManager.shared.addExtension(AddToSidebarAction.actionExtension)
		OCExtensionManager.shared.addExtension(RemoveFromSidebarAction.actionExtension)
		OCExtensionManager.shared.addExtension(CreateShortcutFileAction.actionExtension)
		OCExtensionManager.shared.addExtension(OpenShortcutFileAction.actionExtension)

		if UIDevice.current.isIpad {
			// iPad only
			OCExtensionManager.shared.addExtension(DiscardSceneAction.actionExtension)
			OCExtensionManager.shared.addExtension(OpenSceneAction.actionExtension)
		}

		OCExtensionManager.shared.addExtension(ScanAction.actionExtension)
		OCExtensionManager.shared.addExtension(DocumentEditingAction.actionExtension)

		OCExtensionManager.shared.addExtension(ManageSpaceAction.actionExtension)
		OCExtensionManager.shared.addExtension(MembersSpaceAction.actionExtension)
		OCExtensionManager.shared.addExtension(DisableSpaceAction.actionExtension)
		OCExtensionManager.shared.addExtension(EditSpaceDescriptionAction.actionExtension)
		OCExtensionManager.shared.addExtension(EditSpaceImageAction.actionExtension)
		OCExtensionManager.shared.addExtension(DetailsSpaceAction.actionExtension)

		// Register class settings for extensions added on a per-connection basis
		OnMainThread {
			OpenInWebAppAction.registerSettings()
			OpenShortcutFileAction.registerSettings()
			CreateDocumentAction.registerSettings()
		}

		// Task extensions
		OCExtensionManager.shared.addExtension(BackgroundFetchUpdateTaskAction.taskExtension)
		OCExtensionManager.shared.addExtension(InstantMediaUploadTaskExtension.taskExtension)
		OCExtensionManager.shared.addExtension(PendingMediaUploadTaskExtension.taskExtension)

		// Theming
		Theme.shared.activeCollection = ThemeCollection(with: ThemeStyle.preferredStyle)

		// Licenses
		OCExtensionManager.shared.addExtension(OCExtension.license(withIdentifier: "license.plcrashreporter", bundleOf: AppDelegate.self, title: "PLCrashReporter", resourceName: "PLCrashReporter", fileExtension: "LICENSE"))

		// Initially apply theme based on light / dark mode
		ThemeStyle.considerAppearanceUpdate()

		//Disable UI Animation for UITesting (screenshots)
		if let enableUIAnimations = VendorServices.classSetting(forOCClassSettingsKey: .enableUIAnimations) as? Bool {
			UIView.setAnimationsEnabled(enableUIAnimations)
		}

		// If the app was re-installed, make sure to wipe keychain data. Since iOS 10.3 keychain entries are not deleted if the app is deleted, but since everything else is lost,
		// it might lead to some inconsistency in the app state. Nevertheless we shall be careful here and consider that prior versions of the app didn't have the flag created upon
		// very first app launch in UserDefaults. Thus we will check few more factors: no bookmarks configured and no passcode is set
		if OCBookmarkManager.shared.bookmarks.count == 0 && AppLockSettings.shared.lockEnabled == false {
			VendorServices.shared.onFirstLaunch {
				OCAppIdentity.shared.keychain?.wipe()
			}
		}

		ExternalBrowserBusyHandler.setup()

		setupAndHandleCrashReports()

		setupMDMPushRelaunch()

		return true
	}

	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
		if !OCAuthenticationBrowserSessionCustomScheme.handleOpen(url), // No custom scheme URL handling for this URL
		   url.matchesAppScheme { // + URL matches app scheme
			guard let window = UserInterfaceContext.shared.currentWindow else { return false }

			openAppSchemeLink(url: url, in: window)
		} else if url.isFileURL {
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
		// Not applicable here at the app delegate level.
		return false
	}

	// MARK: UISceneSession Lifecycle
	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
	}

	// MARK: - App Scheme URL handling
	open func openAppSchemeLink(url: URL, in inWindow: UIWindow? = nil, clientContext: ClientContext? = nil, autoDelay: Bool = true) {
		guard let window = inWindow ?? (clientContext?.scene as? UIWindowScene)?.windows.first else { return }

		if UIApplication.shared.applicationState != .background, autoDelay {
			// Delay a resolution of private link on cold launch, since it could be that we would otherwise interfer
			// with activities of the just instantiated ServerListTableViewController
			OnMainThread(after: delayForLinkResolution) {
				self.openAppSchemeLink(url: url, in: window, clientContext: clientContext, autoDelay: false)
			}

			return
		}

		// App is already running, just start link resolution
		if openPrivateLink(url: url, clientContext: clientContext) { return }
		if openPostBuild(url: url, in: window) { return }
	}

	// MARK: Post Build
	private func openPostBuild(url: URL, in window: UIWindow) -> Bool {
		// owncloud://pb/[set|clear]/[all|flatID]/?[int|string|sarray]=[value]
		/*
			Examples:
			owncloud://pb/set/branding.app-name?string=ocisCloud
			owncloud://pb/clear/branding.app-name
			owncloud://pb/clear/all
		*/
		if url.host == "pb" {
			let components = url.pathComponents

			if components.count >= 3 {
				let command = components[1]
				let targetID = components[2]
				var relaunchReason: String?

				switch command {
					case "set":
						if targetID == "all" { break }

						let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
						if let queryItems = urlComponents?.queryItems {
							for queryItem in queryItems {
								if let value = queryItem.value {
									switch queryItem.name {
										case "int":
											if let intVal = Int(value) as? NSNumber {
												let error = OCClassSettingsFlatSourcePostBuild.sharedPostBuildSettings.setValue(intVal, forFlatIdentifier: targetID)
												if error == nil {
													relaunchReason = OCLocalizedFormat("Changed {{settingID}} to {{newValue}}.", [
														"settingID" : targetID,
														"newValue" : "int(\(intVal))"
													])
												}
											}

										case "string":
											let error = OCClassSettingsFlatSourcePostBuild.sharedPostBuildSettings.setValue(value, forFlatIdentifier: targetID)
											if error == nil {
												relaunchReason = OCLocalizedFormat("Changed {{settingID}} to {{newValue}}.", [
													"settingID" : targetID,
													"newValue" : "string(\(value))"
												])
											}

										case "sarray":
											let strings = (value as NSString).components(separatedBy: ".")
											let error = OCClassSettingsFlatSourcePostBuild.sharedPostBuildSettings.setValue(strings, forFlatIdentifier: targetID)
											if error == nil {
												relaunchReason = OCLocalizedFormat("Changed {{settingID}} to {{newValue}}.", [
													"settingID" : targetID,
													"newValue" : "stringArray(\(strings.joined(separator: ", ")))"
												])
											}

										default: break
									}
								}
							}
						}

					case "clear":
						if targetID == "all" {
							// Clear all post build settings
							OCClassSettingsFlatSourcePostBuild.sharedPostBuildSettings.clear()
							relaunchReason = OCLocalizedString("Cleared all.", nil)
							break
						}

						// Clear specific setting
						let error = OCClassSettingsFlatSourcePostBuild.sharedPostBuildSettings.setValue(nil, forFlatIdentifier: targetID)
						if error == nil {
							relaunchReason = OCLocalizedFormat("Cleared {{settingID}}.", [ "settingID" : targetID ])
						}

					default: break
				}

				if let relaunchReason {
					OnMainThread {
						self.offerRelaunchForReason(relaunchReason)
					}
				}
			}
			return true
		}
		return false
	}

	// MARK: Private Link
	private func openPrivateLink(url: URL, clientContext: ClientContext?) -> Bool {
		if let clientContext, url.privateLinkItemID != nil {
			url.resolveAndPresentPrivateLink(with: clientContext)
			return true
		}

		return false
	}
}

extension UserInterfaceContext : ownCloudAppShared.UserInterfaceContextProvider {
	public func provideRootView() -> UIView? {
		return provideCurrentWindow()
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

extension AppDelegate : NotificationResponseHandler {
	func setupMDMPushRelaunch() {
		NotificationCenter.default.addObserver(self, selector: #selector(offerRelaunchAfterMDMPush), name: .OCClassSettingsManagedSettingsChanged, object: nil)
	}

	@objc func offerRelaunchAfterMDMPush() {
		offerRelaunchForReason(OCLocalizedString("New settings received from MDM", nil))
	}

	func offerRelaunchForReason(_ reason: String) {
		NotificationManager.shared.requestAuthorization(options: [.alert, .sound], completionHandler: { (granted, _) in
			if granted {
				let content = UNMutableNotificationContent()

				content.title = reason
				content.body = OCLocalizedString("Tap to quit the app.", nil)

				let request = UNNotificationRequest(identifier: NotificationManagerComposeIdentifier(AppDelegate.self, "terminate-app"), content: content, trigger: nil)

				NotificationManager.shared.add(request, withCompletionHandler: { (_) in })
			}
		})
	}

	static func handle(_ center: UNUserNotificationCenter, response: UNNotificationResponse, identifier: String, completionHandler: @escaping () -> Void) {
		if identifier == "terminate-app", response.actionIdentifier == UNNotificationDefaultActionIdentifier {
			UNUserNotificationCenter.postLocalNotification(with: "mdm-relaunch", title: OCLocalizedString("Tap to launch the app.", nil), body: nil, after: 0.1) { (error) in
				if error == nil {
					exit(0)
				}
			}
		}
	}
}
