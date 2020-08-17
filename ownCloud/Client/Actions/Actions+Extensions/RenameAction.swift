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
import ownCloudAppShared

class RenameAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.rename") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Rename".localized }
	override class var keyCommand : String? { return "\r" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command] }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreFolder, .keyboardShortcut, .contextMenuItem] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.items.count > 1 {
			return .none
		}
		if forContext.items.filter({return $0.isRoot || !$0.permissions.contains(.rename)}).count > 0 {
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

		let renameViewController = NamingViewController(with: item, core: self.core, stringValidator: { name in
			if name.contains("/") || name.contains("\\") {
				return (false, nil, "File name cannot contain / or \\".localized)
			} else {
				if let rootItem = rootItem {
					if ((try? self.core?.cachedItem(inParent: rootItem, withName: name, isDirectory: true)) != nil) ||
					   ((try? self.core?.cachedItem(inParent: rootItem, withName: name, isDirectory: false)) != nil) {
						return (false, "Item with same name already exists".localized, "An item with the same name already exists in this location.".localized)
					}
				}

				return (true, nil, nil)
			}
		}, completion: { newName, _ in
			guard newName != nil else {
				return
			}

			if let progress = self.core?.move(item, to: rootItem!, withName: newName!, options: nil, resultHandler: { (error, _, _, _) in
				if error != nil {
					Log.log("Error \(String(describing: error)) renaming \(String(describing: item.path))")
				}
			}) {
				self.publish(progress: progress)
			}

			self.completed()
		})

		renameViewController.navigationItem.title = "Rename".localized

		let navigationController = ThemeNavigationController(rootViewController: renameViewController)
		navigationController.modalPresentationStyle = .formSheet

		viewController.present(navigationController, animated: true)
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem || location == .moreFolder || location == .contextMenuItem {

			if #available(iOS 13.0, *) {
				return UIImage(systemName: "pencil")?.withRenderingMode(.alwaysTemplate)
			} else {
				return UIImage(named: "folder")
			}
		}

		return nil
	}
}
