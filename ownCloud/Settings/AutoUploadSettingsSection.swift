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
		case InstantLegacyUploadBookmarkUUIDKey = "instant-upload-bookmark-uuid"
		case InstantPhotoUploadBookmarkUUIDKey = "instant-photo-upload-bookmark-uuid"
		case InstantVideoUploadBookmarkUUIDKey = "instant-video-upload-bookmark-uuid"
		case InstantLegacyUploadPathKey = "instant-upload-path"
		case InstantPhotoUploadPathKey = "instant-photo-upload-path"
		case InstantVideoUploadPathKey = "instant-video-upload-path"
		case InstantUploadPhotosAfterDateKey = "instant-upload-photos-after-date"
		case InstantUploadVideosAfterDateKey = "instant-upload-videos-after-date"
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

	public var instantPhotoUploadBookmarkUUID: UUID? {
		set {
			self.set(newValue?.uuidString, forKey: AutoUploadKeys.InstantPhotoUploadBookmarkUUIDKey.rawValue)
		}

		get {
			var uuidString = self.string(forKey: AutoUploadKeys.InstantPhotoUploadBookmarkUUIDKey.rawValue)
			if uuidString == nil {
				uuidString = self.string(forKey: AutoUploadKeys.InstantLegacyUploadBookmarkUUIDKey.rawValue)
			}
			guard let uuid = uuidString else { return nil }
			return UUID(uuidString: uuid)
		}
	}

	public var instantVideoUploadBookmarkUUID: UUID? {
		set {
			self.set(newValue?.uuidString, forKey: AutoUploadKeys.InstantVideoUploadBookmarkUUIDKey.rawValue)
		}

		get {
			var uuidString = self.string(forKey: AutoUploadKeys.InstantVideoUploadBookmarkUUIDKey.rawValue)
			if uuidString == nil {
				uuidString = self.string(forKey: AutoUploadKeys.InstantLegacyUploadBookmarkUUIDKey.rawValue)
			}
			guard let uuid = uuidString else { return nil }
			return UUID(uuidString: uuid)
		}
	}

	public var instantPhotoUploadPath: String? {

		set {
			self.set(newValue, forKey: AutoUploadKeys.InstantPhotoUploadPathKey.rawValue)
		}

		get {
			return self.string(forKey: AutoUploadKeys.InstantPhotoUploadPathKey.rawValue) ?? self.string(forKey: AutoUploadKeys.InstantLegacyUploadPathKey.rawValue)
		}
	}

	public var instantVideoUploadPath: String? {

		set {
			self.set(newValue, forKey: AutoUploadKeys.InstantVideoUploadPathKey.rawValue)
		}

		get {
			return self.string(forKey: AutoUploadKeys.InstantVideoUploadPathKey.rawValue) ?? self.string(forKey: AutoUploadKeys.InstantLegacyUploadPathKey.rawValue)
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
		self.instantPhotoUploadBookmarkUUID = nil
		self.instantPhotoUploadPath = nil
		self.instantUploadPhotos = false
	}

	public func resetInstantVideoUploadConfiguration() {
		self.instantVideoUploadBookmarkUUID = nil
		self.instantVideoUploadPath = nil
		self.instantUploadVideos = false
	}
}

class AutoUploadSettingsSection: SettingsSection {

