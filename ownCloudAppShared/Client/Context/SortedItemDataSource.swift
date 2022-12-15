//
//  SortedItemDataSource.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 15.12.22.
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

open class SortedItemDataSource: OCDataSourceComposition {
	var sortComparatorObserver: NSKeyValueObservation?

	open weak var sortingFollowsContext: ClientContext? {
		willSet {
			sortComparatorObserver?.invalidate()
			sortComparatorObserver = nil
		}

		didSet {
			sortComparatorObserver = sortingFollowsContext?.observe(\.sortDescriptor, options: .initial, changeHandler: { [weak self] context, change in
				if let comparator = context.sortDescriptor?.comparator {
					self?.sortComparator = { (source1, ref1, source2, ref2) in
						if let record1 = try? source1.record(forItemRef: ref1),
						   let record2 = try? source2.record(forItemRef: ref2),
						   let item1 = record1.item as? OCItem,
						   let item2 = record2.item as? OCItem {
							return comparator(item1, item2)
						}

						return .orderedDescending
					}
				}
			})
		}
	}

	public init(itemDataSource: OCDataSource) {
		super.init(sources: [itemDataSource])
	}
}
