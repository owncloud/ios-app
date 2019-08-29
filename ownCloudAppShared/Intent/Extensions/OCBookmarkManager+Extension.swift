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

extension OCBookmarkManager {

	public var accountList : [Account] {
		var accountList : [Account] = []
		for bookmark in OCBookmarkManager.shared.bookmarks {
			let account = Account(identifier: bookmark.uuid.uuidString, display: bookmark.name ?? "")
			account.name = bookmark.shortName
			account.serverURL = bookmark.url
			account.uuid = bookmark.uuid.uuidString
			accountList.append(account)
		}

		return accountList
	}

	public func bookmark(for uuidString: String) -> OCBookmark? {
		for bookmark in OCBookmarkManager.shared.bookmarks {
			if bookmark.uuid.uuidString == uuidString {
				return bookmark
			}
		}

		return nil
	}

}
