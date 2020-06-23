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
		case PreserveOriginalFilenames = "preserve-original-filenames"
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

	public var preserveOriginalMediaFileNames: Bool {
		set {
			self.set(newValue, forKey: MediaUploadKeys.PreserveOriginalFilenames.rawValue)
		}

		get {
			return self.bool(forKey: MediaUploadKeys.PreserveOriginalFilenames.rawValue)
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

	public var instantUploadVideosAfter: Date? {
		set {
			self.set(newValue, forKey: MediaUploadKeys.InstantUploadVideosAfterDateKey.rawValue)
		}

		get {
			return self.value(forKey: MediaUploadKeys.InstantUploadVideosAfterDateKey.rawValue) as? Date
		}
	}

	public func resetInstantUploadConfiguration() {
		self.instantUploadBookmarkUUID = nil
		self.instantUploadPath = nil
		self.instantUploadPhotos = false
		self.instantUploadVideos = false
	}
}

class MediaUploadSettingsSection: SettingsSection {

	private static let bookmarkAndPathSelectionRowIdentifier = "bookmarkAndPathSelectionRowIdentifier"

	private var convertPhotosSwitchRow: StaticTableViewRow?
	private var convertVideosSwitchRow: StaticTableViewRow?
	private var preserveMediaFileNamesSwitchRow: StaticTableViewRow?

	private var instantUploadPhotosRow: StaticTableViewRow?
	private var instantUploadVideosRow: StaticTableViewRow?

	private var bookmarkAndPathSelectionRow: StaticTableViewRow?

	private var uploadLocationSelected : Bool {
		if self.userDefaults.instantUploadBookmarkUUID != nil && self.userDefaults.instantUploadPath != nil {
			return true
		} else {
			return false
		}
	}

	private var uploadPathTracking: OCCoreItemTracking?

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

		preserveMediaFileNamesSwitchRow = StaticTableViewRow(switchWithAction: { [weak self] (_, sender) in
			if let convertSwitch = sender as? UISwitch {
				self?.userDefaults.preserveOriginalMediaFileNames = convertSwitch.isOn
			}
			}, title: "Preserve original media file names".localized, value: self.userDefaults.preserveOriginalMediaFileNames, identifier: "preserve_media_file_names")

		self.add(row: convertPhotosSwitchRow!)
		self.add(row: convertVideosSwitchRow!)
		self.add(row: preserveMediaFileNamesSwitchRow!)

		// Instant upload requires at least one configured account
		if OCBookmarkManager.shared.bookmarks.count > 0 {
			instantUploadPhotosRow = StaticTableViewRow(switchWithAction: { [weak self] (_, sender) in
				if let convertSwitch = sender as? UISwitch {
					self?.changeAndRequestPhotoLibraryAccessForOption(optionSwitch: convertSwitch, completion: { (switchState) in
						self?.userDefaults.instantUploadPhotos = switchState
						self?.userDefaults.instantUploadPhotosAfter = switchState ? Date() : nil

						if switchState, let locationSelected = self?.uploadLocationSelected, locationSelected == false {
							self?.showAccountSelectionViewController()
						} else {
							self?.postSettingsChangedNotification()
						}

					})
				}
				}, title: "Auto Upload Photos".localized, value: self.userDefaults.instantUploadPhotos)

			instantUploadVideosRow = StaticTableViewRow(switchWithAction: { [weak self] (_, sender) in
				if let convertSwitch = sender as? UISwitch {
					self?.changeAndRequestPhotoLibraryAccessForOption(optionSwitch: convertSwitch, completion: { (switchState) in
						self?.userDefaults.instantUploadVideos = switchState
						self?.userDefaults.instantUploadVideosAfter = switchState ? Date() : nil

						if switchState, let locationSelected = self?.uploadLocationSelected, locationSelected == false {
							self?.showAccountSelectionViewController()
						} else {
							self?.postSettingsChangedNotification()
						}
					})
				}
				}, title: "Auto Upload Videos".localized, value: self.userDefaults.instantUploadVideos)

			bookmarkAndPathSelectionRow = StaticTableViewRow(valueRowWithAction: { [weak self] (_, _) in
				self?.showAccountSelectionViewController()
				}, title: "Upload Path".localized, value: "", accessoryType: .disclosureIndicator, identifier: MediaUploadSettingsSection.bookmarkAndPathSelectionRowIdentifier)

			self.add(row: instantUploadPhotosRow!)
			self.add(row: instantUploadVideosRow!)

			updateDynamicUI()
		}
	}

	private func getSelectedBookmark() -> OCBookmark? {
		if let selectedBookmarkUUID = self.userDefaults.instantUploadBookmarkUUID {
			let bookmarks : [OCBookmark] = OCBookmarkManager.shared.bookmarks as [OCBookmark]
			return bookmarks.filter({ $0.uuid == selectedBookmarkUUID}).first
		}
		return nil
	}

	private func updateDynamicUI() {

		func updateInstantUploadSwtches() {
			OnMainThread {
				self.instantUploadPhotosRow?.value = self.userDefaults.instantUploadPhotos
				self.instantUploadVideosRow?.value = self.userDefaults.instantUploadVideos
			}
		}

		self.remove(rowWithIdentifier: MediaUploadSettingsSection.bookmarkAndPathSelectionRowIdentifier)

		if let bookmark = getSelectedBookmark(), let path = self.userDefaults.instantUploadPath {

			OCCoreManager.shared.requestCore(for: bookmark, setup: { (_, _) in },
											 completionHandler: { (core, error) in
												if core != nil, error == nil {
													core?.fetchUpdates(completionHandler: { (fetchError, _) in
														if fetchError == nil {
															self.uploadPathTracking = core?.trackItem(atPath: path, trackingHandler: { (_, pathItem, isInitial) in
																if isInitial {
																	if pathItem != nil {
																		OnMainThread {
																			self.add(row: self.bookmarkAndPathSelectionRow!)
																			let directory = URL(fileURLWithPath: path).lastPathComponent
																			self.bookmarkAndPathSelectionRow?.value = "\(bookmark.shortName)/\(directory)"
																		}
																	} else {
																		self.userDefaults.resetInstantUploadConfiguration()
																		OnMainThread {
																			let alertController = ThemedAlertController(with: "Auto upload disabled".localized,
																													message: "Auto upload of media was disabled since configured account / folder was not found".localized)
																			self.viewController?.present(alertController, animated: true, completion: nil)
																		}
																	}
																	updateInstantUploadSwtches()
																	OCCoreManager.shared.returnCore(for: bookmark, completionHandler: nil)
																} else {
																	self.uploadPathTracking = nil
																}
															})
														} else {
															OCCoreManager.shared.returnCore(for: bookmark, completionHandler: nil)

														}
													})
												}
			})

		} else {
			self.userDefaults.resetInstantUploadConfiguration()
			updateInstantUploadSwtches()
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

				let selectedBookmark = bookmarkDictionary[row]!
				self?.userDefaults.instantUploadBookmarkUUID = selectedBookmark.uuid
				self?.userDefaults.instantUploadPath = nil

				// Proceed with upload path selection
				self?.selectUploadPath(for: selectedBookmark, pushIn: navigationController, completion: { (success) in
					if !success && self?.userDefaults.instantUploadPath == nil {
						self?.userDefaults.resetInstantUploadConfiguration()
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

	private func selectUploadPath(for bookmark:OCBookmark, pushIn navigationController:UINavigationController, completion:@escaping (_ success:Bool) -> Void) {

		OCCoreManager.shared.requestCore(for: bookmark, setup: { (_, _) in },
										 completionHandler: { [weak self, weak navigationController] (core, error) in

											if let core = core, error == nil {

												OnMainThread {
													let directoryPickerViewController = ClientDirectoryPickerViewController(core: core, path: "/", selectButtonTitle: "Select Upload Path".localized, avoidConflictsWith: [], choiceHandler: { (selectedDirectory) in
														var success = false
														OCCoreManager.shared.returnCore(for: bookmark, completionHandler: nil)

														if let directory = selectedDirectory {
															if directory.permissions.contains(.createFile) {
																print("Can create files")
																self?.userDefaults.instantUploadPath = selectedDirectory?.path
																success = true
															} else {
																OnMainThread {
																	let alert = ThemedAlertController(title: "Missing permissions".localized, message: "This permission is needed to upload photos and videos from your photo library.".localized, preferredStyle: .alert)
																	alert.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: nil))
																	self?.viewController?.present(alert, animated: true, completion: nil)
																}
															}
														}

														completion(success)
													})
													navigationController?.pushViewController(directoryPickerViewController, animated: true)
												}
											}
		})
	}

	private func postSettingsChangedNotification() {
		NotificationCenter.default.post(name: UserDefaults.MediaUploadSettingsChangedNotification, object: nil)
	}
}
