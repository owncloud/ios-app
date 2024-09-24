//
//  RemoveFromSidebarAction.swift
//  ownCloud
//
//  Created by Felix Schwarz on 09.04.24.
//  Copyright © 2024 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2024, ownCloud GmbH.
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
import ownCloudAppShared

class RemoveFromSidebarAction: Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.removeFromSidebar") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return OCLocalizedString("Remove from sidebar", nil) }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.contextMenuItem, .moreItem, .accessibilityCustomAction] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext context: ActionContext) -> ActionPosition {
		guard context.items.count > 0 else {
			return .none
		}

		var sidebarItemLocationStrings: [String]?

		for item in context.items {
			if item.type != .collection {
				return .none
			}

			if sidebarItemLocationStrings == nil {
				sidebarItemLocationStrings = context.core?.vault.sidebarItems?.compactMap({ item in
					return item.location?.string
				})

				if sidebarItemLocationStrings == nil {
					return .none
				}
			}

			if let sidebarItemLocationStrings, let itemLocationString = item.location?.string {
				if sidebarItemLocationStrings.contains(itemLocationString) {
					return .middle
				}
			}
		}

		return .none
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0, let core = core, let sidebarItems = context.core?.vault.sidebarItems else {
			completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		for item in context.items {
			if let location = item.location {
				location.bookmarkUUID = context.core?.bookmark.uuid
				for sidebarItem in sidebarItems {
					if sidebarItem.location == location {
						core.vault.delete(sidebarItem)
						break
					}
				}
			}
		}
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return UIImage(named: "sidebar.leading.badge.minus")?.withRenderingMode(.alwaysTemplate)
	}

}
