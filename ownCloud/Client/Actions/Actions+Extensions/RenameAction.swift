//
//  RenameAction.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 15/11/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import ownCloudSDK

class RenameAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.rename") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Rename".localized }

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

		beforeRunHandler?()

		let item = context.items[0]
		let rootItem = context.items[1]

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

			if let progress = self.core.move(item, to: rootItem, withName: newName!, options: nil, resultHandler: { (error, _, _, _) in
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
