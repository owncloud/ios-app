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

class MoveAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.move") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Move".localized }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
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

		let directoryPickerViewController = ClientDirectoryPickerViewController(core: core, path: "/", completion: { (selectedDirectory) in
			if let progress = self.core.move(item, to: selectedDirectory, withName: item.name, options: nil, resultHandler: { (error, _, _, _) in
				if error != nil {
					self.completionHandler?(error)
				} else {
					self.completionHandler?(nil)
				}

			}) {
				self.progressHandler?(progress)
			}
		})

		let pickerNavigationController = ThemeNavigationController(rootViewController: directoryPickerViewController)
		viewController.navigationController?.present(pickerNavigationController, animated: true)
	}
}
