//
//  RecentLocation.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 20.05.25.
//  Copyright © 2025 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2025, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

@objc class RecentLocation: NSObject, NSSecureCoding, OCDataItem, OCDataItemVersioning {
	var location: OCLocation?
	var timestamp: Date?

	var displayName: String?
	var driveName: String?

	init(location: OCLocation, timestamp: Date = .now, from core: OCCore) {
		self.location = location
		self.timestamp = timestamp

		self.displayName = location.displayName(with: core)

		if let driveID = location.driveID {
			self.driveName = core.drive(withIdentifier: driveID, attachedOnly: true)?.name
		}
	}

	// MARK: - NSSecureCoding
	static var supportsSecureCoding: Bool = true

	func encode(with coder: NSCoder) {
		coder.encode(location, forKey: "location")
		coder.encode(timestamp, forKey: "timestamp")
		coder.encode(displayName, forKey: "displayName")
		coder.encode(driveName, forKey: "driveName")
	}

	required init?(coder: NSCoder) {
		location = coder.decodeObject(of: OCLocation.self, forKey: "location")
		timestamp = coder.decodeObject(of: NSDate.self, forKey: "timestamp") as? Date
		displayName = coder.decodeObject(of: NSString.self, forKey: "displayName") as? String
		driveName = coder.decodeObject(of: NSString.self, forKey: "driveName") as? String
	}

	// MARK: - OCDataItem + Versioning
	var dataItemType: OCDataItemType {
		return .recentLocation
	}

	var dataItemReference: OCDataItemReference {
		return location?.dataItemReference ?? ("\(self)" as NSString)
	}

	var dataItemVersion: OCDataItemVersion {
		return "\(location?.dataItemVersion ?? ("-" as NSString))@\(timestamp?.timeIntervalSince1970 ?? 0)" as NSString
	}
}

extension OCDataItemType {
	static let recentLocation: OCDataItemType = OCDataItemType(rawValue: "recentLocation")
}
