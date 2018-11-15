//
//  DuplicateAction.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 15/11/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import Foundation

import ownCloudSDK

class DuplicateAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.duplicate") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Duplicate".localized }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		// Examine items in context
		return .last
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0 else {
			completionHandler?(NSError(ocError: .errorInsufficientParameters))
			return
		}

		beforeRunHandler?()

		let item = context.items[0]
		let rootItem = context.items[1]

		var name: String = "\(item.name!) copy"

		if item.type != .collection {
			let itemName = item.nameWithoutExtension()
			var fileExtension = item.fileExtension()

			if fileExtension != "" {
				fileExtension = ".\(fileExtension)"
			}

			name = "\(itemName) copy\(fileExtension)"
		}

		if let progress = self.core.copy(item, to: rootItem, withName: name, options: nil, resultHandler: { (error, _, item, _) in
			if error != nil {
				Log.log("Error \(String(describing: error)) duplicating \(String(describing: item?.path))")
				self.completionHandler?(error!)
			} else {
				self.completionHandler?(nil)
			}
		}) {
			progressHandler?(progress)
		}
	}
}
