//
//  MediaExportSettingsSection.swift
//  ownCloud
//
//  Created by Michael Neuwert on 22.05.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 20120, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit
import Photos
import ownCloudSDK
import ownCloudAppShared

extension UserDefaults {

	enum MediaExportKeys : String {
		case ConvertHEICtoJPEGKey = "convert-heic-to-jpeg"
		case ConvertVideosToMP4Key = "convert-videos-to-mp4"
		case PreserveOriginalFilenames = "preserve-original-filenames"
	}

	public var convertHeic: Bool {
		set {
			self.set(newValue, forKey: MediaExportKeys.ConvertHEICtoJPEGKey.rawValue)
		}

		get {
			return self.bool(forKey: MediaExportKeys.ConvertHEICtoJPEGKey.rawValue)
		}
	}

	public var convertVideosToMP4: Bool {
		set {
			self.set(newValue, forKey: MediaExportKeys.ConvertVideosToMP4Key.rawValue)
		}

		get {
            return self.bool(forKey: MediaExportKeys.ConvertVideosToMP4Key.rawValue)
		}
	}

	public var preserveOriginalMediaFileNames: Bool {
		set {
			self.set(newValue, forKey: MediaExportKeys.PreserveOriginalFilenames.rawValue)
		}

		get {
			return self.bool(forKey: MediaExportKeys.PreserveOriginalFilenames.rawValue)
		}
	}
}

class MediaExportSettingsSection: SettingsSection {

	private var convertPhotosSwitchRow: StaticTableViewRow?
	private var convertVideosSwitchRow: StaticTableViewRow?
	private var preserveMediaFileNamesSwitchRow: StaticTableViewRow?

	override init(userDefaults: UserDefaults) {

		super.init(userDefaults: userDefaults)

		self.headerTitle = OCLocalizedString("Media Export", nil)
		self.identifier = "media-export"

		convertPhotosSwitchRow = StaticTableViewRow(switchWithAction: { [weak self] (_, sender) in
			if let convertSwitch = sender as? UISwitch {
				self?.userDefaults.convertHeic = convertSwitch.isOn
			}
			}, title: OCLocalizedString("Convert HEIC to JPEG", nil), value: self.userDefaults.convertHeic, identifier: "convert_heic_to_jpeg")

		convertVideosSwitchRow = StaticTableViewRow(switchWithAction: { [weak self] (_, sender) in
			if let convertSwitch = sender as? UISwitch {
				self?.userDefaults.convertVideosToMP4 = convertSwitch.isOn
			}
			}, title: OCLocalizedString("Convert videos to MP4", nil), value: self.userDefaults.convertVideosToMP4, identifier: "convert_to_mp4")

		preserveMediaFileNamesSwitchRow = StaticTableViewRow(switchWithAction: { [weak self] (_, sender) in
			if let convertSwitch = sender as? UISwitch {
				self?.userDefaults.preserveOriginalMediaFileNames = convertSwitch.isOn
			}
			}, title: OCLocalizedString("Preserve original media file names", nil), value: self.userDefaults.preserveOriginalMediaFileNames, identifier: "preserve_media_file_names")

		self.add(row: convertPhotosSwitchRow!)
		self.add(row: convertVideosSwitchRow!)
		self.add(row: preserveMediaFileNamesSwitchRow!)
	}
}
