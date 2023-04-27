//
//  NavigationRevocationAction.swift
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

public enum NavigationRevocationEvent: Equatable {
	case connectionClosed(bookmarkUUID: UUID)
	case connectionStateLeft(bookmarkUUID: UUID, status: OCCoreConnectionStatus)
	case connectionStateEntered(bookmarkUUID: UUID, status: OCCoreConnectionStatus)
	case driveRemoved(driveID: String, bookmarkUUID: UUID)
	case itemRemoved(itemReference: OCDataItemReference, dataSource: String, bookmarkUUID: UUID?)

	public func send() {
		NavigationRevocationManager.shared.handle(event: self)
	}
}

open class NavigationRevocationAction: NSObject {
	private var objcAssociationHandle = 1

	public typealias EventMatcher = (NavigationRevocationEvent) -> Bool
	public typealias EventAction = (NavigationRevocationEvent?, NavigationRevocationAction) -> Void

	open var eventMatcher: EventMatcher
	open var action: EventAction?

	open var triggers: [NavigationRevocationTrigger]? {
		willSet {
			setAction(nil, on: triggers)
		}

		didSet {
			setAction(self, on: triggers)
		}
	}

	private func setAction(_ action: NavigationRevocationAction?, on triggers: [NavigationRevocationTrigger]?) {
		if let triggers {
			for trigger in triggers {
				trigger.action = action
			}
		}
	}

	init(eventMatcher: @escaping EventMatcher, action: @escaping EventAction) {
		self.eventMatcher = eventMatcher
		self.action = action
		super.init()
	}

	convenience init(triggeredBy events: [NavigationRevocationEvent]? = nil, for triggers: [NavigationRevocationTrigger]? = nil, action: @escaping EventAction) {
		self.init(eventMatcher: { (event) in
			return events?.contains(event) ?? false
		}, action: action)

		self.triggers = triggers
		setAction(self, on: triggers)
	}

	open func register(for obj: NSObject? = nil, globally: Bool = false) {
		if globally {
			NavigationRevocationManager.shared.register(action: self)
		}

		if let obj = obj {
			objc_setAssociatedObject(obj, &self.objcAssociationHandle, self, .OBJC_ASSOCIATION_RETAIN)
		}
	}

	open func unregister(for obj: NSObject? = nil, globally: Bool = false) {
		if globally {
			NavigationRevocationManager.shared.unregister(action: self)
		}

		if let obj = obj {
			objc_setAssociatedObject(obj, &self.objcAssociationHandle, nil, .OBJC_ASSOCIATION_RETAIN)
		}
	}

	open func handle(event: NavigationRevocationEvent) -> Bool {
		if eventMatcher(event) {
			return performAction(with: event)
		}
		return false
	}

	@discardableResult open func performAction(with event: NavigationRevocationEvent?) -> Bool {
		var action: EventAction?

		OCSynchronized(self) {
			action = self.action
			self.action = nil
		}

		if let action = action {
			action(event, self)
			return true
		}

		return false
	}
}

public extension NavigationRevocationAction {
	static func forEvent(_ matchEvent: NavigationRevocationEvent, action: @escaping NavigationRevocationAction.EventAction) -> NavigationRevocationAction {
		return NavigationRevocationAction(eventMatcher: { event in
			return event == matchEvent
		}, action: action)
	}

	static func forClosing(connection: AccountConnection, action: @escaping NavigationRevocationAction.EventAction) -> NavigationRevocationAction {
		return forEvent(.connectionClosed(bookmarkUUID: connection.bookmark.uuid), action: action)
	}

	static func forRemoval(connection: AccountConnection, driveID: String, action: @escaping NavigationRevocationAction.EventAction) -> NavigationRevocationAction {
		return forEvent(.driveRemoved(driveID: driveID, bookmarkUUID: connection.bookmark.uuid), action: action)
	}

	static func forRemoval(itemReference: OCDataItemReference, dataSource: OCDataSource, bookmarkUUID: UUID? = nil, action: @escaping NavigationRevocationAction.EventAction) -> NavigationRevocationAction {
		return forEvent(.itemRemoved(itemReference: itemReference, dataSource: dataSource.uuid, bookmarkUUID: bookmarkUUID), action: action)
	}
}
