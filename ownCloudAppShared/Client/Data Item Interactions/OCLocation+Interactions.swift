//
//  OCLocation+Interactions.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 21.11.22.
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
import ownCloudApp

// MARK: - Selection > Open
extension OCLocation : DataItemSelectionInteraction {
	public func openItem(from viewController: UIViewController?, with context: ClientContext?, animated: Bool, pushViewController: Bool, completion: ((Bool) -> Void)?) -> UIViewController? {
		let driveContext = ClientContext(with: context, modifier: { context in
			if let driveID = self.driveID, let core = context.core {
				context.drive = core.drive(withIdentifier: driveID)
			}
		})
		let query = OCQuery(for: self)
		DisplaySettings.shared.updateQuery(withDisplaySettings: query)

		let locationViewController = context?.pushViewControllerToNavigation(context: driveContext, provider: { context in
			let location = OCLocation(bookmarkUUID: self.bookmarkUUID, driveID: self.driveID, path: self.path)

			if location.bookmarkUUID == nil {
				location.bookmarkUUID = driveContext.core?.bookmark.uuid
			}

			let viewController = ClientItemViewController(context: context, query: query, location: location)
			viewController.navigationBookmark = BrowserNavigationBookmark.from(dataItem: location, clientContext: context, restoreAction: .open)
			viewController.revoke(in: context, when: [ .connectionClosed, .driveRemoved ])

			return viewController
		}, push: pushViewController, animated: animated)

		completion?(true)

		return locationViewController
	}

	public func revealItem(from viewController: UIViewController?, with context: ClientContext?, animated: Bool, pushViewController: Bool, completion: ((Bool) -> Void)?) -> UIViewController? {
		if let core = context?.core {
			if let item = try? core.cachedItem(at: self) {
				return item.revealItem(from: viewController, with: context, animated: animated, pushViewController: pushViewController, completion: completion)
			}
		}

		completion?(true)

		return nil
	}
}

// MARK: - BrowserNavigationBookmark (re)store
extension OCLocation: DataItemBrowserNavigationBookmarkReStore {
	public func store(in bookmarkUUID: UUID?, context: ClientContext?, restoreAction: BrowserNavigationBookmark.BookmarkRestoreAction) -> BrowserNavigationBookmark? {
		let navigationBookmark = BrowserNavigationBookmark(for: self, in: bookmarkUUID, restoreAction: restoreAction)
		var storeLocation = self

		// Make sure OCLocation.bookmarkUUID is set
		if storeLocation.bookmarkUUID == nil, let bookmarkUUID, let locationCopy = copy() as? OCLocation {
			locationCopy.bookmarkUUID = bookmarkUUID
			storeLocation = locationCopy
		}

		navigationBookmark?.location = storeLocation

		return navigationBookmark
	}

	public static func restore(navigationBookmark: BrowserNavigationBookmark, in viewController: UIViewController?, with context: ClientContext?, completion: ((Error?, UIViewController?) -> Void)) {
		if let location = navigationBookmark.location {
			let viewController = location.openItem(from: viewController, with: context, animated: false, pushViewController: false, completion: nil)
			completion(nil, viewController)
		} else {
			completion(NSError(ocError: .insufficientParameters), nil)
		}
	}
}
