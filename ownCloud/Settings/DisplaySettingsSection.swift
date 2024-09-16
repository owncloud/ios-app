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
import ownCloudAppShared

class DisplaySettingsSection: SettingsSection {
	override init(userDefaults: UserDefaults) {
		super.init(userDefaults: userDefaults)

		self.headerTitle = OCLocalizedString("Advanced settings", nil)

		self.add(row: StaticTableViewRow(switchWithAction: { (row, _) in
			if let newShowHiddenFiles = row.value as? Bool {
				DisplaySettings.shared.showHiddenFiles = newShowHiddenFiles
			}
		}, title: OCLocalizedString("Show hidden files and folders", nil), value: DisplaySettings.shared.showHiddenFiles, identifier: "show-hidden-files-switch"))

		self.add(row: StaticTableViewRow(switchWithAction: { (row, _) in
			if let newSortFolderFirst = row.value as? Bool {
				DisplaySettings.shared.sortFoldersFirst = newSortFolderFirst
			}
		}, title: OCLocalizedString("Show folders on top", nil), value: DisplaySettings.shared.sortFoldersFirst, identifier: "sort-folders-first"))

		self.add(row: StaticTableViewRow(switchWithAction: { (row, _) in
			if let disableDragging = row.value as? Bool {
				DisplaySettings.shared.preventDraggingFiles = disableDragging
			}
		}, title: OCLocalizedString("Disable gestures", nil), subtitle: OCLocalizedString("Prevent dragging of files and folders and multiselection using system defined gestures", nil), value: DisplaySettings.shared.preventDraggingFiles, identifier: "prevent-dragging-files-switch"))

		self.add(row: StaticTableViewRow(switchWithAction: { (row, _) in
			if let diagnosticsEnabled = row.value as? Bool {
				DiagnosticManager.shared.enabled = diagnosticsEnabled
			}
		}, title: OCLocalizedString("Enable diagnostics", nil), value: DiagnosticManager.shared.enabled, identifier: "diagnostics-enabled"))

		if OCLicenseQAProvider.isQAUnlockPossible {
			self.add(row: StaticTableViewRow(switchWithAction: { (row, _) in
				if let qaUnlockedProFeatures = row.value as? Bool {
					OCLicenseQAProvider.isQAUnlockEnabled = qaUnlockedProFeatures
				}
			}, title: OCLocalizedString("Enable Pro Features (QA)", nil), value: OCLicenseQAProvider.isQAUnlockEnabled, identifier: "enable-pro-features"))
		}
	}
}
