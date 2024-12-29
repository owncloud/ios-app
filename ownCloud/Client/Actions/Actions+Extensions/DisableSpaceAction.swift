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
	override open class var locations : [OCExtensionLocationIdentifier]? { return [.moreFolder] }

	// MARK: - Extension matching
	override open class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.drives == nil || forContext.drives?.count != 1 {
			return .none
		}

		return .last
	}

	// MARK: - Action implementation
	override open func run() {
		guard let viewController = context.viewController, let drive = context.drives?.first, let clientContext = context.clientContext else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		core?.connection.disableDrive(drive, completionHandler: { error in
			OnMainThread {
				if let error {
					let alertController = ThemedAlertController(
						with: OCLocalizedFormat("Error disabling {{driveName}}", ["driveName" : drive.name ?? OCLocalizedString("space", nil)]),
						message: error.localizedDescription,
						okLabel: OCLocalizedString("OK", nil),
						action: nil)

					viewController.present(alertController, animated: true)
				} else {
					clientContext.core?.fetchUpdates()
				}

				self.completed(with: error)
			}
		})
	}

	override open class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return UIImage(systemName: "stop.circle")?.withRenderingMode(.alwaysTemplate)
	}
}
