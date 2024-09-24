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

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	// MARK: - Window
	var window: ThemeWindow?
	weak var scene: UIScene?

	// MARK: - Scene Context
	lazy var sceneClientContext: ClientContext = {
		return ClientContext(scene: scene)
	}()

	// MARK: - AppRootViewController
	lazy var appRootViewController: AppRootViewController = {
		return self.buildAppRootViewController()
	}()

	func buildAppRootViewController() -> AppRootViewController {
		return AppRootViewController(with: sceneClientContext)
	}

	// MARK: - UIWindowSceneDelegate
	// MARK: Sessions
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		self.scene = scene

		// Set up HTTP pipelines
		OCHTTPPipelineManager.setupPersistentPipelines()

		// Window and AppRootViewController creation
		if let windowScene = scene as? UIWindowScene {
			window = ThemeWindow(windowScene: windowScene)

			window?.rootViewController = appRootViewController
			if #unavailable(iOS 16) {
				// Only needed prior to iOS 16
				// From the console: "Manually adding the rootViewController's view to the view hierarchy is no longer supported. Please allow UIWindow to add the rootViewController's view to the view hierarchy itself."
				window?.addSubview(appRootViewController.view)
			}
			window?.makeKeyAndVisible()
		}

		// Was the app launched with registered URL scheme?
		if let urlContext = connectionOptions.urlContexts.first {
			if urlContext.url.matchesAppScheme {
			   	openAppSchemeLink(url: urlContext.url)
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
		}
	}

	// MARK: Screen foreground/background events
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

	// MARK: - State restoration
	func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
		var actions: [AppStateAction] = []

		let navigationBookmark = appRootViewController.contentBrowserController.history.currentItem?.navigationBookmark

		for activeConnection in AccountConnectionPool.shared.activeConnections {
			let connectAction: AppStateAction = .connection(with: activeConnection.bookmark)

			if let navigationBookmark, activeConnection.bookmark.uuid == navigationBookmark.bookmarkUUID {
				connectAction.children = [
					.navigate(to: navigationBookmark)
				]
			}

			actions.append(connectAction)
		}

		return AppStateAction(with: actions).userActivity(with: sceneClientContext)
	}

	@discardableResult func configure(window: ThemeWindow?, with activity: NSUserActivity) -> Bool {
		if activity.isRestorableActivity {
			OnMainThread(after: 0.5) {
				activity.restore(with: [
					UserActivityOption.clientContext.rawValue : self.sceneClientContext
				])
			}

			return true
		}

		return false
	}

	func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		self.scene = scene

		if let firstURL = URLContexts.first?.url { // Ensure the set isn't empty
			if !OCAuthenticationBrowserSessionCustomScheme.handleOpen(firstURL), // No custom scheme URL handling for this URL
			   firstURL.matchesAppScheme {  // + URL matches app scheme
			   	openAppSchemeLink(url: firstURL)
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
		self.scene = scene

		guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
			let url = userActivity.webpageURL else {
				return
		}

	   	openAppSchemeLink(url: url)
	}

	private func openAppSchemeLink(url: URL) {
		if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
			appDelegate.openAppSchemeLink(url: url, clientContext: sceneClientContext)
		}
	}
}

extension ClientContext: ownCloudAppShared.ClientContextProvider {
	public func provideClientContext(for bookmarkUUID: UUID, completion: (Error?, ownCloudAppShared.ClientContext?) -> Void) {
		if let sceneDelegate = scene?.delegate as? SceneDelegate,
		   let sections = sceneDelegate.appRootViewController.sidebarViewController?.allSections {
			for section in sections {
				if let accountControllerSection = section as? AccountControllerSection, accountControllerSection.clientContext?.accountConnection?.bookmark.uuid == bookmarkUUID {
					completion(nil, section.clientContext)
					return
				}
			}
		}

		completion(nil, nil)
	}
}
