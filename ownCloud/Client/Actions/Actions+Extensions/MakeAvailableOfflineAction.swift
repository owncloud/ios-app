//
//  MakeAvailableOfflineAction.swift
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

class MakeAvailableOfflineAction: Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.makeAvailableOffline") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Make available offline".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreFolder] }
	override class var keyCommand : String? { return "O" }

	// MARK: - Extension matching
	override class func applicablePosition(forContext context: ActionContext) -> ActionPosition {
		guard context.items.count > 0, let core = context.core else {
			return .none
		}

		// Only show if item is not already available offline
		var position : ActionPosition = .middle

		for item in context.items {
			if let policies = core.retrieveAvailableOfflinePoliciesCovering(item, completionHandler: nil) {
				if policies.count > 0 {
					position = .none
					break
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
			core.makeAvailableOffline(item, options: [.skipRedundancyChecks : true, .convertExistingLocalDownloads : true], completionHandler: nil)
		}

		self.completed()
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem || location == .moreFolder {
			return UIImage(named: "available-offline")
		}

		return nil
	}
}
