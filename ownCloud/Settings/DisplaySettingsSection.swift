//
//  DisplaySettingsSection.swift
//  ownCloud
//
//  Created by Felix Schwarz on 21.05.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK
import ownCloudApp

class DisplaySettingsSection: SettingsSection {
	override init(userDefaults: UserDefaults) {
		super.init(userDefaults: userDefaults)

		self.headerTitle = "Display settings".localized

		self.add(row: StaticTableViewRow(switchWithAction: { (row, _) in
			if let newShowHiddenFiles = row.value as? Bool {
				DisplaySettings.shared.showHiddenFiles = newShowHiddenFiles
			}
		}, title: "Show hidden files and folders".localized, value: DisplaySettings.shared.showHiddenFiles, identifier: "show-hidden-files-switch"))
	}
}
