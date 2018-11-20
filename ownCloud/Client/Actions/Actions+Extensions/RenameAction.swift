//
//  RenameAction.swift
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

import ownCloudSDK

class RenameAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.rename") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Rename".localized }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.items.count > 1 {
			return .none
		}
		// Examine items in context
		return .middle
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0, let viewController = context.viewController else {
			completionHandler?(NSError(ocError: .errorInsufficientParameters))
			return
		}

		let item = context.items[0]
		let rootItem = item.parentItem(from: core)

		guard rootItem != nil else {
			self.completionHandler?(NSError(ocError: OCError.errorItemNotFound))
			return
		}

		let renameViewController = NamingViewController(with: item, core: self.core, stringValidator: { name in
			if name.contains("/") || name.contains("\\") {
				return (false, "File name cannot contain / or \\")
			} else {
				return (true, nil)
			}
		}, completion: { newName, _ in

			guard newName != nil else {
				return
			}

			if let progress = self.core.move(item, to: rootItem!, withName: newName!, options: nil, resultHandler: { (error, _, _, _) in
				if error != nil {
					Log.log("Error \(String(describing: error)) renaming \(String(describing: item.path))")

					self.completionHandler?(error!)
				} else {
					self.completionHandler?(nil)
				}
			}) {
				self.progressHandler?(progress)
			}
		})

		renameViewController.navigationItem.title = "Rename".localized

		let navigationController = ThemeNavigationController(rootViewController: renameViewController)
		navigationController.modalPresentationStyle = .overFullScreen

		viewController.present(navigationController, animated: true)
	}
}
