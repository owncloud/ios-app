//
//  AutoUploadSettingsSection.swift
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
import Photos
import ownCloudSDK
import ownCloudAppShared

extension UserDefaults {

	static let MediaUploadSettingsChangedNotification = NSNotification.Name("settings.media-upload-settings-changed")

	enum AutoUploadKeys : String {
		case InstantUploadPhotosKey = "instant-upload-photos"
		case InstantUploadVideosKey = "instant-upload-videos"

		case InstantPhotoUploadLocation = "instant-photo-upload-location"
		case InstantVideoUploadLocation = "instant-video-upload-location"

		case InstantUploadPhotosAfterDateKey = "instant-upload-photos-after-date"
		case InstantUploadVideosAfterDateKey = "instant-upload-videos-after-date"

		case LegacyInstantLegacyUploadBookmarkUUIDKey = "instant-upload-bookmark-uuid"
		case LegacyInstantPhotoUploadBookmarkUUIDKey = "instant-photo-upload-bookmark-uuid"
		case LegacyInstantVideoUploadBookmarkUUIDKey = "instant-video-upload-bookmark-uuid"
		case LegacyInstantLegacyUploadPathKey = "instant-upload-path"
		case LegacyInstantPhotoUploadPathKey = "instant-photo-upload-path"
		case LegacyInstantVideoUploadPathKey = "instant-video-upload-path"
	}

	public var instantUploadPhotos: Bool {
		set {
			self.set(newValue, forKey: AutoUploadKeys.InstantUploadPhotosKey.rawValue)
		}

		get {
			return self.bool(forKey: AutoUploadKeys.InstantUploadPhotosKey.rawValue)
		}
	}

	public var instantUploadVideos: Bool {
		set {
			self.set(newValue, forKey: AutoUploadKeys.InstantUploadVideosKey.rawValue)
		}

		get {
			return self.bool(forKey: AutoUploadKeys.InstantUploadVideosKey.rawValue)
		}
	}

	public var instantPhotoUploadLocation: OCLocation? {
		set {
			set(newValue?.data, forKey: AutoUploadKeys.InstantPhotoUploadLocation.rawValue)
		}

		get {
			if let oldBookmarkUUID = legacyInstantPhotoUploadBookmarkUUID,
			   let oldBookmarkPath = legacyInstantPhotoUploadPath {
				// Migrate and remove old setting
				legacyInstantPhotoUploadBookmarkUUID = nil
				legacyInstantPhotoUploadPath = nil

				let location = OCLocation(bookmarkUUID: oldBookmarkUUID, driveID: nil, path: oldBookmarkPath)
				set(location.data, forKey: AutoUploadKeys.InstantPhotoUploadLocation.rawValue)
				return location
			}

			if let locationData = data(forKey: AutoUploadKeys.InstantPhotoUploadLocation.rawValue) {
				return OCLocation.fromData(locationData)
			}

			return nil
		}
	}

	public var instantVideoUploadLocation: OCLocation? {
		set {
			set(newValue?.data, forKey: AutoUploadKeys.InstantVideoUploadLocation.rawValue)
		}

		get {
			if let oldBookmarkUUID = legacyInstantVideoUploadBookmarkUUID,
			   let oldBookmarkPath = legacyInstantVideoUploadPath {
				// Migrate and remove old setting
				legacyInstantVideoUploadBookmarkUUID = nil
				legacyInstantVideoUploadPath = nil

				let location = OCLocation(bookmarkUUID: oldBookmarkUUID, driveID: nil, path: oldBookmarkPath)
				set(location.data, forKey: AutoUploadKeys.InstantVideoUploadLocation.rawValue)
				return location
			}

			if let locationData = data(forKey: AutoUploadKeys.InstantVideoUploadLocation.rawValue) {
				return OCLocation.fromData(locationData)
			}

			return nil
		}
	}

	public var instantUploadPhotosAfter: Date? {
		set {
			self.set(newValue, forKey: AutoUploadKeys.InstantUploadPhotosAfterDateKey.rawValue)
		}

		get {
			return self.value(forKey: AutoUploadKeys.InstantUploadPhotosAfterDateKey.rawValue) as? Date
		}
	}

