//
//  CreateFolderAction.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 20/11/2018.
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

class CreateFolderAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.createFolder") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Create folder".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.folderAction, .keyboardShortcut] }
	override class var keyCommand : String? { return "N" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.items.count > 1 {
			return .none
		}

		if forContext.items.first?.type != OCItemType.collection {
			return .none
		}

		if forContext.items.first?.permissions.contains(.createFolder) == false {
			return .none
		}

		return .first
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0 else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		let item = context.items.first

		guard item != nil, let itemPath = item?.path else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		guard let viewController = context.viewController else {
			return
		}

		core?.suggestUnusedNameBased(on: "New Folder".localized, atPath: itemPath, isDirectory: true, using: .numbered, filteredBy: nil, resultHandler: { (suggestedName, _) in
			guard let suggestedName = suggestedName else { return }

			OnMainThread {
				let createFolderVC = NamingViewController( with: self.core, defaultName: suggestedName, stringValidator: { name in
					if name.contains("/") || name.contains("\\") {
						return (false, "File name cannot contain / or \\".localized)
					} else {
						return (true, nil)
					}
				}, completion: { newName, _ in
					guard newName != nil else {
						return
					}

					if let progress = self.core?.createFolder(newName!, inside: item!, options: nil, resultHandler: { (error, _, _, _) in
						if error != nil {
							Log.error("Error \(String(describing: error)) creating folder \(String(describing: newName))")
							self.completed(with: error)
						} else {
							self.completed()
						}
					}) {
						self.publish(progress: progress)
					}
				})

				createFolderVC.navigationItem.title = "Create folder".localized

				let createFolderNavigationVC = ThemeNavigationController(rootViewController: createFolderVC)
				createFolderNavigationVC.modalPresentationStyle = .overFullScreen

				viewController.present(createFolderNavigationVC, animated: true)
			}
		})
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .toolbar || location == .folderAction {
			return Theme.shared.image(for: "folder-create", size: CGSize(width: 30.0, height: 30.0))!.withRenderingMode(.alwaysTemplate)
		}

		return nil
	}
}
