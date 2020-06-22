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
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreFolder, .toolbar, .keyboardShortcut, .contextMenuItem] }
	override class var keyCommand : String? { return "D" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if let rootItem = forContext.query?.rootItem, !rootItem.permissions.contains(.createFile) || !rootItem.permissions.contains(.createFolder) {
			return .none
		}

		if forContext.items.filter({return $0.isRoot}).count > 0 {
			return .none
		}

		return .middle
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0 else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		let duplicateItems = self.context.items

		if let core = self.core {
			OnBackgroundQueue { [weak core] in
				for item in duplicateItems {
					if let core = core, let itemName = item.name, let parentItem = item.parentItem(from: core), let parentPath = parentItem.path {
						core.suggestUnusedNameBased(on: itemName, atPath: parentPath, isDirectory: item.type == .collection, using: item.type == .collection ? .numbered : .bracketed, filteredBy: nil, resultHandler: { (suggestedName, _) in
							Log.debug("Duplicating \(item.name ?? "(null)") as \(suggestedName ?? "(null)")")

							if let suggestedName = suggestedName, let progress = core.copy(item, to: parentItem, withName: suggestedName, options: nil, resultHandler: { (error, _, item, _) in
								if error != nil {
									Log.error("Error \(String(describing: error)) duplicating \(String(describing: item?.path))")
								}
							}) {
								self.publish(progress: progress)
							} else {
								Log.error("Error duplicating \(String(describing: item.path)) - no suggestedName")
							}
						})
					}
				}
			}
		}

		self.completed()
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem || location == .moreFolder || location == .contextMenuItem {
			return UIImage(named: "duplicate-file")
		}

		return nil
	}
}