	public var instantUploadVideosAfter: Date? {
		set {
			self.set(newValue, forKey: AutoUploadKeys.InstantUploadVideosAfterDateKey.rawValue)
		}

		get {
			return self.value(forKey: AutoUploadKeys.InstantUploadVideosAfterDateKey.rawValue) as? Date
		}
	}

	public func resetInstantPhotoUploadConfiguration() {
		self.legacyInstantPhotoUploadBookmarkUUID = nil
		self.legacyInstantPhotoUploadPath = nil
		self.instantPhotoUploadLocation = nil
		self.instantUploadPhotos = false
	}

	public func resetInstantVideoUploadConfiguration() {
		self.legacyInstantVideoUploadBookmarkUUID = nil
		self.legacyInstantVideoUploadPath = nil
		self.instantVideoUploadLocation = nil
		self.instantUploadVideos = false
	}
}

// Legacy bookmark UUID + path settings from the pre-OCLocation era
extension UserDefaults {
	public var legacyInstantPhotoUploadBookmarkUUID: UUID? {
		set {
			self.set(newValue?.uuidString, forKey: AutoUploadKeys.LegacyInstantPhotoUploadBookmarkUUIDKey.rawValue)
		}

		get {
			var uuidString = self.string(forKey: AutoUploadKeys.LegacyInstantPhotoUploadBookmarkUUIDKey.rawValue)
			if uuidString == nil {
				uuidString = self.string(forKey: AutoUploadKeys.LegacyInstantLegacyUploadBookmarkUUIDKey.rawValue)
			}
			guard let uuid = uuidString else { return nil }
			return UUID(uuidString: uuid)
		}
	}

	public var legacyInstantVideoUploadBookmarkUUID: UUID? {
		set {
			self.set(newValue?.uuidString, forKey: AutoUploadKeys.LegacyInstantVideoUploadBookmarkUUIDKey.rawValue)
		}

		get {
			var uuidString = self.string(forKey: AutoUploadKeys.LegacyInstantVideoUploadBookmarkUUIDKey.rawValue)
			if uuidString == nil {
				uuidString = self.string(forKey: AutoUploadKeys.LegacyInstantLegacyUploadBookmarkUUIDKey.rawValue)
			}
			guard let uuid = uuidString else { return nil }
			return UUID(uuidString: uuid)
		}
	}

	public var legacyInstantPhotoUploadPath: String? {

		set {
			self.set(newValue, forKey: AutoUploadKeys.LegacyInstantPhotoUploadPathKey.rawValue)
		}

		get {
			return self.string(forKey: AutoUploadKeys.LegacyInstantPhotoUploadPathKey.rawValue) ?? self.string(forKey: AutoUploadKeys.LegacyInstantLegacyUploadPathKey.rawValue)
		}
	}

	public var legacyInstantVideoUploadPath: String? {

		set {
			self.set(newValue, forKey: AutoUploadKeys.LegacyInstantVideoUploadPathKey.rawValue)
		}

		get {
			return self.string(forKey: AutoUploadKeys.LegacyInstantVideoUploadPathKey.rawValue) ?? self.string(forKey: AutoUploadKeys.LegacyInstantLegacyUploadPathKey.rawValue)
		}
	}
}

class AutoUploadSettingsSection: SettingsSection {

	enum MediaType { case photo, video }
	var changeHandler : (() -> Void)?

	private static let photoUploadBookmarkAndPathSelectionRowIdentifier = "photo-upload-bookmark-path"
	private static let videoUploadBookmarkAndPathSelectionRowIdentifier = "video-upload-bookmark-path"

	private var instantUploadPhotosRow: StaticTableViewRow?
	private var instantUploadVideosRow: StaticTableViewRow?

	private var photoBookmarkAndPathSelectionRow: StaticTableViewRow?
	private var videoBookmarkAndPathSelectionRow: StaticTableViewRow?

