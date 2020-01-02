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

let ownCloudOpenItemActivityType       = "com.owncloud.ios-app.openItem"
let ownCloudOpenItemPath               = "openItem"
let ownCloudOpenItemUuidKey         = "itemUuid"

class OpenItemUserActivity : NSObject {

	var item : OCItem
	var bookmark : OCBookmark

	var openItemUserActivity: NSUserActivity {
		let userActivity = NSUserActivity(activityType: ownCloudOpenItemActivityType)
		userActivity.title = ownCloudOpenItemPath
		userActivity.userInfo = [ownCloudOpenItemUuidKey: item.localID!, ownCloudOpenAccountAccountUuidKey : bookmark.uuid.uuidString]
		return userActivity
	}

	init(detailItem: OCItem, detailBookmark: OCBookmark) {
		item = detailItem
		bookmark = detailBookmark
	}
}
