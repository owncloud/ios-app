//
//  PhotoUploadSection.swift
//  ownCloud
//
//  Created by Michael Neuwert on 25.04.2019.
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

	enum PhtoUploadKeys : String {
		case ConvertHEICtoJPEGKey = "convert-heic-to-jpeg"
	}

	public var convertHeic: Bool {
		set {
			self.set(newValue, forKey: PhtoUploadKeys.ConvertHEICtoJPEGKey.rawValue)
		}

		get {
			return self.bool(forKey: PhtoUploadKeys.ConvertHEICtoJPEGKey.rawValue)
		}
	}
}

class PhotoUploadSettingsSection: SettingsSection {

	private var convertSwitchRow: StaticTableViewRow?

	override init(userDefaults: UserDefaults) {

		super.init(userDefaults: userDefaults)

		self.headerTitle = "Photo Upload".localized
		self.identifier = "photo-upload"

		convertSwitchRow = StaticTableViewRow(switchWithAction: { [weak self] (_, sender) in
			if let convertSwitch = sender as? UISwitch {
				self?.userDefaults.convertHeic = convertSwitch.isOn
			}
			}, title: "Convert HEIC to JPEG".localized, value: self.userDefaults.convertHeic)

		self.add(row: convertSwitchRow!)
	}

}
