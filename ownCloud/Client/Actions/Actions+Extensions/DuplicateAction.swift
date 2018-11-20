//
//  DuplicateAction.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 15/11/2018.
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

import Foundation

import ownCloudSDK

class DuplicateAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.duplicate") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Duplicate".localized }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		// Examine items in context
		return .middle
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0 else {
			completed(with: NSError(ocError: OCError.errorItemNotFound))
			return
		}

		let item = context.items[0]
		let rootItem = item.parentItem(from: core)

		guard rootItem != nil else {
			completed(with: NSError(ocError: OCError.errorItemNotFound))
			return
		}

		var name: String = "\(item.name!) copy"

		if item.type != .collection {
			let itemName = item.nameWithoutExtension()
			var fileExtension = item.fileExtension()

			if fileExtension != "" {
				fileExtension = ".\(fileExtension)"
			}

			name = "\(itemName) copy\(fileExtension)"
		}

		if let progress = self.core.copy(item, to: rootItem!, withName: name, options: nil, resultHandler: { (error, _, item, _) in
			if error != nil {
				Log.log("Error \(String(describing: error)) duplicating \(String(describing: item?.path))")
				self.completed(with: error)
			} else {
				self.completed()
			}
		}) {
			publish(progress: progress)
		}
	}
}