	override init(userDefaults: UserDefaults) {
		super.init(userDefaults: userDefaults)

		self.headerTitle = "Auto Upload".localized
		self.identifier = "auto-upload"

		// Instant upload requires at least one configured account
		if OCBookmarkManager.shared.bookmarks.count > 0 {
			instantUploadPhotosRow = StaticTableViewRow(switchWithAction: { [weak self] (_, sender) in
				if let convertSwitch = sender as? UISwitch {
					self?.changeAndRequestPhotoLibraryAccessForOption(optionSwitch: convertSwitch, completion: { (switchState) in
						self?.setupPhotoAutoUpload(enabled: switchState)
					})
				}
			}, title: "Auto Upload Photos".localized, value: self.userDefaults.instantUploadPhotos, identifier: "auto-upload-photos")

			instantUploadVideosRow = StaticTableViewRow(switchWithAction: { [weak self] (_, sender) in
				if let convertSwitch = sender as? UISwitch {
					self?.changeAndRequestPhotoLibraryAccessForOption(optionSwitch: convertSwitch, completion: { (switchState) in
						self?.setupVideoAutoUpload(enabled: switchState)
					})
				}
			}, title: "Auto Upload Videos".localized, value: self.userDefaults.instantUploadVideos, identifier: "auto-upload-videos")

			photoBookmarkAndPathSelectionRow = StaticTableViewRow(subtitleRowWithAction: { [weak self] (_, _) in
				self?.showAccountSelectionViewController(for: .photo)
			}, title: "Photo upload path".localized, subtitle: "", accessoryType: .disclosureIndicator, identifier: AutoUploadSettingsSection.photoUploadBookmarkAndPathSelectionRowIdentifier)

			videoBookmarkAndPathSelectionRow = StaticTableViewRow(subtitleRowWithAction: { [weak self] (_, _) in
				self?.showAccountSelectionViewController(for: .video)
			}, title: "Video upload path".localized, subtitle: "", accessoryType: .disclosureIndicator, identifier: AutoUploadSettingsSection.videoUploadBookmarkAndPathSelectionRowIdentifier)

			self.add(row: instantUploadPhotosRow!)
			self.add(row: instantUploadVideosRow!)

			updateDynamicUI()
		}
	}

	private func setupPhotoAutoUpload(enabled:Bool) {
		if !enabled {
			userDefaults.resetInstantPhotoUploadConfiguration()
			postSettingsChangedNotification()
			updateDynamicUI()
		} else {
			userDefaults.instantUploadPhotos = true
			userDefaults.instantUploadPhotosAfter = Date()
			if userDefaults.instantPhotoUploadLocation == nil {
				showAccountSelectionViewController(for: .photo)
			} else {
				updateDynamicUI()
			}
		}

		NotificationCenter.default.post(name: .OCBookmarkManagerListChanged, object: nil)
	}

	private func setupVideoAutoUpload(enabled:Bool) {
		if !enabled {
			userDefaults.resetInstantVideoUploadConfiguration()
			postSettingsChangedNotification()
			updateDynamicUI()
		} else {
			userDefaults.instantUploadVideos = true
			userDefaults.instantUploadVideosAfter = Date()
			if userDefaults.instantVideoUploadLocation == nil {
				showAccountSelectionViewController(for: .video)
			} else {
				updateDynamicUI()
			}
		}

		NotificationCenter.default.post(name: .OCBookmarkManagerListChanged, object: nil)
	}

	private func getSelectedBookmark(for mediaType:MediaType) -> OCBookmark? {

		var bookmarkUUID: UUID?

		switch mediaType {
			case .photo:
				bookmarkUUID = self.userDefaults.instantPhotoUploadLocation?.bookmarkUUID
			case .video:
				bookmarkUUID = self.userDefaults.instantVideoUploadLocation?.bookmarkUUID
		}

		if let selectedBookmarkUUID = bookmarkUUID {
			let bookmarks : [OCBookmark] = OCBookmarkManager.shared.bookmarks as [OCBookmark]
			return bookmarks.filter({ $0.uuid == selectedBookmarkUUID}).first
		}
		return nil
	}

