//
//  MediaUploadSettingsViewController.swift
//  ownCloud
//
//  Created by Michael Neuwert on 22.05.20.
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
import ownCloudApp
import ownCloudAppShared

class MediaUploadSettingsViewController: StaticTableViewController {

	private var proPhotoSettingsSection: StaticTableViewSection?

	deinit {
		NotificationCenter.default.removeObserver(self, name: Notification.Name.OCBookmarkManagerListChanged, object: nil)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		navigationItem.title = "Media Upload".localized

		if let userDefaults = OCAppIdentity.shared.userDefaults {
			proPhotoSettingsSection = ProPhotoUploadSettingsSection(userDefaults: userDefaults)
		}

		if let userDefaults = OCAppIdentity.shared.userDefaults {
			self.addSection(MediaExportSettingsSection(userDefaults: userDefaults))

			if OCBookmarkManager.shared.bookmarks.count > 0 {
				self.addSection(AutoUploadSettingsSection(userDefaults: userDefaults))
				// TODO: Re-add this section when we re-gain an ability to run background NSURLSessions
				//self.addSection(BackgroundUploadsSettingsSection(userDefaults: userDefaults))
			}

			reconsiderProPhotoSettingsSection()
		}

		NotificationCenter.default.addObserver(self, selector: #selector(bookmarksChanged), name: Notification.Name.OCBookmarkManagerListChanged, object: nil)
	}

	private func reconsiderProPhotoSettingsSection() {

		guard let proSettingsSection = proPhotoSettingsSection else { return }

		if OCLicenseEnterpriseProvider.numberOfEnterpriseAccounts > 0 {
			if !self.sections.contains(proSettingsSection) {
				self.addSection(proSettingsSection)
			}
		} else {
			OCLicenseManager.shared.observeProducts(nil, features: [ .photoProFeatures ], in: OCLicenseEnvironment(), withOwner: self) { [weak self] (_, _, status) in
				self?.reconsiderProPhotoSettingsSection()
				switch status {
				case .granted:
					if self?.sections.contains(proSettingsSection) == false {
						self?.addSection(proSettingsSection)
					}
				default:
					self?.removeSection(proSettingsSection)
				}
			}
		}
	}

	@objc private func bookmarksChanged() {
		reconsiderProPhotoSettingsSection()
	}
}
