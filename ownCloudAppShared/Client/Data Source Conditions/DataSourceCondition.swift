//
//  DataSourceCondition.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 22.02.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

open class DataSourceCondition: NSObject {
	public enum Condition {
		// Item count
		case empty
		case countEqual(_ itemCount: Int)
		case countMinimum(_ itemCount: Int)
		case countMaximum(_ itemCount: Int)

		// Logic combination of conditions
		case allOf(_ conditions: [DataSourceCondition])
		case anyOf(_ conditions: [DataSourceCondition])
	}

	public typealias Action = (_ condition: DataSourceCondition) -> Void
	open weak var parent: DataSourceCondition?

	open var datasource: OCDataSource?
	var subscription: OCDataSourceSubscription?
	open var condition: Condition {
		willSet {
			setParentOf(condition: condition, to: nil)
		}

		didSet {
			setParentOf(condition: condition, to: self)
		}
	}

	private func setParentOf(condition: Condition, to newParent: DataSourceCondition?) {
		switch condition {
			case .anyOf(let conditions):
				for condition in conditions {
					condition.parent = newParent
				}

			case .allOf(let conditions):
				for condition in conditions {
					condition.parent = newParent
				}

			default: break
		}
	}

	var action: Action?

	open var fulfilled: Bool? {
		didSet {
			if fulfilled != oldValue {
				if let parent {
					parent.updateResult(fromChild: self)
				}

				if let action {
					action(self)
				}
			}
		}
	}

	public init(_ inCondition: Condition, with inDatasource: OCDataSource? = nil, initial: Bool = false, action inAction: Action? = nil) {
		condition = inCondition

		super.init()

		datasource = inDatasource
		subscription = datasource?.subscribe(updateHandler: { [weak self] subscription in
			self?.updateResult(fromSubscription: subscription)
		}, on: .main, trackDifferences: false, performInitialUpdate: true)

		updateResult()

		setParentOf(condition: condition, to: self)
		action = inAction

		if initial, let action {
			action(self)
		}
	}

	deinit {
		subscription?.terminate()
	}

	func updateResult(fromSubscription subscription: OCDataSourceSubscription? = nil, fromChild childCondition: DataSourceCondition? = nil) {
		if let subscription {
			let snapshot = subscription.snapshotResettingChangeTracking(true)

			switch condition {
				case .empty:
					fulfilled = snapshot.numberOfItems == 0

				case .countEqual(let numberOfItems):
					fulfilled = snapshot.numberOfItems == numberOfItems

				case .countMinimum(let numberOfItems):
					fulfilled = snapshot.numberOfItems >= numberOfItems

				case .countMaximum(let numberOfItems):
					fulfilled = snapshot.numberOfItems <= numberOfItems

				default: break
			}
		}

		switch condition {
			case .allOf(let conditions):
				var newFulfilled: Bool = true

				for childCondition in conditions {
					if childCondition.fulfilled != true {
						newFulfilled = false
						break
					}
				}

				fulfilled = newFulfilled

			case .anyOf(let conditions):
				var newFulfilled: Bool = false

				for childCondition in conditions {
					if childCondition.fulfilled == true {
						newFulfilled = true
						break
					}
				}

				fulfilled = newFulfilled

			default: break
		}
	}
}
