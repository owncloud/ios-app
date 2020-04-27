//
//  NotificationManager.swift
//  ownCloud
//
//  Created by Matthias Hühne on 26.04.20.
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

import UIKit

class NotificationManager: NSObject {

	static func showNotification(title: String, body: String, identifier: String) {

		let center = UNUserNotificationCenter.current()
		center.getNotificationSettings { (settings) in
			if settings.authorizationStatus == .notDetermined {
				center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, _) in
					if granted {
						NotificationManager.deliverNotification(title: title, body: body, identifier: identifier)
					}
				}
			} else if settings.authorizationStatus == .authorized {
				NotificationManager.deliverNotification(title: title, body: body, identifier: identifier)
			}
		}
	}

	private static func deliverNotification(title: String, body: String, identifier: String) {
		let content = UNMutableNotificationContent()
		content.title = title
		content.body = body

		let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

		let center = UNUserNotificationCenter.current()
		center.add(request)
	}
}
