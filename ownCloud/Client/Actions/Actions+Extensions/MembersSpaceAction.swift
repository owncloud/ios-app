//
//  MembersSpaceAction.swift
//  ownCloud
//
//  Created by Felix Schwarz on 29.12.24.
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

class MembersSpaceAction: Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.spacemembers") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String { return OCLocalizedString("Members", nil) }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreFolder, .moreItem, .moreDetailItem, .accessibilityCustomAction] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.items.count == 1, let core = forContext.core, core.connectionStatus == .online, core.connection.capabilities?.sharingAPIEnabled == 1, let item = forContext.items.first, item.isRoot, let driveID = item.driveID, let drive = core.drive(withIdentifier: driveID, attachedOnly: true), drive.specialType == .space {
			return .first
		}

		return .none
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count == 1, let item = context.items.first, let viewController = context.viewController, let clientContext = context.clientContext else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let sharingViewController = SharingViewController(clientContext: clientContext, item: item)
		let navigationController = ThemeNavigationController(rootViewController: sharingViewController)
		viewController.present(navigationController, animated: true)
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return OCItem.groupIcon?.withRenderingMode(.alwaysTemplate)
	}
}
