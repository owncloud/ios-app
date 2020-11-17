//
//  DiagnosticManager.swift
//  ownCloud
//
//  Created by Felix Schwarz on 31.07.20.
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
import ownCloudSDK

extension OCClassSettingsIdentifier {
	static let diagnostics : OCClassSettingsIdentifier = OCClassSettingsIdentifier("diagnostics")
}

extension OCClassSettingsKey {
	static let diagnosticsEnabled : OCClassSettingsKey = OCClassSettingsKey("enabled")
}

class DiagnosticManager: NSObject, OCClassSettingsSupport, OCClassSettingsUserPreferencesSupport {
	// MARK: - Class settings support
	static var classSettingsIdentifier: OCClassSettingsIdentifier {
		return .diagnostics
	}

	static func defaultSettings(forIdentifier identifier: OCClassSettingsIdentifier) -> [OCClassSettingsKey : Any]? {
		return [
			.diagnosticsEnabled : false
		]
	}

	static func allowUserPreference(forClassSettingsKey key: OCClassSettingsKey) -> Bool {
		return true
	}

	// MARK: - Shared instance
	static var shared = DiagnosticManager()

	// MARK: - Implementation
	var enabled : Bool {
		get {
			if let enabled = self.classSetting(forOCClassSettingsKey: .diagnosticsEnabled) as? Bool {
				return enabled
			}

			return false
		}

		set {
			DiagnosticManager.setUserPreferenceValue(newValue as NSSecureCoding, forClassSettingsKey: .diagnosticsEnabled)
		}
	}
}
