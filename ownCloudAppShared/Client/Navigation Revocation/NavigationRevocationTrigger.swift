//
//  NavigationRevocationTrigger.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 22.11.22.
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

open class NavigationRevocationTrigger: NSObject {
	var invalidated: Bool = false

	// MARK: - Predefined event
	var event: NavigationRevocationEvent?

	public init(event: NavigationRevocationEvent? = nil) {
		self.event = event
		super.init()
	}

	// MARK: - Trigger action
	weak public var action: NavigationRevocationAction?

	// MARK: - Data source event
	var dataSourceSubscription: OCDataSourceSubscription?
	private var objcAssociationHandle = 2

	public init(itemRemovalTriggerFor dataSource: OCDataSource, attach: Bool = false, itemRefs: [OCDataItemReference]? = nil, bookmarkUUID: UUID? = nil, on dispatchQueue: DispatchQueue = .main) {
		super.init()

		var isInitial = true

		dataSourceSubscription = dataSource.subscribe(updateHandler: { [weak self] subscription in
			let snapshot = subscription.snapshotResettingChangeTracking(true)

			if let dataSource = subscription.source, let self = self {
				if let removedItems = snapshot.removedItems {
					if let itemRefs = itemRefs {
						for removedItemRef in removedItems {
							if itemRefs.firstIndex(of: removedItemRef) != nil {
								self.send(event: NavigationRevocationEvent.itemRemoved(itemReference: removedItemRef, dataSource: dataSource.uuid, bookmarkUUID: bookmarkUUID))
							}
						}
					} else {
						for removedItemRef in removedItems {
							self.send(event: NavigationRevocationEvent.itemRemoved(itemReference: removedItemRef, dataSource: dataSource.uuid, bookmarkUUID: bookmarkUUID))
						}
					}
				}

				if isInitial {
					isInitial = false

					if let itemRefs = itemRefs {
						let allItems = snapshot.items

						for itemRef in itemRefs {
							if allItems.firstIndex(of: itemRef) == nil {
								self.send(event: NavigationRevocationEvent.itemRemoved(itemReference: itemRef, dataSource: dataSource.uuid, bookmarkUUID: bookmarkUUID))
							}
						}
					}
				}
			}
		}, on: dispatchQueue, trackDifferences: true, performIntialUpdate: true)

		if attach {
			objc_setAssociatedObject(dataSource, &self.objcAssociationHandle, self, .OBJC_ASSOCIATION_RETAIN)
		}
	}

	deinit {
		dataSourceSubscription?.terminate()
	}

	// MARK: - Methods
	func trigger() {
		if invalidated {
			return
		}

		if let event = event {
			self.event = nil
			send(event: event)
		}
	}

	func send(event: NavigationRevocationEvent?) {
		if let event = event {
			event.send()
		}

		if let action = action {
			action.performAction(with: event)
			self.action = nil
		}
	}

	func invalidate() {
		invalidated = true
		event = nil

		if let dataSourceSubscription = dataSourceSubscription {
			if let dataSource = dataSourceSubscription.source {
				objc_setAssociatedObject(dataSource, &self.objcAssociationHandle, nil, .OBJC_ASSOCIATION_RETAIN)
			}
			dataSourceSubscription.terminate()
		}
	}

	// MARK: - On Deallocation
	static func onDeallocation(of obj: Any, event: NavigationRevocationEvent) -> NavigationRevocationTrigger {
		let trigger = NavigationRevocationTrigger(event: event)

		OCDeallocAction.add({
			trigger.trigger()
		}, forDeallocationOf: obj)

		return trigger
	}
}
