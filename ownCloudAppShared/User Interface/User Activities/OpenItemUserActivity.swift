//
//  OpenItemUserActivity.swift
//  ownCloud
//
//  Created by Matthias Hühne on 27.09.19.
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

public extension OCBookmark {
	static let ownCloudOpenAccountActivityType     = "com.owncloud.ios-app.openAccount"
	static let ownCloudOpenAccountPath           	= "openAccount"
	static let ownCloudOpenAccountAccountUuidKey	= "accountUuid"

	var openAccountUserActivity: NSUserActivity {
		let userActivity = NSUserActivity(activityType: OCBookmark.ownCloudOpenAccountActivityType)
		userActivity.title = OCBookmark.ownCloudOpenAccountPath
		userActivity.userInfo = [OCBookmark.ownCloudOpenAccountAccountUuidKey: uuid.uuidString]
		return userActivity
	}
}

public class OpenItemUserActivity : NSObject {
	static public let ownCloudOpenItemActivityType = "com.owncloud.ios-app.openItem"
	static public let ownCloudOpenItemPath         = "openItem"
	static public let ownCloudOpenItemUuidKey      = "itemUuid"

	public var item : OCItem
	public var bookmark : OCBookmark

	public var openItemUserActivity: NSUserActivity {
		let userActivity = NSUserActivity(activityType: OpenItemUserActivity.ownCloudOpenItemActivityType)
		userActivity.title = OpenItemUserActivity.ownCloudOpenItemPath
		userActivity.userInfo = [OpenItemUserActivity.ownCloudOpenItemUuidKey: item.localID as Any, OCBookmark.ownCloudOpenAccountAccountUuidKey : bookmark.uuid.uuidString]
		return userActivity
	}

	public init(detailItem: OCItem, detailBookmark: OCBookmark) {
		item = detailItem
		bookmark = detailBookmark
	}
}
