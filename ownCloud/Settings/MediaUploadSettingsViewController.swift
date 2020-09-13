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

	override func viewDidLoad() {
		super.viewDidLoad()
		navigationItem.title = "Media Upload".localized

		if let userDefaults = OCAppIdentity.shared.userDefaults {
			self.addSection(MediaExportSettingsSection(userDefaults: userDefaults))

			let enterpriseAccountAvailable = OCBookmarkManager.shared.bookmarks.filter({$0.edition == .Enterprise}).count > 0

			if enterpriseAccountAvailable || isProPhotoPackageLicensed() {
				self.addSection(ProPhotoUploadSettingsSection(userDefaults: userDefaults))
			}

			if OCBookmarkManager.shared.bookmarks.count > 0 {
				self.addSection(AutoUploadSettingsSection(userDefaults: userDefaults))
				// TODO: Re-add this section when we re-gain an ability to run background NSURLSessions
				//self.addSection(BackgroundUploadsSettingsSection(userDefaults: userDefaults))
			}
		}
	}

	private func isProPhotoPackageLicensed() -> Bool {

		let environment = OCLicenseEnvironment()

		// Take a shortcut (ha!) if the authorization status is granted
		if OCLicenseManager.shared.authorizationStatus(forFeature: .photoProFeatures, in: environment) == .granted {
			return true
		}

		// Make sure that pending refreshes have been carried out otherwise, so the result is actually conclusive
		let waitGroup = DispatchGroup()

		waitGroup.enter()

		OCLicenseManager.shared.perform(afterCurrentlyPendingRefreshes: {
			waitGroup.leave()
		})

		_ = waitGroup.wait(timeout: .now() + 3)

		return (OCLicenseManager.shared.authorizationStatus(forFeature: .photoProFeatures, in: environment) == .granted)
	}
}
