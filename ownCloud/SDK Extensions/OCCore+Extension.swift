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

extension OCCore {

	func unifiedShares(for item: OCItem, completionHandler: @escaping (_ shares: [OCShare]) -> Void) {
		if let shareQuery = OCShareQuery(scope: .itemWithReshares, item: item) {
			shareQuery.initialPopulationHandler = { [weak self] query in
				let sharesWithReshares = query.queryResults
				self?.stop(shareQuery)

				if let shareQuery = OCShareQuery(scope: .sharedWithUser, item: item) {
					shareQuery.initialPopulationHandler = { query in
						let sharesWithMe = query.queryResults.filter({ (share) -> Bool in
							if share.itemPath == item.path {
								return true
							}
							return false
						})

						var shares : [OCShare] = []
						shares.append(contentsOf: sharesWithMe)
						shares.append(contentsOf: sharesWithReshares)
						self?.stop(shareQuery)

						completionHandler(shares)
					}
					self?.start(shareQuery)
				}
			}
			start(shareQuery)
		}
	}

	@discardableResult func sharesSharedWithMe(for item: OCItem, initialPopulationHandler: @escaping (_ shares: [OCShare]) -> Void, keepRunning: Bool = false) -> OCShareQuery? {
		if let shareQuery = OCShareQuery(scope: .sharedWithUser, item: item) {
			shareQuery.initialPopulationHandler = { [weak self] query in
				let shares = query.queryResults.filter({ (share) -> Bool in
					if share.itemPath == item.path {
						return true
					}
					return false
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
}
