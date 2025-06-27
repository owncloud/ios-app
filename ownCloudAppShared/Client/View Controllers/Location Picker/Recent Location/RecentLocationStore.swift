//
//  RecentLocationStore.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 20.05.25.
//  Copyright © 2025 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2025, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

class RecentLocationStore: NSObject {
	static let maximumStoredLocations: Int = 10

	var bookmark: OCBookmark
	var vault: OCVault

	@objc var locations: [RecentLocation] = []

	init(for bookmark: OCBookmark) {
		self.bookmark = bookmark
		self.vault = OCVault(bookmark: bookmark)

		super.init()

		self.vault.keyValueStore?.registerClasses(NSSet(array: [NSArray.self, RecentLocation.self]) as! Set<AnyHashable>, forKey: .recentLocations) // force cast can't be avoided here, unfortunately
		self.vault.keyValueStore?.addObserver({ store, owner, key, newValue in
			if let recentLocations = newValue as? [RecentLocation],
			    let store = owner as? RecentLocationStore {
				store.locations = recentLocations
			}
		}, forKey: .recentLocations, withOwner: self, initial: true)
	}

	deinit {
		vault.keyValueStore?.removeObserver(forOwner: self, forKey: .recentLocations)
	}

	func add(location: OCLocation, from core: OCCore) {
		if location.bookmarkUUID == nil {
			location.bookmarkUUID = bookmark.uuid
		}

		let recentLocation = RecentLocation(location: location, from: core)
		var newLocations = [
			recentLocation
		]

		for location in locations {
			if location.location?.dataItemReference == recentLocation.location?.dataItemReference {
				// Skip identical locations, so the same location isn't stored multiple times
				continue
			}
			newLocations.append(location)
		}

		// Limit number of stored entries
		while newLocations.count > RecentLocationStore.maximumStoredLocations {
			newLocations.removeLast()
		}

		// Store updated locations
		locations = newLocations
		vault.keyValueStore?.storeObject(locations as NSArray, forKey: .recentLocations)
	}

	private var _dataSource: OCDataSource?
	var dataSource: OCDataSource? {
		if _dataSource == nil {
			_dataSource = OCDataSourceKVO(object: self, keyPath: "locations")
		}
		return _dataSource
	}
}

public extension OCKeyValueStoreKey {
	static let recentLocations = OCKeyValueStoreKey(rawValue: "recentLocations")
}
