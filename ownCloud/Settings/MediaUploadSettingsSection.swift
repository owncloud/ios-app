//
//  MediaUploadSettingsSection
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
import Photos

extension UserDefaults {

	enum MediaUploadKeys : String {
		case ConvertHEICtoJPEGKey = "convert-heic-to-jpeg"
		case ConvertVideosToMP4Key = "convert-videos-to-mp4"
		case InstantUploadPhotos = "instant-upload-photos"
		case InstantUploadVideos = "instant-upload-videos"
	}

	public var convertHeic: Bool {
		set {
			self.set(newValue, forKey: MediaUploadKeys.ConvertHEICtoJPEGKey.rawValue)
		}

		get {
			return self.bool(forKey: MediaUploadKeys.ConvertHEICtoJPEGKey.rawValue)
		}
	}

	public var convertVideosToMP4: Bool {
		set {
			self.set(newValue, forKey: MediaUploadKeys.ConvertVideosToMP4Key.rawValue)
		}

		get {
			return self.bool(forKey: MediaUploadKeys.ConvertVideosToMP4Key.rawValue)
		}
	}

	public var instantUploadPhotos: Bool {
		set {
			self.set(newValue, forKey: MediaUploadKeys.InstantUploadPhotos.rawValue)
		}

		get {
			return self.bool(forKey: MediaUploadKeys.InstantUploadPhotos.rawValue)
		}
	}

	public var instantUploadVideos: Bool {
		set {
			self.set(newValue, forKey: MediaUploadKeys.InstantUploadVideos.rawValue)
		}

		get {
			return self.bool(forKey: MediaUploadKeys.InstantUploadVideos.rawValue)
		}
	}
}

class MediaUploadSettingsSection: SettingsSection {

	private var convertPhotosSwitchRow: StaticTableViewRow?
	private var convertVideosSwitchRow: StaticTableViewRow?
	private var instantUploadPhotosRow: StaticTableViewRow?
	private var instantUploadVideosRow: StaticTableViewRow?

	override init(userDefaults: UserDefaults) {

		super.init(userDefaults: userDefaults)

		self.headerTitle = "Media Upload".localized
		self.identifier = "media-upload"

		convertPhotosSwitchRow = StaticTableViewRow(switchWithAction: { [weak self] (_, sender) in
			if let convertSwitch = sender as? UISwitch {
				self?.userDefaults.convertHeic = convertSwitch.isOn
			}
			}, title: "Convert HEIC to JPEG".localized, value: self.userDefaults.convertHeic)

		convertVideosSwitchRow = StaticTableViewRow(switchWithAction: { [weak self] (_, sender) in
			if let convertSwitch = sender as? UISwitch {
				self?.userDefaults.convertVideosToMP4 = convertSwitch.isOn
			}
			}, title: "Convert videos to MP4".localized, value: self.userDefaults.convertVideosToMP4)

		instantUploadPhotosRow = StaticTableViewRow(switchWithAction: { [weak self] (_, sender) in
			if let convertSwitch = sender as? UISwitch {
				self?.changeAndRequestPhotoLibraryAccessForOption(optionSwitch: convertSwitch, completion: { (value) in
					self?.userDefaults.instantUploadPhotos = value
				})
			}
			}, title: "Instant Upload Photos".localized, value: self.userDefaults.instantUploadPhotos)

		instantUploadVideosRow = StaticTableViewRow(switchWithAction: { [weak self] (_, sender) in
			if let convertSwitch = sender as? UISwitch {
				self?.changeAndRequestPhotoLibraryAccessForOption(optionSwitch: convertSwitch, completion: { (value) in
					self?.userDefaults.instantUploadVideos = value
				})
			}
			}, title: "Instant Upload Videos".localized, value: self.userDefaults.instantUploadVideos)

		self.add(row: convertPhotosSwitchRow!)
		self.add(row: convertVideosSwitchRow!)
		self.add(row: instantUploadPhotosRow!)
		self.add(row: instantUploadVideosRow!)
	}

	private func changeAndRequestPhotoLibraryAccessForOption(optionSwitch:UISwitch, completion:@escaping (_ value:Bool) -> Void) {
		if optionSwitch.isOn {
			PHPhotoLibrary.requestAccess(completion: { (granted) in
				optionSwitch.isOn = granted

				if !granted {
					let alert = UIAlertController.alertControllerForPhotoLibraryAuthorizationInSettings()
					self.viewController?.present(alert, animated: true)
				}

				completion(granted)
			})
		} else {
			completion(false)
		}
	}
}
