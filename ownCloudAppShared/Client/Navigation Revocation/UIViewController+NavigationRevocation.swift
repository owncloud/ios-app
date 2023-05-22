//
//  UIViewController+NavigationRevocation.swift
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

public struct RevocationTriggers: OptionSet {
	public let rawValue: Int
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}

	static public let connectionClosed = RevocationTriggers(rawValue: 1)
	static public let driveRemoved = RevocationTriggers(rawValue: 2)
}

public extension UIViewController {
	@discardableResult func revoke(in context: ClientContext?, when revocationTriggers: RevocationTriggers = [ .connectionClosed ]) -> UIViewController {
		guard let context = context else { return self }

		var triggers: [NavigationRevocationTrigger] = []
		var events: [NavigationRevocationEvent] = []

		// Log.debug("Register revokation of view controller: \(self) \(self.navigationItem.titleLabelText ?? "?")")

		if let bookmarkUUID = context.accountConnection?.bookmark.uuid {
			if revocationTriggers.contains(.connectionClosed) {
				events.append(.connectionClosed(bookmarkUUID: bookmarkUUID))
			}

			if revocationTriggers.contains(.driveRemoved) {
				if let drivesDataSource = context.core?.subscribedDrivesDataSource,
				   let driveID = context.drive?.identifier as? OCDataItemReference {
					let driveTrigger = NavigationRevocationTrigger(itemRemovalTriggerFor: drivesDataSource, itemRefs: [ driveID ], bookmarkUUID: bookmarkUUID)
					triggers.append(driveTrigger)
				}
			}
		}

		if triggers.count > 0 || events.count > 0 {
			let navigationRevocationHandler = context.navigationRevocationHandler

			NavigationRevocationAction(triggeredBy: events, for: triggers, action: { [weak self, weak context, weak navigationRevocationHandler] event, action in
				if let self = self, let event = event {
					if let navigationRevocationHandler {
						navigationRevocationHandler.handleRevocation(event: event, context: context, for: self)
					} else {
						Log.warning("navigation revocation triggered, but navigationRevocationHandler is gone")
					}
				} else {
					Log.warning("navigation revocation triggered, but viewController is gone")
				}
			}).register(for: self, globally: true)
		}

		return self
	}
}
