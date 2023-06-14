//
//  OCBookmarkManager+Locking.swift
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

public extension OCBookmarkManager {
	static private let lastConnectedBookmarkUUIDDefaultsKey = "last-connected-bookmark-uuid"

	// MARK: - Defaults Keys
	static var lastBookmarkSelectedForConnection : OCBookmark? {
		get {
			if let bookmarkUUIDString = OCAppIdentity.shared.userDefaults?.string(forKey: OCBookmarkManager.lastConnectedBookmarkUUIDDefaultsKey), let bookmarkUUID = UUID(uuidString: bookmarkUUIDString) {
				return OCBookmarkManager.shared.bookmark(for: bookmarkUUID)
			}

			return nil
		}

		set {
			OCAppIdentity.shared.userDefaults?.set(newValue?.uuid.uuidString, forKey: OCBookmarkManager.lastConnectedBookmarkUUIDDefaultsKey)
		}
	}

	static var lockedBookmarks : [OCBookmark] = []

	@discardableResult static func attemptLock(bookmark: OCBookmark, presentErrorOn hostViewController: UIViewController? = nil, action: (_ bookmark: OCBookmark, _ completion: @escaping () -> Void) -> Void) -> Bool {
		if !isLocked(bookmark: bookmark, presentAlertOn: hostViewController) {
			self.lock(bookmark: bookmark)

			action(bookmark, {
				self.unlock(bookmark: bookmark)
			})

			return true
		}

		return false
	}

	static func lock(bookmark: OCBookmark) {
		OCSynchronized(self) {
			self.lockedBookmarks.append(bookmark)
		}
	}

	static func unlock(bookmark: OCBookmark) {
		OCSynchronized(self) {
			if let removeIndex = self.lockedBookmarks.firstIndex(of: bookmark) {
				self.lockedBookmarks.remove(at: removeIndex)
			}
		}
	}

	static func isLocked(bookmark: OCBookmark, presentAlertOn viewController: UIViewController? = nil, completion: ((_ isLocked: Bool) -> Void)? = nil) -> Bool {
		if self.lockedBookmarks.contains(bookmark) {
			if viewController != nil {
				let alertController = ThemedAlertController(title: NSString(format: "'%@' is currently locked".localized as NSString, bookmark.shortName as NSString) as String,
									    message: NSString(format: "An operation is currently performed that prevents connecting to '%@'. Please try again later.".localized as NSString, bookmark.shortName as NSString) as String,
									    preferredStyle: .alert)

				alertController.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: { (_) in
					completion?(true)
				}))

				viewController?.present(alertController, animated: true, completion: nil)
			}

			return true
		}

		completion?(false)

		return false
	}
}
