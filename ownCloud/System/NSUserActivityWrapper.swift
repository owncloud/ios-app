//
//  NSUserActivityWrapper.swift
//  ownCloud
//
//  Created by Matthias Hühne on 03.09.19.
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

import Foundation

class NSUserActivityWrapper: NSObject, NSCoding {
    private (set) var userActivity: NSUserActivity

    init(_ userActivity: NSUserActivity) {
        self.userActivity = userActivity
    }

    required init?(coder: NSCoder) {
        if let activityType = coder.decodeObject(forKey: "activityType") as? String {
            userActivity = NSUserActivity(activityType: activityType)
            userActivity.title = coder.decodeObject(forKey: "activityTitle") as? String
            userActivity.userInfo = coder.decodeObject(forKey: "activityUserInfo") as? [AnyHashable: Any]
        } else {
            return nil;
        }
    }

    func encode(with coder: NSCoder) {
        coder.encode(userActivity.activityType, forKey: "activityType")
        coder.encode(userActivity.title, forKey: "activityTitle")
        coder.encode(userActivity.userInfo, forKey: "activityUserInfo")
    }
}
