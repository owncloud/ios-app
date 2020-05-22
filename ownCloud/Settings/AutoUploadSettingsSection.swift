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

	enum AutoUploadKeys : String {
		case InstantUploadPhotosKey = "instant-upload-photos"
		case InstantUploadVideosKey = "instant-upload-videos"
		case InstantUploadBookmarkUUIDKey = "instant-upload-bookmark-uuid"
		case InstantUploadPathKey = "instant-upload-path"
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

	public var instantUploadBookmarkUUID: UUID? {
		set {
			self.set(newValue?.uuidString, forKey: AutoUploadKeys.InstantUploadBookmarkUUIDKey.rawValue)
		}

		get {
			if let uuidString = self.string(forKey: AutoUploadKeys.InstantUploadBookmarkUUIDKey.rawValue) {
				return UUID(uuidString: uuidString)
			} else {
				return nil
			}
		}
	}

	public var instantUploadPath: String? {

		set {
			self.set(newValue, forKey: AutoUploadKeys.InstantUploadPathKey.rawValue)
		}

		get {
			return self.string(forKey: AutoUploadKeys.InstantUploadPathKey.rawValue)
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

	public func resetInstantUploadConfiguration() {
		self.instantUploadBookmarkUUID = nil
		self.instantUploadPath = nil
		self.instantUploadPhotos = false
		self.instantUploadVideos = false
	}
}

class AutoUploadSettingsSection: SettingsSection {

	private static let bookmarkAndPathSelectionRowIdentifier = "bookmarkAndPathSelectionRowIdentifier"

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
				}, title: "Auto Upload Photos".localized, value: self.userDefaults.instantUploadPhotos)

			instantUploadVideosRow = StaticTableViewRow(switchWithAction: { [weak self] (_, sender) in
				if let convertSwitch = sender as? UISwitch {
					self?.changeAndRequestPhotoLibraryAccessForOption(optionSwitch: convertSwitch, completion: { (switchState) in
						self?.setupVideoAutoUpload(enabled: switchState)
					})
				}
				}, title: "Auto Upload Videos".localized, value: self.userDefaults.instantUploadVideos)

			bookmarkAndPathSelectionRow = StaticTableViewRow(subtitleRowWithAction: { [weak self] (_, _) in
				self?.showAccountSelectionViewController()
				}, title: "Upload Path".localized, subtitle: "", accessoryType: .disclosureIndicator, identifier: AutoUploadSettingsSection.bookmarkAndPathSelectionRowIdentifier)

			self.add(row: instantUploadPhotosRow!)
			self.add(row: instantUploadVideosRow!)

			updateDynamicUI()
		}
	}

	private func setupPhotoAutoUpload(enabled:Bool) {
		userDefaults.instantUploadPhotos = enabled
		userDefaults.instantUploadPhotosAfter = enabled ? Date() : nil

		if enabled == true, uploadLocationSelected == false {
			showAccountSelectionViewController()
		} else {
			postSettingsChangedNotification()
		}
	}

	private func setupVideoAutoUpload(enabled:Bool) {
		userDefaults.instantUploadVideos = enabled
		userDefaults.instantUploadVideosAfter = enabled ? Date() : nil

		if enabled == true, uploadLocationSelected == false {
			showAccountSelectionViewController()
		} else {
			postSettingsChangedNotification()
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

		self.remove(rowWithIdentifier: AutoUploadSettingsSection.bookmarkAndPathSelectionRowIdentifier)

		guard let bookmark = getSelectedBookmark(), let path = self.userDefaults.instantUploadPath else {
			self.userDefaults.resetInstantUploadConfiguration()
			self.instantUploadPhotosRow?.value = self.userDefaults.instantUploadPhotos
			self.instantUploadVideosRow?.value = self.userDefaults.instantUploadVideos
			return
		}

		OCItemTracker().item(for: bookmark, at: path) { (error, _, pathItem) in
			guard error == nil else { return }

			OnMainThread {
				if pathItem != nil {
					self.add(row: self.bookmarkAndPathSelectionRow!)
					let directory = URL(fileURLWithPath: path).lastPathComponent
					self.bookmarkAndPathSelectionRow?.value = "\(bookmark.shortName)/\(directory)"
				} else {
					self.userDefaults.resetInstantUploadConfiguration()
					self.showAutoUploadDisabledAlert()
				}
				self.instantUploadPhotosRow?.value = self.userDefaults.instantUploadPhotos
				self.instantUploadVideosRow?.value = self.userDefaults.instantUploadVideos
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
				self?.selectUploadPath(for: selectedBookmark, pushIn: navigationController, completion: { (directoryItem) in
					self?.userDefaults.instantUploadPath = self?.getDirectoryPath(from: directoryItem)
					if self?.userDefaults.instantUploadPath == nil {
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

	private func selectUploadPath(for bookmark:OCBookmark, pushIn navigationController:UINavigationController, completion:@escaping (_ directoryItem:OCItem?) -> Void) {

		OCCoreManager.shared.requestCore(for: bookmark, setup: { (_, _) in },
										 completionHandler: { [weak navigationController] (core, error) in

											guard let core = core, error == nil else { return }

											OnMainThread {
												let directoryPickerViewController = ClientDirectoryPickerViewController(core: core, path: "/", selectButtonTitle: "Select Upload Path".localized, avoidConflictsWith: [], choiceHandler: { (selectedDirectory) in
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
