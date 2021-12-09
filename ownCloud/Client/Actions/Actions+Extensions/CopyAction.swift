//
//  CopyAction.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 14/01/2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
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

class CopyAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.copy") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Copy".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreFolder, .toolbar, .keyboardShortcut] }
	override class var keyCommand : String? { return "C" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command, .alternate] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.items.filter({return $0.isRoot}).count > 0 {
			return .none

		}

		return .middle
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0, let viewController = context.viewController, let core = self.core else {
			completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let items = context.items

		let directoryPickerViewController = ClientDirectoryPickerViewController(core: core, path: "/", selectButtonTitle: "Copy here".localized, avoidConflictsWith: items, choiceHandler: { (selectedDirectory) in
			if let targetDirectory = selectedDirectory {
				items.forEach({ (item) in

					if let progress = self.core?.copy(item, to: targetDirectory, withName: item.name!, options: nil, resultHandler: { (error, _, _, _) in
						if error != nil {
							self.completed(with: error)
						} else {
							self.completed()
						}

					}) {
						self.publish(progress: progress)
					}
				})
			}

		})

		let pickerNavigationController = ThemeNavigationController(rootViewController: directoryPickerViewController)
		viewController.present(pickerNavigationController, animated: true)
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem || location == .moreFolder {
			return UIImage(named: "copy-file")
		}

		return nil
	}
}
