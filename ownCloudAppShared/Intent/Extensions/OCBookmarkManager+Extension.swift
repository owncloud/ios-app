//
//  Account+Extension.swift
//  ownCloudAppShared
//
//  Created by Matthias Hühne on 29.08.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2018, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit
import ownCloudSDK

@available(iOS 13.0, *)
extension OCBookmarkManager {

	public var accountList : [Account] {
		var accountList : [Account] = []
		accountList = OCBookmarkManager.shared.bookmarks.map { (bookmark) -> Account in
			let account = Account(identifier: bookmark.uuid.uuidString, display: bookmark.shortName)
			account.name = bookmark.shortName
			account.serverURL = bookmark.url
			account.uuid = bookmark.uuid.uuidString

			return account
		}

		return accountList
	}

	public func accountBookmark(for uuidString: String) -> (OCBookmark, Account)? {
		if let bookmark = bookmark(for: uuidString) {
			let account = Account(identifier: bookmark.uuid.uuidString, display: bookmark.shortName)
			account.name = bookmark.shortName
			account.serverURL = bookmark.url
			account.uuid = bookmark.uuid.uuidString

			return (bookmark, account)
		}

		return nil
	}
}

extension OCBookmarkManager {

	public func bookmark(for uuidString: String) -> OCBookmark? {
		return OCBookmarkManager.shared.bookmarks.filter({ $0.uuid.uuidString == uuidString}).first
	}

	static private let lastConnectedBookmarkUUIDDefaultsKey = "last-connected-bookmark-uuid"

	// MARK: - Defaults Keys
	static public var lastBookmarkSelectedForConnection : OCBookmark? {
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

	static public var lockedBookmarks : [OCBookmark] = []

	static public func lock(bookmark: OCBookmark) {
		OCSynchronized(self) {
			self.lockedBookmarks.append(bookmark)
		}
	}

	static public func unlock(bookmark: OCBookmark) {
		OCSynchronized(self) {
			if let removeIndex = self.lockedBookmarks.index(of: bookmark) {
				self.lockedBookmarks.remove(at: removeIndex)
			}
		}
	}

	static public func isLocked(bookmark: OCBookmark, presentAlertOn viewController: UIViewController? = nil, completion: ((_ isLocked: Bool) -> Void)? = nil) -> Bool {
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
