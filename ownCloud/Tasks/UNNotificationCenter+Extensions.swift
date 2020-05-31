//
//  UNNotificationCenter+Extensions.swift
//  ownCloud
//
//  Created by Michael Neuwert on 31.05.20.
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

import UserNotifications

extension UNUserNotificationCenter {
	class func postLocalNotification(with identifier:String, title:String, body:String, after:TimeInterval = 0.5, completion:((Error?)->Void)? = nil) {
		let center = Self.current()
		center.getNotificationSettings(completionHandler: { (settings) in
			if settings.authorizationStatus == .authorized {
				let content = UNMutableNotificationContent()

				content.title = title
				content.body = body

				let trigger = UNTimeIntervalNotificationTrigger(timeInterval: after, repeats: false)

				let request = UNNotificationRequest(identifier: identifier,
							  content: content, trigger: trigger)
				center.add(request, withCompletionHandler: { (error) in
					completion?(error)
				})
			}
		})
	}
}
