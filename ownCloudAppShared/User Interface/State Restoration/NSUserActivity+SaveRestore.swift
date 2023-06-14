//
//  NSUserActivity+SaveRestore.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 08.02.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

public enum UserActivityOption: String {
	case clientContext	//!< ClientContext instance
}

public protocol UserActivityCapture: NSObject {
	func captureUserActivityData(with options: [UserActivityOption : NSObject]?) -> Data?
}

public protocol UserActivityRestoration: NSObject {
	static func restoreFromUserActivity(with data: Data?, options: [UserActivityOption.RawValue : NSObject]?, completion: NSUserActivity.RestoreCompletionHandler?)
}

public extension NSUserActivity {
	private static let CaptureRestoreActivityType = "com.owncloud.captureRestoreActivityType"
	private static let UserInfoKeyClassName = "className"
	private static let UserInfoKeyActivityData = "activityData"

	typealias RestoreCompletionHandler = (Error?) -> Void

	var isRestorableActivity: Bool {
		return (activityType == NSUserActivity.CaptureRestoreActivityType) && (userInfo?[NSUserActivity.UserInfoKeyClassName] != nil)
	}

	static func capture(from object: UserActivityCapture, with options: [UserActivityOption : NSObject]? = nil) -> NSUserActivity? {
		let activity = NSUserActivity(activityType: NSUserActivity.CaptureRestoreActivityType)
		let className = NSStringFromClass(type(of: object))

		activity.addUserInfoEntries(from: [
			UserInfoKeyClassName : className
		])

		if let activityData = object.captureUserActivityData(with: options) {
			activity.addUserInfoEntries(from: [
				UserInfoKeyActivityData : activityData
			])
		}

		return activity
	}

	func restore(with options: [UserActivityOption.RawValue : NSObject]? = nil, completion: RestoreCompletionHandler? = nil) {
		guard let className = userInfo?[NSUserActivity.UserInfoKeyClassName] as? String, isRestorableActivity else {
			completion?(NSError(ocError: .internal))
			return
		}

		if let restoreClass = NSClassFromString(className) {
			let activityData = userInfo?[NSUserActivity.UserInfoKeyActivityData] as? Data

			if let restoration = restoreClass as? UserActivityRestoration.Type {
				restoration.restoreFromUserActivity(with: activityData, options: options, completion: completion)
			} else {
				completion?(NSError(ocError: .featureNotImplemented))
			}
		} else {
			completion?(NSError(ocError: .featureNotImplemented))
		}
	}
}
