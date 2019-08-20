//
//  MediaFilesSettings.swift
//  ownCloud
//
//  Created by Michael Neuwert on 23.07.2019.
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

import UIKit

extension UserDefaults {

	enum MediaFilesKeys : String {
		case EnableStreamingKey = "media-enable-streaming"
	}

	public var streamingEnabled: Bool {
		set {
			self.set(newValue, forKey: MediaFilesKeys.EnableStreamingKey.rawValue)
		}

		get {
			return self.bool(forKey: MediaFilesKeys.EnableStreamingKey.rawValue)
		}
	}
}

class MediaFilesSettingsSection: SettingsSection {
	private var enableStreamingSwitchRow: StaticTableViewRow?

	override init(userDefaults: UserDefaults) {
		super.init(userDefaults: userDefaults)

		self.headerTitle = "Media Files".localized
		self.identifier = "media-files"

		enableStreamingSwitchRow = StaticTableViewRow(switchWithAction: { [weak self] (_, sender) in
			if let enableSwitch = sender as? UISwitch {
				self?.userDefaults.streamingEnabled = enableSwitch.isOn
			}
			}, title: "Streaming Enabled".localized, value: self.userDefaults.streamingEnabled)

		self.add(row: enableStreamingSwitchRow!)
	}
}
