//
//  AccountSearchScope.swift
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

// Search scope that creates and manages its own OCQuery using OCQueryConditions
// Used for server-wide search

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

	public var queryConditionModifier : ((OCQueryCondition?) -> OCQueryCondition?)?  // MARK: modifier that can modify the query condition before it is passed to create the OCQuery backing the scope. The modification is invisible to the outside. Can be used to add constraints like limit to a drive, etc.

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

		var condition = queryCondition

		if let queryConditionModifier = queryConditionModifier, let baseCondition = condition {
			// Apply query condition modifier
			condition = queryConditionModifier(baseCondition)
		}

 		if let condition = condition {
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

// Subclasses
open class AccountSearchScope : CustomQuerySearchScope {
	public override init(with context: ClientContext, cellStyle: CollectionViewCellStyle?, localizedName name: String, localizedPlaceholder placeholder: String? = nil, icon: UIImage? = nil) {
		var revealCellStyle : CollectionViewCellStyle?

		if let cellStyle = cellStyle {
			revealCellStyle = CollectionViewCellStyle(from: cellStyle, changing: { cellStyle in
				cellStyle.showRevealButton = true
			})
		}

		super.init(with: context, cellStyle: revealCellStyle, localizedName: name, localizedPlaceholder: placeholder, icon: icon)
	}
}

open class DriveSearchScope : AccountSearchScope {
	public override init(with context: ClientContext, cellStyle: CollectionViewCellStyle?, localizedName name: String, localizedPlaceholder placeholder: String? = nil, icon: UIImage? = nil) {
		super.init(with: context, cellStyle: cellStyle, localizedName: name, localizedPlaceholder: placeholder, icon: icon)

		if context.core?.useDrives == true, let driveID = context.drive?.identifier {
			let requireDriveCondition = OCQueryCondition.where(.driveID, isEqualTo: driveID)

			queryConditionModifier = { (baseCondition) in
				if let baseCondition = baseCondition {
					return .require([ requireDriveCondition, baseCondition ])
				}

				return nil
			}
		}
	}
}
