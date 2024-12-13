//
//  ConfidentalManager.swift
//  ownCloud
//
//  Created by Matthias Hühne on 09.12.24.
//  Copyright © 2024 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2024, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import ownCloudSDK

public class ConfidentalManager : NSObject {
	public static var shared: ConfidentalManager = ConfidentalManager()
}

public extension OCClassSettingsIdentifier {
	static let confidential = OCClassSettingsIdentifier("confidential")
}

public extension OCClassSettingsKey {
	static let allowScreenshots = OCClassSettingsKey("allow-screenshots")
	static let markConfidentalViews = OCClassSettingsKey("mark-confidental-views")
	static let allowOverwriteConfidentalMDMSettings = OCClassSettingsKey("allow-overwrite-confidental-mdm-settings")
}

extension ConfidentalManager : OCClassSettingsSupport {
	public static let classSettingsIdentifier : OCClassSettingsIdentifier = .confidential
	
	
	public var allowScreenshots: Bool {
		return ConfidentalManager.classSetting(forOCClassSettingsKey: .allowScreenshots) as? Bool ?? true
	}
	
	public var markConfidentalViews: Bool {
		return ConfidentalManager.classSetting(forOCClassSettingsKey: .markConfidentalViews) as? Bool ?? true
	}
	
	public var allowOverwriteConfidentalMDMSettings: Bool {
		return (self.confidentalSettingsEnabled && (ConfidentalManager.classSetting(forOCClassSettingsKey: .allowOverwriteConfidentalMDMSettings) as? Bool ?? true))
	}
	
	public var confidentalSettingsEnabled: Bool {
		if self.allowScreenshots || self.markConfidentalViews {
			return true
		}
		
		return false
	}
	
	public var disallowedActions: [String]? {
		if confidentalSettingsEnabled, !allowOverwriteConfidentalMDMSettings {
			return ["com.owncloud.action.openin", "com.owncloud.action.copy", "com.owncloud.action.collaborate", "action.allow-image-interactions"]
		}
		
		return nil
	}
	
	public static func defaultSettings(forIdentifier identifier: OCClassSettingsIdentifier) -> [OCClassSettingsKey : Any]? {
		if identifier == .confidential {
			return [
				.allowScreenshots : false,
				.markConfidentalViews : true,
				.allowOverwriteConfidentalMDMSettings : false
			]
		}
		
		return nil
	}
	
	public static func classSettingsMetadata() -> [OCClassSettingsKey : [OCClassSettingsMetadataKey : Any]]? {
		return [
			.allowScreenshots : [
				.type 		: OCClassSettingsMetadataType.boolean,
				.description	: "Controls whether screenshots are allowed or not. If not allowed confidental views will be marked as sensitive and are not visible in screenshots.",
				.category	: "Confidental",
				.status		: OCClassSettingsKeyStatus.debugOnly
			],
			.markConfidentalViews : [
				.type 		: OCClassSettingsMetadataType.boolean,
				.description	: "Controls if views which contains sensitive content contains a watermark or not.",
				.category	: "Confidental",
				.status		: OCClassSettingsKeyStatus.debugOnly
			],
			.allowOverwriteConfidentalMDMSettings : [
				.type 		: OCClassSettingsMetadataType.boolean,
				.description	: "Controls if confidental related MDM settings can be overwritten.",
				.category	: "Confidental",
				.status		: OCClassSettingsKeyStatus.debugOnly
			]
		]
	}
}
