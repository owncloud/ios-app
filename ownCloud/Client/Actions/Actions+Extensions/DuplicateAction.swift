//
//  DuplicateAction.swift
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

import Foundation

import ownCloudSDK

class DuplicateAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.duplicate") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Duplicate".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreFolder, .toolbar] }
	var remainingItems : [OCItem] = []

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		// Examine items in context
		return .middle
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0 else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		let duplicateItems = self.context.items

		if let core = self.core {
			OnBackgroundQueue { [weak core] in
				let localizedCopy = "copy".localized
				let pattern = " \(localizedCopy)[ ]?[0-9]{0,}$"

				var scheduledCopyPaths : [String] = []

				for item in duplicateItems {
					if let core = core, let baseName = item.baseName, let parentItem = item.parentItem(from: core) {
						var duplicateCounter = 0
						let itemPathExtension = item.fileExtension

						findFreeName: repeat {
							var copyItemName = "\(baseName.replacingOccurrences(for: pattern)) \(localizedCopy)"

							if duplicateCounter > 0 {
								copyItemName = "\(copyItemName) \(String(duplicateCounter+1))"
							}

							if let itemPathExtension = itemPathExtension, itemPathExtension != "" {
								copyItemName = (copyItemName as NSString).appendingPathExtension(itemPathExtension) ?? copyItemName
							}

							var copyPath = (parentItem.path as NSString?)?.appendingPathComponent(copyItemName)

							if (item.type == .collection) && (copyPath?.hasSuffix("/") == false) {
								copyPath = copyPath?.appending("/")
							}

							if let copyPath = copyPath, scheduledCopyPaths.contains(copyPath) {
								Log.debug("Skipping scheduled path \(copyPath) for duplicating \(item.name ?? "(null)") ")
								duplicateCounter += 1
							} else {
								if let copyPath = copyPath {
									scheduledCopyPaths.append(copyPath)
								}

								if let existingItemFile = try? core.cachedItem(inParent: parentItem, withName: copyItemName, isDirectory: false) {
									Log.debug("Skipping existing file \(existingItemFile.path ?? "(null)") for duplicating \(item.name ?? "(null)") ")
									duplicateCounter += 1
								} else if let existingItemDir = try? core.cachedItem(inParent: parentItem, withName: copyItemName, isDirectory: true) {
									Log.debug("Skipping existing dir \(existingItemDir.path ?? "(null)") for duplicating \(item.name ?? "(null)") ")
									duplicateCounter += 1
								} else {
									Log.debug("Duplicating \(item.name ?? "(null)") as \(copyItemName)")

									if let progress = core.copy(item, to: parentItem, withName: copyItemName, options: nil, resultHandler: { (error, _, item, _) in
										if error != nil {
											Log.error("Error \(String(describing: error)) duplicating \(String(describing: item?.path))")
										}
									}) {
										self.publish(progress: progress)
										break findFreeName
									}
								}
							}
						} while (duplicateCounter < 10000)
					}
				}
			}
		}

		self.completed()
	}
}
