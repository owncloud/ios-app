//
//  DisableSpaceAction.swift
//  ownCloud
//
//  Created by Felix Schwarz on 15.12.24.
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
import ownCloudApp
import ownCloudAppShared

public class DisableSpaceAction : Action {
	override open class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.disablespace") }
	override open class var category : ActionCategory? { return .edit }
	override open class var name : String? { return OCLocalizedString("Disable space", nil) }
	override open class var locations : [OCExtensionLocationIdentifier]? { return [.moreFolder, .spaceAction] }

	// MARK: - Extension matching
	override open class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if let core = forContext.core, core.connectionStatus == .online, let drive = forContext.drive, drive.specialType == .space {
			if let shareActions = core.connection.shareActions(for: drive) {
				if shareActions.contains(.updatePermissions) {
					return .last
				}
			}
		}

		return .none
	}

	// MARK: - Action implementation
	override open func run() {
		guard let viewController = context.viewController, let drive = context.drive, let clientContext = context.clientContext else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		drive.disable(with: clientContext, completionHandler: { [weak self] error in
			if viewController is SpaceManagementViewController {
				// Dismiss SpaceManagementViewController if the action was triggered from there
				OnMainThread {
					viewController.dismiss(animated: true)
				}
			}
			self?.completed(with: error)
		})
	}

	override open class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return UIImage(systemName: "stop.circle")?.withRenderingMode(.alwaysTemplate)
	}
}
