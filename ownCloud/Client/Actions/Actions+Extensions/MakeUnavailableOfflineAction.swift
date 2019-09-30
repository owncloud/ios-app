//
//  MakeUnavailableOfflineAction.swift
//  ownCloud
//
//  Created by Felix Schwarz on 18.07.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

class MakeUnavailableOfflineAction: Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.makeUnavailableOffline") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Available Offline".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreFolder] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext context: ActionContext) -> ActionPosition {
		guard context.items.count > 0, let core = context.core else {
			return .none
		}

		// Only show if item is not already available offline
		var position : ActionPosition = .none

		for item in context.items {
			if let itemPolicies = core.retrieveAvailableOfflinePoliciesCovering(item, completionHandler: nil) {
				if itemPolicies.contains(where: { (itemPolicy) -> Bool in
					return (itemPolicy.path == item.path) || (itemPolicy.localID == item.localID)
				}) {
					position = .middle
				}
			}
		}

		return position
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0, let core = self.core else {
			completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		for item in context.items {
			if let itemPolicies = core.retrieveAvailableOfflinePoliciesCovering(item, completionHandler: nil) {
				for itemPolicy in itemPolicies {
					if (itemPolicy.path == item.path) || (itemPolicy.localID == item.localID) {
						core.removeAvailableOfflinePolicy(itemPolicy, completionHandler: nil)
					}
				}
			}
		}

		self.completed()
	}

	override func provideStaticRow() -> StaticTableViewRow? {
		// Add checkmark
		if let staticRow = super.provideStaticRow() {
			staticRow.cell?.accessoryType = .checkmark
			return staticRow
		}
		return nil
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem || location == .moreFolder {
			return UIImage(named: "unavailable-offline")
		}

		return nil
	}
}
