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

	func sharesSharedWithMe(for item: OCItem, initialPopulationHandler: @escaping (_ shares: [OCShare]) -> Void) -> OCShareQuery? {
		let shareQuery = OCShareQuery(scope: .sharedWithUser, item: item)
		start(shareQuery!)
		shareQuery?.initialPopulationHandler = { query in
			let shares = query.queryResults.filter({ (share) -> Bool in
				if share.itemPath == item.path {
					return true
				}
				return false
			})
			initialPopulationHandler(shares)
		}

		return shareQuery
	}

	func sharesWithReshares(for item: OCItem, initialPopulationHandler: @escaping (_ shares: [OCShare]) -> Void) -> OCShareQuery? {
		let shareQuery = OCShareQuery(scope: .itemWithReshares, item: item)
		shareQuery?.refreshInterval = 5
		start(shareQuery!)
		shareQuery?.initialPopulationHandler = { query in
			initialPopulationHandler(query.queryResults)
		}

		return shareQuery
	}
}
