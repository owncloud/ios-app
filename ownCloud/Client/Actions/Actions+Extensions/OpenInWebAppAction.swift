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

class OpenInWebAppAction: Action {
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
		guard context.items.count == 1, let item = context.items.first, let core = context.core else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

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
