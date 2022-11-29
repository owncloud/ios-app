//
//  AppUserActivity.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 29.11.22.
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

public enum AppUserActivityType: String {
	case accountList = "com.owncloud.ios-app.accountList"
	case openAccount = "com.owncloud.ios-app.openAccount"
	case openItem = "com.owncloud.ios-app.openItem"
}

public enum AppUserActivityUserInfoKey: String {
	case bookmarkUUID = "bookmarkUUID"
}

public extension NSUserActivity {
	static func userActivity(for appActivityType: AppUserActivityType) -> NSUserActivity {
		return NSUserActivity(activityType: appActivityType.rawValue)
	}

	static var accountList: NSUserActivity {
		return userActivity(for: .accountList)
	}

	static func openAccount(_ bookmark: OCBookmark) -> NSUserActivity {
		let activity = userActivity(for: .openAccount)

		activity.userInfo = [
			AppUserActivityUserInfoKey.bookmarkUUID.rawValue : bookmark.uuid.uuidString
		]

		return activity
	}
}
