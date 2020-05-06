//
//  OCCore+Extension.swift
//  ownCloud
//
//  Created by Matthias Hühne on 17.04.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2019, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import Foundation
import ownCloudSDK
import ownCloudApp

extension OCCore {

	func unifiedShares(for item: OCItem, completionHandler: @escaping (_ shares: [OCShare]) -> Void) {
		let combinedShares : NSMutableArray = NSMutableArray()
		let dispatchGroup = DispatchGroup()

		if let shareQuery = OCShareQuery(scope: .itemWithReshares, item: item) {
			dispatchGroup.enter()

			shareQuery.initialPopulationHandler = { [weak self] query in
				combinedShares.addObjects(from: query.queryResults)
				dispatchGroup.leave()
				self?.stop(query)
			}
			start(shareQuery)
		}

		if let shareQuery = OCShareQuery(scope: .sharedWithUser, item: nil) {
			dispatchGroup.enter()

			shareQuery.initialPopulationHandler = { [weak self] query in
				let sharesWithMe = query.queryResults.filter({ (share) -> Bool in
					return share.itemPath == item.path
				})

				combinedShares.addObjects(from: sharesWithMe)
				dispatchGroup.leave()
				self?.stop(query)
			}
			start(shareQuery)
		}

		if let shareQuery = OCShareQuery(scope: .acceptedCloudShares, item: item) {
			dispatchGroup.enter()

			shareQuery.initialPopulationHandler = { [weak self] query in
				combinedShares.addObjects(from: query.queryResults)
				dispatchGroup.leave()
				self?.stop(query)
			}
			start(shareQuery)
		}

		dispatchGroup.notify(queue: .main, execute: {
			completionHandler((combinedShares as? [OCShare])!)
		})
	}

	@discardableResult func sharesSharedWithMe(for item: OCItem, initialPopulationHandler: @escaping (_ shares: [OCShare]) -> Void, allowPartialMatch : Bool = false, keepRunning: Bool = false) -> OCShareQuery? {
		if let shareQuery = OCShareQuery(scope: .sharedWithUser, item: nil) {
			shareQuery.initialPopulationHandler = { [weak self] query in
				let shares = query.queryResults.filter({ (share) -> Bool in
					return (share.itemPath == item.path) ||
					       (allowPartialMatch && (item.path?.hasPrefix(share.itemPath) == true))
				})
				initialPopulationHandler(shares)

				if !keepRunning {
					self?.stop(query)
				}
			}
			start(shareQuery)

			return keepRunning ? shareQuery : nil
		}

		return nil
	}

	@discardableResult func acceptedCloudShares(for item: OCItem, initialPopulationHandler: @escaping (_ shares: [OCShare]) -> Void, keepRunning: Bool = false) -> OCShareQuery? {
		if let shareQuery = OCShareQuery(scope: .acceptedCloudShares, item: item) {
			shareQuery.initialPopulationHandler = { [weak self] query in
				let shares = query.queryResults.filter({ (share) -> Bool in
					return share.itemPath == item.path
				})
				initialPopulationHandler(shares)

				if !keepRunning {
					self?.stop(query)
				}
			}
			start(shareQuery)

			return keepRunning ? shareQuery : nil
		}

		return nil
	}

	@discardableResult func sharesWithReshares(for item: OCItem, initialPopulationHandler: @escaping (_ shares: [OCShare]) -> Void, changesAvailableNotificationHandler: @escaping (_ shares: [OCShare]) -> Void, keepRunning: Bool) -> OCShareQuery? {
		if let shareQuery = OCShareQuery(scope: .itemWithReshares, item: item) {
			shareQuery.initialPopulationHandler = { [weak self] query in
				initialPopulationHandler(query.queryResults)

				if !keepRunning {
					self?.stop(query)
				}
			}
			shareQuery.changesAvailableNotificationHandler = { query in
				changesAvailableNotificationHandler(query.queryResults)
			}
			start(shareQuery)

			return keepRunning ? shareQuery : nil
		}

		return nil
	}

	func retrieveParentItems(for item: OCItem) -> [OCItem] {
		var parentItems : [OCItem] = []

		if item.parentLocalID != nil {
			if let parentItem = item.parentItem(from: self) {
				if item.parentLocalID != nil {
					parentItems.append(parentItem)
					let items = self.retrieveParentItems(for: parentItem)
					parentItems.append(contentsOf: items.reversed())
				}
			}
		}

		return parentItems.reversed()
	}

	func retrieveSubItems(for item: OCItem, completionHandler: ((_ items: [OCItem]?) -> Void)? = nil) {
		var newHandler = completionHandler
		let subitemsQuery = OCQuery(condition: .require([
			.where(.path, startsWith: item.path!)
		]), inputFilter:nil)

		var items : [OCItem]?

			subitemsQuery.changesAvailableNotificationHandler = { [weak self] query in
				items = query.queryResults
				self?.stop(query)
				newHandler?(items)
				newHandler = nil
			}
		self.start(subitemsQuery)
	}

	func localFile(for item: OCItem, completionHandler: @escaping (_ item: DownloadItem?) -> Void) {
		if self.localCopy(of: item) == nil {
			self.downloadItem(item, options: [ .returnImmediatelyIfOfflineOrUnavailable : true ], resultHandler: { (error, core, item, file) in
				if error == nil, let item = item, let file = item.file(with: core) {
					completionHandler(DownloadItem(file: file, item: item))
				} else {
					completionHandler(nil)
				}
			})
		} else if let file = item.file(with: self) {
			completionHandler(DownloadItem(file: file, item: item))
		} else {
			completionHandler(nil)
		}
	}
}
