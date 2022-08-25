//
//  ItemSearchScope.swift
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

// Common base class for query-modifying and custom query search scopes, implementing commonly used tools

open class ItemSearchScope : SearchScope {
	private var sortDescriptorObserver: NSKeyValueObservation?

	public override init(with context: ClientContext, cellStyle: CollectionViewCellStyle?, localizedName name: String, icon: UIImage? = nil) {
		super.init(with: context, cellStyle: cellStyle, localizedName: name, icon: icon)

		tokenizer = CustomQuerySearchTokenizer(scope: self, clientContext: context)

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

	open override func updateFor(_ searchElements: [SearchElement]) {
		if isSelected {
			var queryConditions : [OCQueryCondition] = []

			for searchElement in searchElements {
				if let queryCondition = searchElement.representedObject as? OCQueryCondition {
					queryConditions.append(queryCondition)
				}
			}

			if queryConditions.count > 0 {
				queryCondition = OCQueryCondition.require(queryConditions)
				// Log.debug("Assembled search: \(queryCondition!.composedSearchTerm)")
			} else {
				queryCondition = nil
			}
		}
	}
}
