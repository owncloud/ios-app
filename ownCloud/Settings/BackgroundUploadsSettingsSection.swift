//
//  BackgroundUploadsSettingsSection.swift
//  ownCloud
//
//  Created by Michael Neuwert on 27.05.20.
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
import CoreLocation
import UserNotifications

extension UserDefaults {

	enum BackgroundUploadsKeys : String {
		case MediaUploadsEnabled = "background-media-uploads-enabled"
		case MediaUploadsNotificationsEnabled = "background-media-uploads-notifications-enabled"
	}

	public var backgroundMediaUploadsEnabled: Bool {
		set {
			self.set(newValue, forKey: BackgroundUploadsKeys.MediaUploadsEnabled.rawValue)
		}

		get {
			return self.bool(forKey: BackgroundUploadsKeys.MediaUploadsEnabled.rawValue)
		}
	}

	public var backgroundMediaUploadsNotificationsEnabled: Bool {
		set {
			self.set(newValue, forKey: BackgroundUploadsKeys.MediaUploadsNotificationsEnabled.rawValue)
		}

		get {
			return self.bool(forKey: BackgroundUploadsKeys.MediaUploadsNotificationsEnabled.rawValue)
		}
	}
}

class BackgroundUploadsSettingsSection: SettingsSection {

	private var backgroundUploadsRow: StaticTableViewRow?
	private var backgroundLocationRow: StaticTableViewRow?
	private var notificationsRow: StaticTableViewRow?

	override init(userDefaults: UserDefaults) {
		super.init(userDefaults: userDefaults)
		self.headerTitle = "Background uploads".localized

		// Add option for iOS13 to use BackgroundTasks framework for background uploads
		if #available(iOS 13, *) {
			backgroundUploadsRow = StaticTableViewRow(switchWithAction: { (_, sender) in
				if let enableSwitch = sender as? UISwitch {
					userDefaults.backgroundMediaUploadsEnabled = enableSwitch.isOn
				}
				}, title: "Enable background uploads".localized, value: self.userDefaults.backgroundMediaUploadsEnabled)

			self.add(row: backgroundUploadsRow!)
		}

		// Add option to enable background location updates which will trigger background media uploads
		var locationServicesRowTitle: String = ""
		if #available(iOS 13, *) {
			locationServicesRowTitle = "Improve background uploading".localized
		} else {
			locationServicesRowTitle = "Enable background uploads".localized
		}

		let currentAuthStatus = CLLocationManager.authorizationStatus() == .authorizedAlways
		backgroundLocationRow = StaticTableViewRow(switchWithAction: { (_, sender) in
			if let enableSwitch = sender as? UISwitch {
				if enableSwitch.isOn {
					if !ScheduledTaskManager.shared.requestLocationAuthorization() {
						enableSwitch.isOn = false
						self.showLocationDisabledAlert()
					}
				} else {
					ScheduledTaskManager.shared.stopLocationMonitoring()
				}
			}
			}, title: locationServicesRowTitle, value: currentAuthStatus)

		self.add(row: backgroundLocationRow!)

		// Add option to enable local notifications reporting that some number of media files got enqueued for upload
		notificationsRow = StaticTableViewRow(switchWithAction: { (_, sender) in
			if let enableSwitch = sender as? UISwitch {
				if enableSwitch.isOn {
					// Request authorization for notifications
					let center = UNUserNotificationCenter.current()
					center.getNotificationSettings(completionHandler: { (settings) in
						if settings.authorizationStatus == .notDetermined {
							center.requestAuthorization(options: [.alert]) { (granted, _) in
								enableSwitch.isOn = granted
							}
						}
					})
				}

			}
			}, title: "Background upload notifications".localized, value: false)

		self.add(row: notificationsRow!)

		// Update notifications option
		let center = UNUserNotificationCenter.current()
		center.getNotificationSettings(completionHandler: { (settings) in
			if settings.authorizationStatus == .authorized {
				OnMainThread {
					self.notificationsRow?.value = true
				}
			}
		})

		// Add section footer with detailed explanations
		var footerText = ""
		if #available(iOS 13, *) {
			footerText += "if you would like background media uploads to be more reliable, you should enable background location updates.".localized
		} else {
			footerText += "Background media uploads rely on location updates and will stop working if location acquisition permissions are revoked.".localized
		}

		if #available(iOS 13, *) {
			footerText += " "
			footerText += "Otherwise background media uploads would depend on how often do you use the app.".localized
		}
		self.footerTitle = footerText

		// Monitor media upload settings changes
		NotificationCenter.default.addObserver(self, selector: #selector(mediaUploadSettingsDidChange), name: UserDefaults.MediaUploadSettingsChangedNotification, object: nil)

		updateUI()
	}

	deinit {
		NotificationCenter.default.removeObserver(self, name: UserDefaults.MediaUploadSettingsChangedNotification, object: nil)
	}

	private func showLocationDisabledAlert() {
		let alertController = ThemedAlertController(with: "Location permission denied".localized,
												message: "Please re-enable location acquisition in system settings".localized)
		self.viewController?.present(alertController, animated: true, completion: nil)
	}

	private func updateUI() {
		let enableRows = self.userDefaults.instantUploadPhotos || self.userDefaults.instantUploadVideos
		backgroundUploadsRow?.enabled = enableRows
		backgroundLocationRow?.enabled = enableRows
		notificationsRow?.enabled = enableRows
	}

	@objc func mediaUploadSettingsDidChange() {
		updateUI()
	}

}
