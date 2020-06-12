//
//  AppStatistics.swift
//  ownCloudAppShared
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

import Foundation
import ownCloudSDK
import StoreKit

extension TimeInterval {
	public var days: Int {
		return Int(self / (3600.0 * 24.0))
	}
}

public class AppStatistics {

	enum UserDefaultsKeys: String {
		case firstLaunchDate, updateDate, lastInstalledVersion, lastPromptedAboutReviewDate
	}

	private var launchDate: Date
	private var updateDate: Date

	private var lastReviewPromptDate: Date? {
		get {
			return OCAppIdentity.shared.userDefaults?.object(forKey: UserDefaultsKeys.lastPromptedAboutReviewDate.rawValue) as? Date
		}

		set {
			OCAppIdentity.shared.userDefaults?.set(newValue, forKey: UserDefaultsKeys.lastPromptedAboutReviewDate.rawValue)
			OCAppIdentity.shared.userDefaults?.synchronize()
		}
	}

	public static let shared = AppStatistics()

	public var timeIntervalSinceFirstLaunch: TimeInterval {
		return launchDate.timeIntervalSinceNow
	}

	public var timeIntervalSinceUpdate: TimeInterval {
		return updateDate.timeIntervalSinceNow
	}

	private var appVersion: String? {
		guard let version = OCAppIdentity.shared.appVersion, let build = OCAppIdentity.shared.appBuildNumber else { return nil }
		return "\(version).\(build)"
	}

	init() {
		let now = Date()
		launchDate = now
		updateDate = now
	}

	public func update() {
		if let userDefaults = OCAppIdentity.shared.userDefaults {
			// Update launch date from user defaults
			if let firstLaunchDate = userDefaults.object(forKey: UserDefaultsKeys.firstLaunchDate.rawValue) as? Date {
				self.launchDate = firstLaunchDate
			}

			// Update the update launch date user defaults
			if let updateLaunchDate = userDefaults.object(forKey: UserDefaultsKeys.updateDate.rawValue) as? Date {
				self.updateDate = updateLaunchDate
			}

			// Reset update launch date if current version is different compared to stored ones
			if let lastVersion = userDefaults.object(forKey: UserDefaultsKeys.lastInstalledVersion.rawValue) as? String {
				if lastVersion != appVersion {
					self.updateDate = Date()
				}
			}

			// Update user defaults except for review prompt time stamp updated separately
			userDefaults.set(self.launchDate, forKey:  UserDefaultsKeys.firstLaunchDate.rawValue)
			userDefaults.set(self.appVersion, forKey: UserDefaultsKeys.lastInstalledVersion.rawValue)
			userDefaults.set(self.updateDate, forKey:  UserDefaultsKeys.firstLaunchDate.rawValue)

			// Persist user defaults
			userDefaults.synchronize()
		}
	}

	public func requestAppStoreReview(onceInDays:Int = 0) {
		var shallRequest = true

		if onceInDays > 0 {
			if let lastPromptDate = self.lastReviewPromptDate {
				if lastPromptDate.timeIntervalSinceNow.days < onceInDays {
					shallRequest = false
				}
			}
		}

		if shallRequest {
			self.lastReviewPromptDate = Date()
			OnMainThread {
				SKStoreReviewController.requestReview()
			}
		}
	}
}
