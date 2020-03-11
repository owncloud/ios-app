//
//  OpenSceneAction.swift
//  ownCloud
//
//  Created by Matthias Hühne on 10.09.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
*/

import UIKit
import ownCloudSDK
import MobileCoreServices
import ownCloudAppShared

@available(iOS 13.0, *)
class OpenSceneAction: Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.openscene") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String { return "Open in a new Window".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .keyboardShortcut] }
	override class var keyCommand : String? { return "O" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command, .shift] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {

		if UIDevice.current.isIpad() {
			if forContext.items.count == 1 {
				return .first
			}
		}

		return .none
	}

	// MARK: - Action implementation
	override func run() {
		guard let viewController = context.viewController else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		if UIDevice.current.isIpad() {
			if context.items.count == 1, let item = context.items.first, let tabBarController = viewController.tabBarController as? ClientRootViewController {
				let activity = OpenItemUserActivity(detailItem: item, detailBookmark: tabBarController.bookmark)
				UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity.openItemUserActivity, options: nil)
			}
		}
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return UIImage(systemName: "uiwindow.split.2x1")?.tinted(with: Theme.shared.activeCollection.tintColor)
	}
}
