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

class DiagnosticManager: NSObject {
	static var diagnosticsEnabledKey : String = "diagnostics-enabled"

	static var shared = DiagnosticManager()

	var enabled : Bool {
		get {
			if let enabledNumber = OCAppIdentity.shared.userDefaults?.object(forKey: DiagnosticManager.diagnosticsEnabledKey), let enabled = enabledNumber as? Bool {
				return enabled
			}

			return false
		}

		set {
			OCAppIdentity.shared.userDefaults?.set(newValue, forKey: DiagnosticManager.diagnosticsEnabledKey)
		}
	}
}
