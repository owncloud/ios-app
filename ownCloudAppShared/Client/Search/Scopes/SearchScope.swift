//
//  SearchScope.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 22.06.22.
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

open class SearchScope: NSObject {
	public var localizedName : String

	@objc public dynamic var results: OCDataSource?
	@objc public dynamic var resultsCellStyle: CollectionViewCellStyle?

	public var isSelected: Bool = false

	public var clientContext: ClientContext

	static public func modifyingQuery(with context: ClientContext, localizedName: String) -> SearchScope {
		return QueryModifyingSearchScope(with: context, cellStyle: nil, localizedName: localizedName)
	}

	static public func globalSearch(with context: ClientContext, cellStyle: CollectionViewCellStyle, localizedName: String) -> SearchScope {
		let revealCellStyle = CollectionViewCellStyle(from: cellStyle, changing: { cellStyle in
			cellStyle.showRevealButton = true
		})

		return CustomQuerySearchScope(with: context, cellStyle: revealCellStyle, localizedName: localizedName)
	}

	public init(with context: ClientContext, cellStyle: CollectionViewCellStyle?, localizedName name: String) {
		clientContext = context
		localizedName = name

		super.init()

		resultsCellStyle = cellStyle
	}

	open func updateForSearchTerm(_ term: String?) {

	}
}

open class ItemSearchScope : SearchScope {
	private var sortDescriptorObserver: NSKeyValueObservation?

	public override init(with context: ClientContext, cellStyle: CollectionViewCellStyle?, localizedName name: String) {
		super.init(with: context, cellStyle: cellStyle, localizedName: name)

		sortDescriptorObserver = context.observe(\.sortDescriptor, changeHandler: { [weak self] context, change in
			self?.sortDescriptorChanged(to: context.sortDescriptor)
		})
	}

	deinit {
		sortDescriptorObserver?.invalidate()
	}

	open func sortDescriptorChanged(to sortDescriptor: SortDescriptor?) {
	}

	open var queryCondition: OCQueryCondition?

	open override var isSelected: Bool {
		didSet {
			if !isSelected {
				queryCondition = nil
				results = nil
			}
		}
	}

	open var searchTerm: String?

	open override func updateForSearchTerm(_ term: String?) {
		if isSelected {
			searchTerm = term

			if let searchText = term {
				queryCondition = OCQueryCondition.fromSearchTerm(searchText)
			} else {
				queryCondition = nil
			}
		}
	}
}

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

open class CustomQuerySearchScope : ItemSearchScope {
	private let maxResultCountDefault = 100 // Maximum number of results to return from database (default)
 	private var maxResultCount = 100 // Maximum number of results to return from database (flexible)

	public override var isSelected: Bool {
		didSet {
			if isSelected {
				resultActionSource.setItems([
					OCAction(title: "Show more results".localized, icon: nil, action: { [weak self] action, options, completion in
						self?.showMoreResults()
						completion(nil)
					})
				], updated: nil)
				composeResultsDataSource()
			}
		}
	}

	public var resultActionSource: OCDataSourceArray = OCDataSourceArray()

	var resultsSubscription: OCDataSourceSubscription?

	func composeResultsDataSource() {
		if let queryResultsSource = customQuery?.queryResultsDataSource {
			let composedResults = OCDataSourceComposition(sources: [
				queryResultsSource,
				resultActionSource
			])

			let maxResultCount = maxResultCount
			let resultActionSource = resultActionSource

			resultsSubscription = queryResultsSource.subscribe(updateHandler: { [weak composedResults, weak resultActionSource] (subscription) in
				let snapshot = subscription.snapshotResettingChangeTracking(true)

				if let resultActionSource = resultActionSource {
					OnMainThread {
						composedResults?.setInclude((snapshot.numberOfItems >= maxResultCount), for: resultActionSource)
					}
				}
			}, on: .main, trackDifferences: false, performIntialUpdate: true)

			results = composedResults
		} else {
			results = nil
		}
	}

	public var customQuery: OCQuery? {
		willSet {
			if let core = clientContext.core, let oldQuery = customQuery {
				core.stop(oldQuery)
			}
		}

		didSet {
			if let core = clientContext.core, let newQuery = customQuery {
				core.start(newQuery)

				composeResultsDataSource()
			} else {
				results = nil
			}
		}
	}

	private var lastSearchTerm : String?
	private var scrollToTopWithNextRefresh : Bool = false

 	public func updateCustomSearchQuery() {
		if lastSearchTerm != searchTerm {
			// Reset max result count when search text changes
			maxResultCount = maxResultCountDefault
			lastSearchTerm = searchTerm

			// Scroll to top when search text changes
			scrollToTopWithNextRefresh = true
		}

 		if let condition = queryCondition {
			if let sortDescriptor = clientContext.sortDescriptor {
				condition.sortBy = sortDescriptor.method.sortPropertyName
				condition.sortAscending = sortDescriptor.direction != .ascendant
			}

			condition.maxResultCount = NSNumber(value: maxResultCount)

			customQuery = OCQuery(condition:condition, inputFilter: nil)
 		} else {
 			customQuery = nil
 		}
 	}

	func showMoreResults() {
		maxResultCount += maxResultCountDefault
		updateCustomSearchQuery()
	}

 	open override var queryCondition: OCQueryCondition? {
 		didSet {
 			updateCustomSearchQuery()
		}
	}

	open override func sortDescriptorChanged(to sortDescriptor: SortDescriptor?) {
		updateCustomSearchQuery()
	}
}
