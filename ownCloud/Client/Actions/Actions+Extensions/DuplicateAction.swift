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

class DuplicateAction : Action, OCQueryDelegate {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.duplicate") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Duplicate".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreFolder, .toolbar] }
	var query : OCQuery?
	let localizedCopy = "copy".localized
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
		remainingItems.append(contentsOf: context.items)
		prepareNameForNextItem()
	}

	func prepareNameForNextItem() {
		guard let item = remainingItems.first, let baseName = item.baseName, let core = self.core, let itemPath = item.path, let rootItemPath = itemPath.parentPath() else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		let pattern = " \(localizedCopy)[ ]?[0-9]{0,}$"
		let searchName = baseName.replacingOccurrences(for: pattern)

		query = OCQuery(forPath: rootItemPath)
		query?.delegate = self
		query?.queryItem = item

		let filterHandler: OCQueryFilterHandler = { (_, _, item) -> Bool in
			if let itemName = item?.baseName {
				return itemName.hasPrefix(searchName)
			}
			return false
		}
		query?.addFilter(OCQueryFilter.init(handler: filterHandler), withIdentifier: "rename-file")

		core.start(query!)
	}

	// MARK: - Query handling
	func query(_ query: OCQuery, failedWithError error: Error) {
		completed(with: NSError(ocError: .itemNotFound))
	}

	func queryHasChangesAvailable(_ query: OCQuery) {
		query.requestChangeSet(withFlags: OCQueryChangeSetRequestFlag(rawValue: 0)) { (query, changeSet) in

			guard let queryItem = query.queryItem else { return }

			switch query.state {
			case .contentsFromCache, .waitingForServerReply:
				break
			case .idle:
				self.core?.stop(query)

				let items = changeSet?.queryResult ?? []
				guard items.first != nil else {
					OnBackgroundQueue {
						self.copy(item: queryItem, with: 0)
					}
					return
				}

				var fileCounter = -1
				for anItem in items {
					guard let baseName = anItem.baseName else { return }

					let pattern = "\(self.localizedCopy)[ ]?[0-9]{0,}$"
					let matched = baseName.matches(for: pattern)
					if matched.count > 0 {
						let copyCounter = Int(matched.first!.replacingOccurrences(of: "\(self.localizedCopy) ", with: "")) ?? 0
						if copyCounter > fileCounter {
							fileCounter = copyCounter
						}
					}
				}
				fileCounter = (fileCounter + 1)
				OnBackgroundQueue {
					self.copy(item: queryItem, with: fileCounter)
				}

			case .targetRemoved: break

			default: break
			}
		}
	}

	// MARK: - Copy Action
	func copy(item: OCItem, with duplicateCounter: Int) {
		guard let core = self.core, let itemBaseName = item.baseName else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}
		guard let rootItem = item.parentItem(from: core) else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		let pattern = " \(localizedCopy)[ ]?[0-9]{0,}$"
		var copyFileName = "\(itemBaseName.replacingOccurrences(for: pattern)) \(localizedCopy)"
		if duplicateCounter > 0 {
			copyFileName = "\(copyFileName) \(String(duplicateCounter))"
		}

		if let itemFileExtension = item.fileExtension {
			var fileExtension = itemFileExtension
			if fileExtension != "" {
				fileExtension = ".\(fileExtension)"
				copyFileName = "\(copyFileName)\(fileExtension)"
			}
		}

		if let progress = core.copy(item, to: rootItem, withName: copyFileName, options: nil, resultHandler: { (error, _, item, _) in
			if error != nil {
				Log.log("Error \(String(describing: error)) duplicating \(String(describing: item?.path))")
				self.completed(with: error)
			} else {
				self.remainingItems.removeFirst()
				if self.remainingItems.count > 0 {
					self.prepareNameForNextItem()
				} else {
					self.completed()
				}
			}
		}) {
			publish(progress: progress)
		}
	}
}
