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
import ownCloudSDK

extension UserDefaults {

	enum MediaUploadKeys : String {
		case ConvertHEICtoJPEGKey = "convert-heic-to-jpeg"
		case ConvertVideosToMP4Key = "convert-videos-to-mp4"
		case InstantUploadPhotosKey = "instant-upload-photos"
		case InstantUploadVideosKey = "instant-upload-videos"
		case InstantUploadBookmarkUUIDKey = "instant-upload-bookmark-uuid"
		case InstantUploadPathKey = "instant-upload-path"
		case InstantUploadPhotosAfterDateKey = "instant-upload-photos-after-date"
		case InstantUploadVideosAfterDateKey = "instant-upload-videos-after-date"
	}

	static let MediaUploadSettingsChangedNotification = NSNotification.Name("settings.media-upload-settings-changed")

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
			self.set(newValue, forKey: MediaUploadKeys.InstantUploadPhotosKey.rawValue)
		}

		get {
			return self.bool(forKey: MediaUploadKeys.InstantUploadPhotosKey.rawValue)
		}
	}

	public var instantUploadVideos: Bool {
		set {
			self.set(newValue, forKey: MediaUploadKeys.InstantUploadVideosKey.rawValue)
		}

		get {
			return self.bool(forKey: MediaUploadKeys.InstantUploadVideosKey.rawValue)
		}
	}

	public var instantUploadBookmarkUUID: UUID? {
		set {
			self.set(newValue?.uuidString, forKey: MediaUploadKeys.InstantUploadBookmarkUUIDKey.rawValue)
		}

		get {
			if let uuidString = self.string(forKey: MediaUploadKeys.InstantUploadBookmarkUUIDKey.rawValue) {
				return UUID(uuidString: uuidString)
			} else {
				return nil
			}
		}
	}

	public var instantUploadPath: String? {

		set {
			self.set(newValue, forKey: MediaUploadKeys.InstantUploadPathKey.rawValue)
		}

		get {
			return self.string(forKey: MediaUploadKeys.InstantUploadPathKey.rawValue)
		}
	}

	public var instantUploadPhotosAfter: Date? {
		set {
			self.set(newValue, forKey: MediaUploadKeys.InstantUploadPhotosAfterDateKey.rawValue)
		}

		get {
			return self.value(forKey: MediaUploadKeys.InstantUploadPhotosAfterDateKey.rawValue) as? Date
		}
	}

	public var instantUploaVideosAfter: Date? {
		set {
			self.set(newValue, forKey: MediaUploadKeys.InstantUploadVideosAfterDateKey.rawValue)
		}

		get {
			return self.value(forKey: MediaUploadKeys.InstantUploadVideosAfterDateKey.rawValue) as? Date
		}
	}
}

class MediaUploadSettingsSection: SettingsSection {

	private static let bookmarkSelectionRowIdentifier = "bookmarkSelectionRowIdentifier"
	private static let pathSelectionRowIdentifier = "pathSelectionRowIdentifier"

	private var convertPhotosSwitchRow: StaticTableViewRow?
	private var convertVideosSwitchRow: StaticTableViewRow?
	private var instantUploadPhotosRow: StaticTableViewRow?
	private var instantUploadVideosRow: StaticTableViewRow?

	private var bookmarkSelectionRow: StaticTableViewRow?
	private var uploadPathSelectionRow: StaticTableViewRow?

	override init(userDefaults: UserDefaults) {

		super.init(userDefaults: userDefaults)

		self.headerTitle = "Media Upload".localized
		self.identifier = "media-upload"

		convertPhotosSwitchRow = StaticTableViewRow(switchWithAction: { [weak self] (_, sender) in
			if let convertSwitch = sender as? UISwitch {
				self?.userDefaults.convertHeic = convertSwitch.isOn
			}
			}, title: "Convert HEIC to JPEG".localized, value: self.userDefaults.convertHeic, identifier: "convert_heic_to_jpeg")

		convertVideosSwitchRow = StaticTableViewRow(switchWithAction: { [weak self] (_, sender) in
			if let convertSwitch = sender as? UISwitch {
				self?.userDefaults.convertVideosToMP4 = convertSwitch.isOn
			}
			}, title: "Convert videos to MP4".localized, value: self.userDefaults.convertVideosToMP4, identifier: "convert_to_mp4")

		self.add(row: convertPhotosSwitchRow!)
		self.add(row: convertVideosSwitchRow!)

		// Instant upload requires at least one configured account
		OCBookmarkManager.shared.loadBookmarks()
		if OCBookmarkManager.shared.bookmarks.count > 0 {
			instantUploadPhotosRow = StaticTableViewRow(switchWithAction: { [weak self] (_, sender) in
				if let convertSwitch = sender as? UISwitch {
					self?.changeAndRequestPhotoLibraryAccessForOption(optionSwitch: convertSwitch, completion: { (switchState) in
						self?.userDefaults.instantUploadPhotos = switchState
						self?.updateDynamicUI()

						self?.userDefaults.instantUploadPhotosAfter = switchState ? Date() : nil

						NotificationCenter.default.post(name: UserDefaults.MediaUploadSettingsChangedNotification, object: nil)
					})
				}
				}, title: "Instant Upload Photos".localized, value: self.userDefaults.instantUploadPhotos)

			instantUploadVideosRow = StaticTableViewRow(switchWithAction: { [weak self] (_, sender) in
				if let convertSwitch = sender as? UISwitch {
					self?.changeAndRequestPhotoLibraryAccessForOption(optionSwitch: convertSwitch, completion: { (switchState) in
						self?.userDefaults.instantUploadVideos = switchState
						self?.updateDynamicUI()

						self?.userDefaults.instantUploaVideosAfter = switchState ? Date() : nil

						NotificationCenter.default.post(name: UserDefaults.MediaUploadSettingsChangedNotification, object: nil)
					})
				}
				}, title: "Instant Upload Videos".localized, value: self.userDefaults.instantUploadVideos)

			bookmarkSelectionRow = StaticTableViewRow(valueRowWithAction: { [weak self] (_, _) in
				self?.showAccountSelectionViewController()
				}, title: "Account".localized, value: "", accessoryType: .disclosureIndicator, identifier: MediaUploadSettingsSection.bookmarkSelectionRowIdentifier)

			uploadPathSelectionRow = StaticTableViewRow(valueRowWithAction: { [weak self] (_, _) in
				self?.showUploadPathSelectionViewController()
				}, title: "Upload Path".localized, value: "", accessoryType: .disclosureIndicator, identifier: MediaUploadSettingsSection.pathSelectionRowIdentifier)

			self.add(row: instantUploadPhotosRow!)
			self.add(row: instantUploadVideosRow!)
		}

		updateDynamicUI()
	}