	enum MediaType { case photo, video }

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
			if userDefaults.instantPhotoUploadPath == nil || userDefaults.instantPhotoUploadBookmarkUUID == nil {
				showAccountSelectionViewController(for: .photo)
			}
		}
	}

	private func setupVideoAutoUpload(enabled:Bool) {
		if !enabled {
			userDefaults.resetInstantVideoUploadConfiguration()
			postSettingsChangedNotification()
			updateDynamicUI()
		} else {
			userDefaults.instantUploadVideos = true
			userDefaults.instantUploadVideosAfter = Date()
			if userDefaults.instantVideoUploadPath == nil || userDefaults.instantVideoUploadBookmarkUUID == nil {
				showAccountSelectionViewController(for: .video)
			}
		}
	}

	private func getSelectedBookmark(for mediaType:MediaType) -> OCBookmark? {

		var bookmarkUUID: UUID?

		switch mediaType {
		case .photo:
			bookmarkUUID = self.userDefaults.instantPhotoUploadBookmarkUUID
		case .video:
			bookmarkUUID = self.userDefaults.instantVideoUploadBookmarkUUID
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

		if let bookmark = getSelectedBookmark(for: .photo), let path = userDefaults.instantPhotoUploadPath, userDefaults.instantUploadPhotos == true {
			OCItemTracker().item(for: bookmark, at: path) { (error, _, pathItem) in
				guard error == nil else { return }

				OnMainThread {
					if pathItem != nil {
						self.add(row: self.photoBookmarkAndPathSelectionRow!)
						let directory = URL(fileURLWithPath: path).lastPathComponent
						self.photoBookmarkAndPathSelectionRow?.value = "\(bookmark.shortName)/\(directory)"
					} else {
						self.userDefaults.resetInstantPhotoUploadConfiguration()
						self.showAutoUploadDisabledAlert()
					}
					self.instantUploadPhotosRow?.value = self.userDefaults.instantUploadPhotos
				}
			}
		} else {
			self.userDefaults.resetInstantPhotoUploadConfiguration()
			self.instantUploadPhotosRow?.value = self.userDefaults.instantUploadPhotos
		}

		if let bookmark = getSelectedBookmark(for: .video), let path = userDefaults.instantVideoUploadPath, userDefaults.instantUploadVideos == true {
			OCItemTracker().item(for: bookmark, at: path) { (error, _, pathItem) in
				guard error == nil else { return }

				OnMainThread {
					if pathItem != nil {
						self.add(row: self.videoBookmarkAndPathSelectionRow!)
						let directory = URL(fileURLWithPath: path).lastPathComponent
						self.videoBookmarkAndPathSelectionRow?.value = "\(bookmark.shortName)/\(directory)"
					} else {
						self.userDefaults.resetInstantVideoUploadConfiguration()
						self.showAutoUploadDisabledAlert()
					}
					self.instantUploadVideosRow?.value = self.userDefaults.instantUploadVideos
				}
			}
		} else {
			self.userDefaults.resetInstantVideoUploadConfiguration()
			self.instantUploadVideosRow?.value = self.userDefaults.instantUploadVideos
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

		let accountSelectionViewController = StaticTableViewController(style: .grouped)
		let navigationController = ThemeNavigationController(rootViewController: accountSelectionViewController)

		accountSelectionViewController.navigationItem.title = "Select account".localized
		accountSelectionViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
																						   target: accountSelectionViewController,
																						   action: #selector(accountSelectionViewController.dismissAnimated))
		accountSelectionViewController.didDismissAction = { [weak self] (viewController) in
			self?.updateDynamicUI()
		}

		let accountsSection = StaticTableViewSection(headerTitle: "Accounts".localized)

		var bookmarkRows: [StaticTableViewRow] = []
		let bookmarks = OCBookmarkManager.shared.bookmarks

		guard bookmarks.count > 0 else { return }

		var bookmarkDictionary = [StaticTableViewRow : OCBookmark]()

		for bookmark in bookmarks {
			let row = StaticTableViewRow(buttonWithAction: { [weak self] (_ row, _ sender) in

				// Store selected bookmark
				let selectedBookmark = bookmarkDictionary[row]!
				switch mediaType {
				case .photo:
					self?.userDefaults.instantPhotoUploadBookmarkUUID = selectedBookmark.uuid
					self?.userDefaults.instantPhotoUploadPath = nil
				case .video:
					self?.userDefaults.instantVideoUploadBookmarkUUID = selectedBookmark.uuid
					self?.userDefaults.instantVideoUploadPath = nil
				}

				// Proceed with upload path selection
				self?.selectUploadPath(for: selectedBookmark, pushIn: navigationController, completion: { (directoryItem) in
					let path = self?.getDirectoryPath(from: directoryItem)
					switch mediaType {
					case .photo:
						self?.userDefaults.instantPhotoUploadPath = path
						if path == nil {
							self?.userDefaults.resetInstantPhotoUploadConfiguration()
						}
					case .video:
						self?.userDefaults.instantVideoUploadPath = path
						if path == nil {
							self?.userDefaults.resetInstantVideoUploadConfiguration()
						}
					}

					navigationController.dismiss(animated: true, completion: nil)
					self?.postSettingsChangedNotification()
					self?.updateDynamicUI()
				})

			}, title: bookmark.shortName, style: .plain, image: Theme.shared.image(for: "owncloud-logo", size: CGSize(width: 25, height: 25)), imageWidth: 25, alignment: .left)

			bookmarkRows.append(row)
			bookmarkDictionary[row] = bookmark
		}

		accountsSection.add(rows: bookmarkRows)
		accountSelectionViewController.addSection(accountsSection)

		self.viewController?.present(navigationController, animated: true)
	}

	private func selectUploadPath(for bookmark:OCBookmark, pushIn navigationController:UINavigationController, completion:@escaping (_ directoryItem:OCItem?) -> Void) {

		OCCoreManager.shared.requestCore(for: bookmark, setup: { (_, _) in },
										 completionHandler: { [weak navigationController] (core, error) in

											guard let core = core, error == nil else { return }

											OnMainThread {
												let directoryPickerViewController = ClientDirectoryPickerViewController(core: core, path: "/", selectButtonTitle: "Select Upload Path".localized, avoidConflictsWith: [], choiceHandler: { (selectedDirectory, _) in
													OCCoreManager.shared.returnCore(for: bookmark, completionHandler: nil)
													completion(selectedDirectory)
												})
												navigationController?.pushViewController(directoryPickerViewController, animated: true)
											}
		})
	}

	private func getDirectoryPath(from directoryItem:OCItem?) -> String? {

		guard let item = directoryItem else { return nil }

		if item.permissions.contains(.createFile) {
			return item.path
		} else {
			OnMainThread {
				let alert = ThemedAlertController(title: "Missing permissions".localized, message: "This permission is needed to upload photos and videos from your photo library.".localized, preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: nil))
				self.viewController?.present(alert, animated: true, completion: nil)
			}
		}
		return nil
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
