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

	var accountList : [Account] {
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

	func bookmark(for uuidString: String) -> OCBookmark? {
		return OCBookmarkManager.shared.bookmarks.filter({ $0.uuid.uuidString == uuidString}).first
	}

	func accountBookmark(for uuidString: String) -> (OCBookmark, Account)? {
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
