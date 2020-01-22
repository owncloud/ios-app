//
//  EditAction.swift
//  ownCloud
//
//  Created by Matthias Hühne on 21/01/2020.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2020, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import ownCloudSDK

class EditAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.edit") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Edit".localized }
	override class var keyCommand : String? { return "A" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command] }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreFolder, .keyboardShortcut] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.items.contains(where: {$0.type == .collection}) {
			return .none
		}
		// Examine items in context
		return .middle
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0, let viewController = context.viewController, let core = self.core else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let item = context.items[0]
		let rootItem = item.parentItem(from: core)

		guard rootItem != nil else {
			self.completed(with: NSError(ocError: .itemNotFound))
			return
		}
		
		let editDocumentViewController = EditDocumentViewController(with: item, core: self.core) { (controller) in
			self.completed()
		}

		let navigationController = ThemeNavigationController(rootViewController: editDocumentViewController)
		navigationController.modalPresentationStyle = .overFullScreen
		viewController.present(navigationController, animated: true)
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem || location == .moreFolder {
			if #available(iOS 13.0, *) {
				return UIImage(systemName: "pencil")?.tinted(with: Theme.shared.activeCollection.tintColor)
			} else {
				return UIImage(named: "folder")
			}
		}

		return nil
	}
}
