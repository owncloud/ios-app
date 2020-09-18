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
import ownCloudAppShared

extension UserDefaults {

	enum MediaFilesKeys : String {
		case DownloadMediaFiles = "media-download-files"
	}

	public var downloadMediaFiles: Bool {
		set {
			self.set(newValue, forKey: MediaFilesKeys.DownloadMediaFiles.rawValue)
		}

		get {
			return self.bool(forKey: MediaFilesKeys.DownloadMediaFiles.rawValue)
		}
	}
}

class MediaFilesSettingsSection: SettingsSection {
	private var enableStreamingSwitchRow: StaticTableViewRow?
	private var mediaUploadSettingsRow : StaticTableViewRow?

	override init(userDefaults: UserDefaults) {
		super.init(userDefaults: userDefaults)

		self.headerTitle = "Media Files".localized
		self.identifier = "media-files"

		enableStreamingSwitchRow = StaticTableViewRow(switchWithAction: { [weak self] (_, sender) in
			if let enableSwitch = sender as? UISwitch {
				self?.userDefaults.downloadMediaFiles = enableSwitch.isOn
			}
			}, title: "Download instead of streaming".localized, value: self.userDefaults.downloadMediaFiles, identifier: "download-media")

		self.add(row: enableStreamingSwitchRow!)

		mediaUploadSettingsRow = StaticTableViewRow(valueRowWithAction: { [weak self] (_, _) in
			self?.pushMediaUploadSettings()
		}, title: "Media Upload".localized, value: "", accessoryType: .disclosureIndicator, identifier: "media-upload")

		self.add(row: mediaUploadSettingsRow!)
	}

	private func pushMediaUploadSettings() {
		let mediaUploadSettingsViewController = MediaUploadSettingsViewController(style: .grouped)
		self.viewController?.navigationController?.pushViewController(mediaUploadSettingsViewController, animated: true)
	}
}
