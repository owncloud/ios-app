//
//  SingleFolderSearchScope.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 25.08.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK
import ownCloudApp

// Search scope that modifies an existing OCQuery so that it only returns matching results
// Used for folder-only search

open class QueryModifyingSearchScope : ItemSearchScope {
	public override var isSelected: Bool {
		didSet {
			if let query = clientContext.query {
				if isSelected {
					// Modify existing query provided via clientContext
					results = query.queryResultsDataSource
				}
			}
		}
	}

	open override var queryCondition: OCQueryCondition? {
		didSet {
			let queryCondition = queryCondition

			if let query = clientContext.query {
				if queryCondition != nil {
					let filterHandler: OCQueryFilterHandler = { (_, _, item) -> Bool in
						if let item = item, let queryCondition = queryCondition {
							return queryCondition.fulfilled(by: item)
						}
						return false
					}

					if let filter = query.filter(withIdentifier: "text-search") {
						query.updateFilter(filter, applyChanges: { filterToChange in
							(filterToChange as? OCQueryFilter)?.filterHandler = filterHandler
						})
					} else {
						query.addFilter(OCQueryFilter(handler: filterHandler), withIdentifier: "text-search")
					}
				} else {
					if let filter = query.filter(withIdentifier: "text-search") {
						query.removeFilter(filter)
					}
				}
			}
		}
	}
}

// Subclass
open class SingleFolderSearchScope : QueryModifyingSearchScope {
	open override var savedSearchScope: OCSavedSearchScope? {
		return .folder
	}
	open override var savedSearch: AnyObject? {
		if let savedSearch = super.savedSearch as? OCSavedSearch {
			savedSearch.location = clientContext.query?.queryLocation
			return savedSearch
		}
		return nil
	}
}
