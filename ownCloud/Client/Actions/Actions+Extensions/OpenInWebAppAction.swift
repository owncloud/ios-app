//
//  OpenInWebAppAction.swift
//  ownCloud
//
//  Created by Felix Schwarz on 06.09.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
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

public extension OCClassSettingsKey {
	static let openInWebAppMode = OCClassSettingsKey("open-in-web-app-mode")
}

enum OpenInWebAppActionMode: String {
	case defaultBrowser = "default-browser"
	case inApp = "in-app"
	case inAppWithDefaultBrowserOption = "in-app-with-default-browser-option"
}

class OpenInWebAppAction: Action {
	private static var _classSettingsRegistered: Bool = false
	override class var actionExtension: ActionExtension {
		if !_classSettingsRegistered {
			_classSettingsRegistered = true

			self.registerOCClassSettingsDefaults([
				.openInWebAppMode : OpenInWebAppActionMode.inApp.rawValue
			], metadata: [
				.openInWebAppMode : [
					.type 		: OCClassSettingsMetadataType.string,
					.label		: "Open In WebApp mode",
					.description 	: "Determines how to open a document in a web app.",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Actions",
					.possibleValues : [
						[
							OCClassSettingsMetadataKey.value 	: OpenInWebAppActionMode.defaultBrowser.rawValue,
							OCClassSettingsMetadataKey.description 	: "Open in default browser app. May require user to sign in."
						],
						[
							OCClassSettingsMetadataKey.value 	: OpenInWebAppActionMode.inApp.rawValue,
							OCClassSettingsMetadataKey.description 	: "Open inline in an in-app browser."
						],
						[
							OCClassSettingsMetadataKey.value 	: OpenInWebAppActionMode.inAppWithDefaultBrowserOption.rawValue,
							OCClassSettingsMetadataKey.description 	: "Open inline in an in-app browser, but provide a button to open the document in the default browser (may require the user to sign in)."
						]
					]
				]
			])
		}

		return super.actionExtension
	}

	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.openinwebapp") }
	override class var category : ActionCategory? { return .normal }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreDetailItem, .contextMenuItem] }

	class open func createActionExtension(for app: OCAppProviderApp, core: OCCore) -> ActionExtension {
		let objectProvider : OCExtensionObjectProvider = { (_ rawExtension, _ context, _ error) -> Any? in
			if let actionExtension = rawExtension as? ActionExtension,
				let actionContext   = context as? ActionContext {
				let action = self.init(for: actionExtension, with: actionContext)

				action.app = app

				return action
			}

			return nil
		}

		let appName = app.name ?? UUID().uuidString
		let extensionIdentifier = OCExtensionIdentifier("\(identifier!.rawValue).\(appName.lowercased())")
		let coreRunIdentifier = core.runIdentifier

		let standardMatcher = actionCustomContextMatcher
		let customMatcher : OCExtensionCustomContextMatcher  = { (context, priority) -> OCExtensionPriority in
			// Apply standard matching
			let standardPriority = standardMatcher(context, priority)

			guard standardPriority != .noMatch, let actionContext = context as? ActionContext else {
				return .noMatch
			}

			// Limit to specific core
			guard let core = actionContext.core, core.runIdentifier == coreRunIdentifier else {
				return .noMatch
			}

			// Apply app matching
			if self.applicablePosition(forContext: actionContext, app: app) == .none {
				return .noMatch
			}

			return standardPriority
		}

		return ActionExtension(name: "Open in {{appName}} (web)".localized(["appName" : appName]), category: category!, identifier: extensionIdentifier, locations: locations, features: features, objectProvider: objectProvider, customMatcher: customMatcher, keyCommand: nil, keyModifierFlags: nil)
	}

	class open func applicablePosition(forContext: ActionContext, app: OCAppProviderApp) -> ActionPosition {
		// OpenInWebApp only supports a single item
		guard let item = forContext.items.first, forContext.items.count == 1 else {
			return .none
		}

		// Exclude directories
		if item.type == .collection {
			return .none
		}

		// Ensure item is supported by the web app
		if !app.supportsItem(item) {
			return .none
		}

		return .nearFirst
	}

	var app : OCAppProviderApp?

	// MARK: - Action implementation
	override func run() {
		var openMode : OpenInWebAppActionMode = .inApp

		if let openInWebAppMode = classSetting(forOCClassSettingsKey: .openInWebAppMode) as? String, let configuredOpenMode = OpenInWebAppActionMode(rawValue: openInWebAppMode) {
			openMode = configuredOpenMode
		}

		switch openMode {
			case .defaultBrowser:
				openInExternalBrowser()

			case .inApp:
				openInInAppBrowser(withDefaultBrowserOption: false)

			case .inAppWithDefaultBrowserOption:
				openInInAppBrowser(withDefaultBrowserOption: true)
		}
	}

	func openInInAppBrowser(withDefaultBrowserOption defaultBrowserOption: Bool) {
		guard context.items.count == 1, let item = context.items.first, let core = context.core else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		// Open in in-app browser
		core.connection.open(inApp: item, with: app, viewMode: nil, completionHandler: { (error, url, method, headers, parameters, urlRequest) in
			if let urlRequest = urlRequest as? URLRequest {
				OnMainThread {
					let webAppViewController = ClientWebAppViewController(with: urlRequest)
					webAppViewController.navigationItem.title = item.name

					if defaultBrowserOption {
						webAppViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "safari"), primaryAction: UIAction(handler: { [weak webAppViewController] _ in
							webAppViewController?.parent?.dismiss(animated: true, completion: {
								self.openInExternalBrowser()
							})
						}), menu: nil)
					}

					let navigationController = ThemeNavigationController(rootViewController: webAppViewController)

					self.context.viewController?.present(navigationController, animated: true)
				}
			}

			self.completed(with: error)
		})
	}

	func openInExternalBrowser() {
		guard context.items.count == 1, let item = context.items.first, let core = context.core else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		// Open in external browser
		core.connection.open(inWeb: item, with: app) { (error, url) in
			if let url = url {
				OnMainThread {
					UIApplication.shared.open(url)
				}
			}

			self.completed(with: error)
		}
	}

	override var position: ActionPosition {
		if let app = app {
			return type(of: self).applicablePosition(forContext: context, app: app)
		}

		return .none
	}

	override var icon: UIImage? {
		if let remoteIcon = (app?.iconResourceRequest?.resource as? OCResourceImage)?.image?.image {
			return remoteIcon
		}

		return super.icon
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return UIImage(systemName: "globe")?.withRenderingMode(.alwaysTemplate)
	}
}