	private func getSelectedBookmark() -> OCBookmark? {
		if let selectedBookmarkUUID = self.userDefaults.instantUploadBookmarkUUID {
			let bookmarks : [OCBookmark] = OCBookmarkManager.shared.bookmarks as [OCBookmark]
			return bookmarks.filter({ $0.uuid == selectedBookmarkUUID}).first
		}
		return nil
	}

	@discardableResult private func updateBookmarkSelectionRow() -> Bool {
		var accountName = ""
		var foundBookmark = false

		if let selectedBookmark = getSelectedBookmark() {
			accountName = selectedBookmark.shortName
			foundBookmark = true
		}

		bookmarkSelectionRow?.value = accountName

		return foundBookmark
	}

	private func updateUploadPathSelectionRow() {
		var directory = ""
		if let selectedPath = self.userDefaults.instantUploadPath {
			let url = URL(fileURLWithPath: selectedPath)
			directory = url.lastPathComponent
		}

		uploadPathSelectionRow?.value = directory
	}

	private func updateDynamicUI() {

		self.remove(rowWithIdentifier: MediaUploadSettingsSection.bookmarkSelectionRowIdentifier)
		self.remove(rowWithIdentifier: MediaUploadSettingsSection.pathSelectionRowIdentifier)

		if self.userDefaults.instantUploadPhotos || self.userDefaults.instantUploadVideos {
			self.add(row: bookmarkSelectionRow!)
			if updateBookmarkSelectionRow() == true {
				self.add(row: uploadPathSelectionRow!)
				updateUploadPathSelectionRow()
			}
		}
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

	private func showAccountSelectionViewController() {
		let accountSelectionViewController = StaticTableViewController(style: .grouped)
		accountSelectionViewController.navigationItem.title = "Accounts".localized

		let accountsSection = StaticTableViewSection(headerTitle: "Select account".localized)

		var bookmarkRows: [StaticTableViewRow] = []
		let bookmarks = OCBookmarkManager.shared.bookmarks

		guard bookmarks.count > 0 else { return }

		var bookmarkDictionary = [StaticTableViewRow : OCBookmark]()

		for bookmark in bookmarks {
			let row = StaticTableViewRow(buttonWithAction: { [weak self] (_ row, _ sender) in
				accountSelectionViewController.dismissAnimated()

				// Reflect user selection in the UI
				let selectedBookmark = bookmarkDictionary[row]
				self?.userDefaults.instantUploadBookmarkUUID = selectedBookmark?.uuid

				// Remove eventually existing path selection when account is switched
				self?.userDefaults.instantUploadPath = nil

				self?.updateDynamicUI()

				NotificationCenter.default.post(name: UserDefaults.MediaUploadSettingsChangedNotification, object: nil)

			}, title: bookmark.shortName, style: .plain, image: Theme.shared.image(for: "owncloud-logo", size: CGSize(width: 25, height: 25)), imageWidth: 25, alignment: .left)

			bookmarkRows.append(row)
			bookmarkDictionary[row] = bookmark
		}

		accountsSection.add(rows: bookmarkRows)
		accountSelectionViewController.addSection(accountsSection)

		let navigationController = ThemeNavigationController(rootViewController: accountSelectionViewController)

		self.viewController?.present(navigationController, animated: true)

	}

	private func showUploadPathSelectionViewController() {

		guard let bookmark = getSelectedBookmark() else { return }

		OCCoreManager.shared.requestCore(for: bookmark, setup: { (_, _) in },
										 completionHandler: { [weak self] (core, error) in

											if let core = core, error == nil {

												OnMainThread {
													let directoryPickerViewController = ClientDirectoryPickerViewController(core: core, path: "/", selectButtonTitle: "Select Upload Path".localized, avoidConflictsWith: [], choiceHandler: { (selectedDirectory) in
														if selectedDirectory != nil {
															self?.userDefaults.instantUploadPath = selectedDirectory?.path
															self?.updateUploadPathSelectionRow()

															NotificationCenter.default.post(name: UserDefaults.MediaUploadSettingsChangedNotification, object: nil)
														}
													})
													let pickerNavigationController = ThemeNavigationController(rootViewController: directoryPickerViewController)
													self?.viewController?.present(pickerNavigationController, animated: true)
												}
											}

		})
	}
}
