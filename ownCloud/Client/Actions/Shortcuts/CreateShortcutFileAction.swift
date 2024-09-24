//
//  CreateShortcutFileAction.swift
//  ownCloud
//
//  Created by Felix Schwarz on 10.04.24.
//  Copyright © 2024 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2024, ownCloud GmbH.
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

class CreateShortcutFileAction: Action {
	override open class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.createShortcutFile") }
	override open class var category : ActionCategory? { return .normal }
	override open class var name : String? { return OCLocalizedString("Create shortcut", nil) }
	override open class var locations : [OCExtensionLocationIdentifier]? { return [.folderAction, .emptyFolder] }

	// MARK: - Extension matching
	override open class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.items.count > 1 {
			return .none
		}

		if forContext.items.first?.type != .collection {
			return .none
		}

		if forContext.items.first?.permissions.contains(.createFile) == false {
			return .none
		}

		return .middle
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0, let parentItem = context.items.first, let clientContext = context.clientContext else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		let navigationController = ThemeNavigationController(rootViewController: CreateShortcutFileViewController(parentItem: parentItem, clientContext: clientContext))
		clientContext.present(navigationController, animated: true)

		self.completed()
	}

	override open class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return UIImage(systemName: "arrow.up.forward.square")?.withRenderingMode(.alwaysTemplate)
	}
}
