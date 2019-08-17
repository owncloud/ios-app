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
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreFolder, .toolbar] }
	override class var keyCommand : String? { return "V" }

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0, let viewController = context.viewController, let core = self.core else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let items = context.items

		let directoryPickerViewController = ClientDirectoryPickerViewController(core: core, path: "/", selectButtonTitle: "Move here".localized, avoidConflictsWith: items, choiceHandler: { (selectedDirectory) in
			guard let selectedDirectory = selectedDirectory else {
				self.completed(with: NSError(ocError: OCError.cancelled))
				return
			}

			items.forEach({ (item) in
				guard let itemName = item.name else {
					return
				}

				if let progress = self.core?.move(item, to: selectedDirectory, withName: itemName, options: nil, resultHandler: { (error, _, _, _) in
					if error != nil {
						Log.error("Error \(String(describing: error)) moving \(String(describing: itemName))")
					}
				}) {
					self.publish(progress: progress)
				}
			})

			self.completed()
		})

		let pickerNavigationController = ThemeNavigationController(rootViewController: directoryPickerViewController)
		viewController.present(pickerNavigationController, animated: true)
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem {
			return UIImage(named: "folder")
		}

		return nil
	}
}
