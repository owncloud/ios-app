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
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreFolder, .toolbar] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		// Examine items in context
		return .middle
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0, let core = self.core, let item = context.items.first, let itemName = item.name else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		guard let rootItem = item.parentItem(from: core) else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		var name: String = "\(itemName) copy"

		if item.type != .collection {
			if let itemFileExtension = item.fileExtension, let baseName = item.baseName {
				var fileExtension = itemFileExtension

				if fileExtension != "" {
					fileExtension = ".\(fileExtension)"
				}

				name = "\(baseName) copy\(fileExtension)"
			}
		}

		if let progress = core.copy(item, to: rootItem, withName: name, options: nil, resultHandler: { (error, _, item, _) in
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
