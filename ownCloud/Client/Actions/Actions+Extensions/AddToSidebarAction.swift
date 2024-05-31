//
//  AddToSidebarAction.swift
//  ownCloud
//
//  Created by Felix Schwarz on 28.02.24.
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

class AddToSidebarAction: Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.addToSidebar") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Add to sidebar".localized }
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
				}) ?? []
			}

			if let sidebarItemLocationStrings, sidebarItemLocationStrings.count > 0, let itemLocationString = item.location?.string {
				if sidebarItemLocationStrings.contains(itemLocationString) {
					return .none
				}
			}
		}

		return .middle
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0, let core = core else {
			completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		for item in context.items {
			if let location = item.location {
				location.bookmarkUUID = context.core?.bookmark.uuid
				core.vault.add(OCSidebarItem(location: location))
			}
		}
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return UIImage(named: "sidebar.leading.badge.plus")?.withRenderingMode(.alwaysTemplate)
	}

}
