//
//  RequestReviewTaskExtension.swift
//  ownCloud
//
//  Created by Michael Neuwert on 10.06.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2020, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import ownCloudAppShared
import ownCloudSDK

class RequestReviewTaskExtension : ScheduledTaskAction {

    override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.request-review") }
    override class var locations : [OCExtensionLocationIdentifier]? { return [.appDidComeToForeground] }

    override func run(background:Bool) {
        // Make sure completed is called when run method scope is left
        defer {
            self.completed()
        }

        // We should only run in foreground
        guard background == false else { return }

        // Make sure there is at least one bookmark configured, to not bother users who have never configured any accounts
        guard OCBookmarkManager.shared.bookmarks.count > 0 else { return }

        // Make sure at least 14 days have elapsed since the first launch of the app
        guard AppStatistics.shared.timeIntervalSinceFirstLaunch.days >= 14 else { return }

        // Make sure at least 7 days have elapsed since first launch of current version
        guard AppStatistics.shared.timeIntervalSinceUpdate.days >= 7 else { return }

        // Make sure at least 230 have elapsed since last prompting
        AppStatistics.shared.requestAppStoreReview(onceInDays: 230)
    }
}