	private func updateDynamicUI() {

		self.remove(rowWithIdentifier: AutoUploadSettingsSection.photoUploadBookmarkAndPathSelectionRowIdentifier)
		self.remove(rowWithIdentifier: AutoUploadSettingsSection.videoUploadBookmarkAndPathSelectionRowIdentifier)

		if let bookmark = getSelectedBookmark(for: .photo), let location = userDefaults.instantPhotoUploadLocation, userDefaults.instantUploadPhotos == true {
			OCItemTracker(for: bookmark, at: location) { (error, _, pathItem) in
				guard error == nil else { return }

				OnMainThread {
					if pathItem != nil {
						self.add(row: self.photoBookmarkAndPathSelectionRow!)
						let directory = location.lastPathComponent ?? "?"
						self.photoBookmarkAndPathSelectionRow?.value = "\(bookmark.shortName)/\(directory)"
					} else {
						self.userDefaults.resetInstantPhotoUploadConfiguration()
						self.showAutoUploadDisabledAlert()
					}
					self.instantUploadPhotosRow?.value = self.userDefaults.instantUploadPhotos

					self.changeHandler?()
				}
			}
		} else {
			self.userDefaults.resetInstantPhotoUploadConfiguration()
			self.instantUploadPhotosRow?.value = self.userDefaults.instantUploadPhotos
			changeHandler?()
		}

		if let bookmark = getSelectedBookmark(for: .video), let location = userDefaults.instantVideoUploadLocation, userDefaults.instantUploadVideos == true {
			OCItemTracker(for: bookmark, at: location) { (error, _, pathItem) in
				guard error == nil else { return }

				OnMainThread {
					if pathItem != nil {
						self.add(row: self.videoBookmarkAndPathSelectionRow!)
						let directory = location.lastPathComponent ?? "?"
						self.videoBookmarkAndPathSelectionRow?.value = "\(bookmark.shortName)/\(directory)"
					} else {
						self.userDefaults.resetInstantVideoUploadConfiguration()
						self.showAutoUploadDisabledAlert()
					}
					self.instantUploadVideosRow?.value = self.userDefaults.instantUploadVideos

					self.changeHandler?()
				}
			}
		} else {
			self.userDefaults.resetInstantVideoUploadConfiguration()
			self.instantUploadVideosRow?.value = self.userDefaults.instantUploadVideos
			changeHandler?()
		}
	}

	private func changeAndRequestPhotoLibraryAccessForOption(optionSwitch:UISwitch, completion:@escaping (_ value:Bool) -> Void) {
		if optionSwitch.isOn {
			PHPhotoLibrary.requestAccess(completion: { (granted) in
				optionSwitch.isOn = granted

				if !granted {
					let alert = ThemedAlertController.alertControllerForPhotoLibraryAuthorizationInSettings()
					self.viewController?.present(alert, animated: true)
				}

				completion(granted)
			})
		} else {
			completion(false)
		}
	}

	private func showAccountSelectionViewController(for mediaType:MediaType) {
		var prompt: String

		switch mediaType {
			case .photo:
				prompt = "Pick a destination for photo uploads".localized

			case .video:
				prompt = "Pick a destination for video uploads".localized
		}

		let locationPicker = ClientLocationPicker(location: .accounts, selectButtonTitle: "Select Destination".localized, selectPrompt: prompt, requiredPermissions: [ .createFile ], avoidConflictsWith: nil, choiceHandler: { [weak self] (chosenItem, location, _, cancelled) in
			if let chosenItem, !chosenItem.permissions.contains(.createFile) {
				OnMainThread { [weak self] in
					let alert = ThemedAlertController(title: "Missing permissions".localized, message: "This permission is needed to upload photos and videos from your photo library.".localized, preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: nil))
					self?.viewController?.present(alert, animated: true, completion: nil)
				}
			} else {
				switch mediaType {
					case .photo:
						self?.userDefaults.instantPhotoUploadLocation = location
						if location == nil {
							self?.userDefaults.resetInstantPhotoUploadConfiguration()
						}

					case .video:
						self?.userDefaults.instantVideoUploadLocation = location
						if location == nil {
							self?.userDefaults.resetInstantVideoUploadConfiguration()
						}
				}

				self?.postSettingsChangedNotification()
				self?.updateDynamicUI()
			}
		})

		locationPicker.present(in: ClientContext(originatingViewController: self.viewController))
	}

	private func postSettingsChangedNotification() {
		NotificationCenter.default.post(name: UserDefaults.MediaUploadSettingsChangedNotification, object: nil)
	}

	private func showAutoUploadDisabledAlert() {
		let alertController = ThemedAlertController(with: "Auto upload disabled".localized,
							    message: "Auto upload of media was disabled since configured account / folder was not found".localized)
		self.viewController?.present(alertController, animated: true, completion: nil)
	}
}
