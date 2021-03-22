//
//  ScheduledTaskExtension.swift
//  ownCloud
//
//  Created by Michael Neuwert on 28.05.2019.
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
import ownCloudSDK

extension OCExtensionType {
	static let scheduledTask: OCExtensionType  =  OCExtensionType("app.scheduled_task") //!< Specific identifier for scheduled task extensions
}

extension OCExtensionLocationIdentifier {
	static let appLaunch: OCExtensionLocationIdentifier = OCExtensionLocationIdentifier("appLaunch") //!< Application launch
	static let appDidBecomeBackgrounded: OCExtensionLocationIdentifier = OCExtensionLocationIdentifier("appDidBecomeBackgrounded") //!< Application did come into background
	static let appDidComeToForeground: OCExtensionLocationIdentifier = OCExtensionLocationIdentifier("appDidComeToForeground") //!< Application did come into foreground
	static let appBackgroundFetch: OCExtensionLocationIdentifier = OCExtensionLocationIdentifier("appBackgroundFetch") //!< Application woke up to peform background fetch
}

class ScheduledTaskAction : NSObject {

	struct FeatureKeys {
		static let runOnLowBattery: String = "runOnLowBattery"
		static let runOnExternalPower: String = "runOnExternalPower"
		static let runOnWifi: String = "runOnWifi"
		static let photoLibraryChanged: String = "photoLibraryChanged"
	}

	typealias ActionResult = Result<Any?, Error>
	typealias ActionHandler = (ScheduledTaskAction) -> Void

	let gracePeriod: TimeInterval = 0.1

	class var identifier : OCExtensionIdentifier? { return nil }
	class var locations : [OCExtensionLocationIdentifier]? { return nil }
	class var features : [String : Any]? { return nil }

	var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
	var backgroundFetchCompletion: ((UIBackgroundFetchResult) -> Void)?

	var result : ActionResult?
	var completion : ActionHandler?
	var runUntil: Date?

	class var taskExtension : ScheduledTaskExtension {
		let objectProvider : OCExtensionObjectProvider = { (_ rawExtension, _ context, _ error) -> Any? in
			if (rawExtension as? ScheduledTaskExtension) != nil {
				return self.init()
			}

			return nil
		}

		return ScheduledTaskExtension(identifier: identifier!, locations: locations, features: features, objectProvider: objectProvider)
	}

	required override init() {
		super.init()
	}

	func run(background:Bool) {
		if background {
			self.backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {})
		}
	}

	func completed() {
		self.completion?(self)

		if self.backgroundFetchCompletion != nil {
			if let result = self.result {
				switch result {
				case .success(_):
					self.backgroundFetchCompletion!(.newData)
				case .failure(_):
					self.backgroundFetchCompletion!(.failed)
				}
			} else {
				self.backgroundFetchCompletion!(.noData)
			}
			self.backgroundFetchCompletion = nil
		}

		if self.backgroundTaskIdentifier != .invalid {
			UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
		}
	}

	var allowedToRun : Bool {
		if let deadline = runUntil {
			if (deadline.timeIntervalSince1970 + gracePeriod) >= Date().timeIntervalSince1970 {
				return false
			}
		}
		return true
	}
}

class ScheduledTaskExtension : OCExtension {
	init(identifier: OCExtensionIdentifier, locations: [OCExtensionLocationIdentifier]?, features: [String : Any]?, objectProvider: OCExtensionObjectProvider? = nil, customMatcher: OCExtensionCustomContextMatcher? = nil) {

		super.init(identifier: identifier, type: .scheduledTask, locations: locations, features: features, objectProvider: objectProvider, customMatcher: customMatcher)
	}
}
