//
//  DeleteAction.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 12/11/2018.
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

import ownCloudSDK

class DeleteAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.delete") }
	override class var category : ActionCategory? { return .destructive }
	override class var name : String? { return "Delete".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .tableRow, .moreFolder, .toolbar] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		// Examine items in context
		return .last
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0, let viewController = context.viewController else {
			completionHandler?(NSError(ocError: .insufficientParameters))
			return
		}

		let items = context.items

		let message: String
		if items.count > 1 {
			message = "Are you sure you want to delete these items from the server?".localized
		} else {
			message = "Are you sure you want to delete this item from the server?".localized
		}

		let name: String
		if items.count > 1 {
			name = "Multiple items".localized
		} else {
			name = items[0].name
		}

		let deleteItemAndPublishProgress = { (item: OCItem) in
			if let progress = self.core?.delete(item, requireMatch: true, resultHandler: { (error, _, _, _) in
				if error != nil {
					Log.log("Error \(String(describing: error)) deleting \(String(describing: item.path))")
					self.completed(with: error)
				} else {
					self.completed()
				}
			}) {
				self.publish(progress: progress)
			}
		}

		let alertController = UIAlertController(
			with: name,
			message: message,
			destructiveLabel: "Delete".localized,
			preferredStyle: UIDevice.current.isIpad() ? UIAlertController.Style.alert : UIAlertController.Style.actionSheet,
			destructiveAction: {
				for item in items {
					deleteItemAndPublishProgress(item)
				}
		})

		viewController.present(alertController, animated: true)

	}
}
