//
//  AvailableOfflineAction.swift
//  ownCloud
//
//  Created by Felix Schwarz on 17.07.23.
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
import ownCloudAppShared

class AvailableOfflineAction: Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.availableOffline") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Make available offline".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreDetailItem, .moreFolder, .keyboardShortcut, .contextMenuItem, .accessibilityCustomAction] }
	override class var keyCommand : String? { return "O" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command, .alternate] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext context: ActionContext) -> ActionPosition {
		guard context.items.count > 0, let core = context.core else {
			return .none
		}

		for item in context.items {
			if let itemLocation = item.location, let policies = core.retrieveAvailableOfflinePoliciesCovering(item, completionHandler: nil) {
				for policy in policies {
					// Only show if item is not already available offline via parent item
					if let policyLocation = policy.location, itemLocation.isLocated(in: policyLocation) && itemLocation != policyLocation {
						return .none
					}
				}
			}
		}

		return .middle
	}

	var isAvailableOffline: Bool {
		get {
			var availableOfflineCount: Int = 0

			if let core {
				for item in context.items {
					if let policies = core.retrieveAvailableOfflinePoliciesCovering(item, completionHandler: nil) {
						if policies.count > 0 {
							availableOfflineCount += 1
						}
					}
				}
			}

			return (availableOfflineCount == context.items.count)
		}

		set {
			if let core {
				if newValue {
					// Make available offline
					for item in context.items {
						core.makeAvailableOffline(item, options: [.skipRedundancyChecks : true, .convertExistingLocalDownloads : true], completionHandler: nil)
					}
				} else {
					// Make unavailable offline
					for item in context.items {
						if let itemPolicies = core.retrieveAvailableOfflinePoliciesCovering(item, completionHandler: nil) {
							for itemPolicy in itemPolicies {
								if (itemPolicy.location == item.location) || (itemPolicy.localID == item.localID) {
									core.removeAvailableOfflinePolicy(itemPolicy, completionHandler: nil)
								}
							}
						}
					}
				}
			}
		}
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0 else {
			completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let newAvailableOffline = !isAvailableOffline

		isAvailableOffline = newAvailableOffline
		availableOfflineSwitch?.isOn = isAvailableOffline

		self.completed()
	}

	var availableOfflineSwitch: UISwitch?

	override func provideStaticRow() -> StaticTableViewRow? {
		if let staticRow = super.provideStaticRow() {
			availableOfflineSwitch = UISwitch(frame: .zero, primaryAction: UIAction(handler: { [weak self] action in
				if let self, let availableOfflineSwitch = self.availableOfflineSwitch {
					self.isAvailableOffline = availableOfflineSwitch.isOn
				}
			}))

			availableOfflineSwitch?.isOn = isAvailableOffline

			staticRow.cell?.accessoryView = availableOfflineSwitch

			return staticRow
		}
		return nil
	}

	override func provideAccessibilityCustomAction() -> UIAccessibilityCustomAction {
		let customAction = super.provideAccessibilityCustomAction()

		if self.isAvailableOffline {
			customAction.name = "Make unavailable offline".localized
		} else {
			customAction.name = "Make available offline".localized
		}

		return customAction
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return UIImage(named: "available-offline")?.withRenderingMode(.alwaysTemplate)
	}

}
