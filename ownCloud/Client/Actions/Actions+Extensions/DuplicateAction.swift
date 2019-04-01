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
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreFolder] }
	var query : OCQuery?

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		// Examine items in context
		return .middle
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0, let core = self.core, let item = context.items.first, let itemName = item.name else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		print("----> changeset itemName \(itemName))")
/*
		guard let rootItem = item.parentItem(from: core) else {
			print("----> changeset error rootItem \(item)")
			completed(with: NSError(ocError: .itemNotFound))
			return
		}
		print("----> changeset root \(rootItem.name) \(rootItem.baseName)")
		guard let rootItemName = rootItem.name else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		print("----> changeset rootItemName \(rootItemName)")
*/

		guard let rootItemName = item.path else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}
		let newrootItemName = rootItemName.replacingOccurrences(of: itemName, with: "")


		var name: String = "\(itemName) copy"
		var searchName = name

		if item.type != .collection {
			if let itemFileExtension = item.fileExtension, let baseName = item.baseName {
				var fileExtension = itemFileExtension

				if fileExtension != "" {
					fileExtension = ".\(fileExtension)"
				}

				if baseName.contains(" copy ") == false {
					name = "\(baseName) copy\(fileExtension)"
				}
				searchName = "\(baseName) copy"
			}
		}

			query = OCQuery(forPath: newrootItemName)
			query?.delegate = self

			let filterHandler: OCQueryFilterHandler = { (_, _, item) -> Bool in
				if let itemName = item?.baseName {

					//print("----> changeset serachtext \(searchName) \(itemName) \(itemName.hasPrefix(searchName))")
					return itemName.hasPrefix(searchName)
				}
				return false
			}
			query?.addFilter(OCQueryFilter.init(handler: filterHandler), withIdentifier: "rename-file")
			core.start(query!)
	}



	// MARK: - Query handling
	// (not in an extension, so subclasses can override these as needed)
	func query(_ query: OCQuery, failedWithError error: Error) {
		// Not applicable atm
	}

	func queryHasChangesAvailable(_ query: OCQuery) {
		query.requestChangeSet(withFlags: OCQueryChangeSetRequestFlag(rawValue: 0)) { (query, changeSet) in

			print("----> changeset \(changeSet)")

				switch query.state {
				case .contentsFromCache, .waitingForServerReply:
					break
				case .idle:
					self.core?.stop(query)

					let items = changeSet?.queryResult ?? []
					print("----> changeset items \(items)")

					guard let firstItem = items.first else {

						self.copyItem(with: 0)
						return
					}

var newCounter = 0

					for anItem in items {



					print("----> changeset last name \(anItem.baseName)")
					guard let baseName = anItem.baseName else { return }

					let matched = self.matches(for: "copy [0-9]+$", in: baseName)

						if matched.count > 0 {

							let copyCounter = Int(matched.first!.replacingOccurrences(of: "copy ", with: "")) ?? 0

							if copyCounter > newCounter {
								newCounter = copyCounter
							}
							print("----> changeset match \(newCounter)")
						}


					}

					newCounter = (newCounter + 1)
					print("----> changeset newCounter \(newCounter)")
					self.copyItem(with: newCounter)

				case .targetRemoved: break

				default: break
				}
			}

		//}

	}

	func matches(for regex: String, in text: String) -> [String] {

		do {
			let regex = try NSRegularExpression(pattern: regex)
			let results = regex.matches(in: text,
										range: NSRange(text.startIndex..., in: text))
			return results.map {
				String(text[Range($0.range, in: text)!])
			}
		} catch let error {
			print("invalid regex: \(error.localizedDescription)")
			return []
		}
	}

	func copyItem(with counter: Int) {
		guard context.items.count > 0, let core = self.core, let item = context.items.first, let itemBaseName = item.baseName else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		guard let rootItem = item.parentItem(from: core) else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		var newName = ""
			newName = "\(itemBaseName) copy"
			if counter > 0 {
				newName = "\(newName) \(String(counter))"
			}


		if item.type != .collection {
			if let itemFileExtension = item.fileExtension, let baseName = item.baseName {
				var fileExtension = itemFileExtension

				if fileExtension != "" {
					fileExtension = ".\(fileExtension)"
				}

				newName = "\(baseName) copy"
				if counter > 0 {
					newName = "\(newName) \(String(counter))"
				}
				newName = "\(newName)\(fileExtension)"
			}
		}

		print("----> changeset new name \(newName)")

		if let progress = core.copy(item, to: rootItem, withName: newName, options: nil, resultHandler: { (error, _, item, _) in
			if error != nil {
				Log.log("Error \(String(describing: error)) duplicating \(String(describing: item?.path))")
				self.completed(with: error)
			} else {
				self.completed()
			}
		}) {
			publish(progress: progress)
		}
	}
}
