//
//  MoveAction.swift
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
import ownCloudAppShared

class MoveAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.move") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return OCLocalizedString("Move", nil) }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreDetailItem, .moreFolder, .multiSelection, .dropAction, .keyboardShortcut, .contextMenuItem, .accessibilityCustomAction] }
	override class var keyCommand : String? { return "V" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command, .alternate] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.containsRoot {
			return .none
		}

		if !forContext.allItemsMoveable || !forContext.allItemsDeleteable {
			return .none
		}

		return .middle
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0, let clientContext = context.clientContext, let bookmark = context.core?.bookmark else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let items = context.items
		let driveID = items.first?.driveID
		var startLocation: OCLocation
		var baseContext: ClientContext?

		if let driveID {
			// Limit to same drive
			startLocation = .drive(driveID, bookmark: bookmark)
			baseContext = clientContext
		} else {
			// Limit to account
			startLocation = .account(bookmark)
		}

		var titleText: String

		if items.count > 1 {
			titleText = OCLocalizedFormat("Move {{itemCount}} items", ["itemCount" : "\(items.count)"])
		} else {
			titleText = OCLocalizedFormat("Move \"{{itemName}}\"", ["itemName" : items.first?.name ?? "?"])
		}

		let locationPicker = ClientLocationPicker(location: startLocation, selectButtonTitle: OCLocalizedString("Move here", nil), headerTitle: titleText, headerSubTitle: OCLocalizedString("Select target.", nil), avoidConflictsWith: items, choiceHandler: { (selectedDirectoryItem, location, _, cancelled) in
			guard !cancelled, let selectedDirectoryItem else {
				self.completed(with: NSError(ocError: OCError.cancelled))
				return
			}

			items.forEach({ (item) in
				guard let itemName = item.name else {
					return
				}

				if let progress = self.core?.move(item, to: selectedDirectoryItem, withName: itemName, options: nil, resultHandler: { (error, _, _, _) in
					if error != nil {
						Log.error("Error \(String(describing: error)) moving \(String(describing: itemName)) to \(String(describing: location))")
					}
				}) {
					self.publish(progress: progress)
				}
			})

			self.completed()
		})

		locationPicker.present(in: clientContext, baseContext: baseContext)
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return UIImage(named: "folder")?.withRenderingMode(.alwaysTemplate)
	}
}
