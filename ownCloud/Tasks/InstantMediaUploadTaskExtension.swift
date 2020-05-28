//
//  InstantMediaUploadTaskExtension.swift
//  ownCloud
//
//  Created by Michael Neuwert on 24.07.2019.
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

import Foundation
import ownCloudSDK
import Photos
import UserNotifications

class InstantMediaUploadTaskExtension : ScheduledTaskAction {

	enum MediaType {
		case images, videos, imagesAndVideos
	}

	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.instant_media_upload") }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.appDidComeToForeground, .appDidBecomeBackgrounded] }
	override class var features : [String : Any]? { return [ FeatureKeys.photoLibraryChanged : true] }

	private var uploadDirectoryTracking: OCCoreItemTracking?

	override func run(background:Bool) {
		guard let userDefaults = OCAppIdentity.shared.userDefaults else { return }

		var enqueuedAssetCount = 0

		if  userDefaults.instantUploadPhotos == true {
			if let bookmarkUUID = userDefaults.instantPhotoUploadBookmarkUUID, let path = userDefaults.instantPhotoUploadPath {
				if let bookmark = OCBookmarkManager.shared.bookmark(for: bookmarkUUID) {
					enqueuedAssetCount += uploadPhotoAssets(for: bookmark, at: path)
				}
			} else {
				Log.warning(tagged: ["INSTANT_MEDIA_UPLOAD"], "Instant photo upload enabled, but bookmark or path not configured")
			}
		}

		if  userDefaults.instantUploadVideos == true {
			if let bookmarkUUID = userDefaults.instantVideoUploadBookmarkUUID, let path = userDefaults.instantVideoUploadPath {
				if let bookmark = OCBookmarkManager.shared.bookmark(for: bookmarkUUID) {
					enqueuedAssetCount += uploadVideoAssets(for: bookmark, at: path)
				}
			} else {
				Log.warning(tagged: ["INSTANT_MEDIA_UPLOAD"], "Instant video upload enabled, but bookmark or path not configured")
			}
		}

		if background == true && enqueuedAssetCount > 0 {

			func postMediaUploadsEnqueudNotification() {
				let center = UNUserNotificationCenter.current()
				let content = UNMutableNotificationContent()

				content.title = "Background uploads".localized
				content.body = String(format: "Scheduled upload of %ld media assets".localized, enqueuedAssetCount)

				let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)

				let identifier = "com.ownloud.instant-media-upload-notification"
				let request = UNNotificationRequest(identifier: identifier,
							  content: content, trigger: trigger)
				center.add(request, withCompletionHandler: { (error) in
				  if error != nil {
					Log.warning(tagged: ["INSTANT_MEDIA_UPLOAD"], "Failed to schedule local user notification")
				  }
				})
			}

			let center = UNUserNotificationCenter.current()
			center.getNotificationSettings(completionHandler: { (settings) in
				if settings.authorizationStatus == .authorized {
					postMediaUploadsEnqueudNotification()
				}
			})
		}
	}

	private func uploadPhotoAssets(for bookmark:OCBookmark, at path:String) -> Int {
		guard let userDefaults = OCAppIdentity.shared.userDefaults else { return 0 }

		var photoAssets = [PHAsset]()

        Log.debug(tagged: ["INSTANT_MEDIA_UPLOAD"], "Fetching images created after \(String(describing: userDefaults.instantUploadPhotosAfter))")

		// Add photo assets
		if let uploadPhotosAfter = userDefaults.instantUploadPhotosAfter {
			let fetchResult = PHAsset.fetchAssetsFromCameraRoll(with: [.image], createdAfter: uploadPhotosAfter)
			if fetchResult != nil {
				fetchResult!.enumerateObjects({ (asset, _, _) in
					photoAssets.append(asset)
				})
			}
		}

		Log.debug(tagged: ["INSTANT_MEDIA_UPLOAD"], "Importing \(photoAssets.count) photo assets")

		if photoAssets.count > 0 {
			MediaUploadQueue.shared.addUploads(Array(photoAssets), for: bookmark, at: path)
			userDefaults.instantUploadPhotosAfter = photoAssets.last?.creationDate
            Log.debug(tagged: ["INSTANT_MEDIA_UPLOAD"], "Last added photo asset modification date: \(String(describing: userDefaults.instantUploadPhotosAfter))")
		}

		return photoAssets.count
	}

	private func uploadVideoAssets(for bookmark:OCBookmark, at path:String) -> Int {
		guard let userDefaults = OCAppIdentity.shared.userDefaults else { return 0 }

		var videoAssets = [PHAsset]()

        Log.debug(tagged: ["INSTANT_MEDIA_UPLOAD"], "Fetching videos created after \(String(describing: userDefaults.instantUploadVideosAfter))")

		// Add video assets
		if let uploadVideosAfter = userDefaults.instantUploadVideosAfter {
			let fetchResult = PHAsset.fetchAssetsFromCameraRoll(with: [.video], createdAfter: uploadVideosAfter)
			if fetchResult != nil {
				fetchResult!.enumerateObjects({ (asset, _, _) in
					videoAssets.append(asset)
				})
			}
		}

		Log.debug(tagged: ["INSTANT_MEDIA_UPLOAD"], "Importing \(videoAssets.count) video assets")

		if videoAssets.count > 0 {
			MediaUploadQueue.shared.addUploads(videoAssets, for: bookmark, at: path)
			userDefaults.instantUploadVideosAfter = videoAssets.last?.creationDate
            Log.debug(tagged: ["INSTANT_MEDIA_UPLOAD"], "Last added video asset modification date: \(String(describing: userDefaults.instantUploadPhotosAfter))")
		}

		return videoAssets.count
	}

	private func showFeatureDisabledAlert() {
		OnMainThread {
			let alertController = ThemedAlertController(with: "Auto upload disabled".localized,
																	message: "Auto upload of media was disabled since configured account / folder was not found".localized)
			UIApplication.shared.currentWindow()?.rootViewController?.present(alertController, animated: true, completion: nil)
		}
	}
}
