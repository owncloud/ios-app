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
	private var autoUploadSection : AutoUploadSettingsSection?
	private var backgroundUploadsSection : BackgroundUploadsSettingsSection?
	private var licenseObserver : OCLicenseObserver?

	deinit {
		NotificationCenter.default.removeObserver(self, name: .OCBookmarkManagerListChanged, object: nil)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		navigationItem.title = "Media Upload".localized

		if let userDefaults = OCAppIdentity.shared.userDefaults {
			proPhotoSettingsSection = ProPhotoUploadSettingsSection(userDefaults: userDefaults)
			self.addSection(MediaExportSettingsSection(userDefaults: userDefaults))
		}

		NotificationCenter.default.addObserver(self, selector: #selector(reconsiderSections), name: .OCBookmarkManagerListChanged, object: nil)

		licenseObserver = OCLicenseManager.shared.observeProducts(nil, features: [ .photoProFeatures ], in: OCLicenseEnvironment(), withOwner: self) { [weak self] (_, _, _) in
			self?.reconsiderSections()
		}
	}

	@objc private func reconsiderSections() {
		OnMainThread {
			guard let proSettingsSection = self.proPhotoSettingsSection, let userDefaults = OCAppIdentity.shared.userDefaults else { return }

			if OCBookmarkManager.shared.bookmarks.count > 0 {
				if self.autoUploadSection == nil {
					self.autoUploadSection = AutoUploadSettingsSection(userDefaults: userDefaults)

					self.autoUploadSection?.changeHandler = { [weak self] in
						self?.backgroundUploadsSection?.updateUI()
					}
				}
				if self.backgroundUploadsSection == nil {
					self.backgroundUploadsSection = BackgroundUploadsSettingsSection(userDefaults: userDefaults)
				}

				if let autoUploadSection = self.autoUploadSection, !autoUploadSection.attached {
					self.addSection(autoUploadSection)
				}
				if let backgroundUploadsSection = self.backgroundUploadsSection {
					if !backgroundUploadsSection.attached, backgroundUploadsSection.rows.count > 0, (userDefaults.instantUploadPhotos || userDefaults.instantUploadVideos) {
						if let autoUploadSection = self.autoUploadSection, let index = self.indexForSection(autoUploadSection) {
							self.insertSection(backgroundUploadsSection, at: (index + 1), animated: true)
						} else {
							self.addSection(backgroundUploadsSection)
						}
					} else if !userDefaults.instantUploadPhotos, !userDefaults.instantUploadVideos {
						self.removeSection(backgroundUploadsSection, animated: true)
					}
				}
			} else {
				if let autoUploadSection = self.autoUploadSection, autoUploadSection.attached {
					self.removeSection(autoUploadSection)
					self.autoUploadSection = nil
				}
				if let backgroundUploadsSection = self.backgroundUploadsSection, backgroundUploadsSection.attached, !userDefaults.instantUploadPhotos, !userDefaults.instantUploadVideos {
					self.removeSection(backgroundUploadsSection)
					self.backgroundUploadsSection = nil
				}
			}

			if OCLicenseEnterpriseProvider.numberOfEnterpriseAccounts > 0 || OCLicenseManager.shared.authorizationStatus(forFeature: .photoProFeatures, in: OCLicenseEnvironment()) == .granted {
				if !proSettingsSection.attached {
					self.addSection(proSettingsSection)
				}
			} else {
				if proSettingsSection.attached {
					self.removeSection(proSettingsSection)
				}
			}
		}
	}
}
