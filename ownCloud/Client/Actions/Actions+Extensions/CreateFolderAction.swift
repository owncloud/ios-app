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

class CreateFolderAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.crateFolder") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Create Folder".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.sortBar] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {

		if forContext.items.count > 1 {
			return .none
		}

		return .first
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0 else {
			completed(with: NSError(ocError: OCError.errorItemNotFound))
			return
		}

		let item = context.items.first

		guard item != nil else {
			completed(with: NSError(ocError: OCError.errorItemNotFound))
			return
		}

		guard let viewController = context.viewController else {
			return
		}

		let createFolderVC = NamingViewController( with: core, defaultName: "New Folder".localized, stringValidator: { name in
			if name.contains("/") || name.contains("\\") {
				return (false, "File name cannot contain / or \\")
			} else {
				return (true, nil)
			}
		}, completion: { newName, _ in

			guard newName != nil else {
				return
			}

			if let progress = self.core.createFolder(newName!, inside: item!, options: nil, resultHandler: { (error, _, _, _) in
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

	override func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .sortBar || location == .toolbar {
			return Theme.shared.image(for: "folder-create", size: CGSize(width: 30.0, height: 30.0))!.withRenderingMode(.alwaysTemplate)
		}

		return nil
	}
}
