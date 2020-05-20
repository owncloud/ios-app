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

class InstantMediaUploadTaskExtension : ScheduledTaskAction {

	enum MediaType {
		case images, videos, imagesAndVideos
	}

	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.instant_media_upload") }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.appDidComeToForeground] }
	override class var features : [String : Any]? { return [ FeatureKeys.photoLibraryChanged : true, FeatureKeys.runOnWifi : true] }

	private var uploadDirectoryTracking: OCCoreItemTracking?

	override func run(background:Bool) {
		guard let userDefaults = OCAppIdentity.shared.userDefaults else { return }

		guard userDefaults.instantUploadPhotos == true || userDefaults.instantUploadVideos == true else { return }

		guard let bookmarkUUID = userDefaults.instantUploadBookmarkUUID else {
            Log.warning(tagged: ["INSTANT_MEDIA_UPLOAD"], "Instant media upload enabled, but bookmark not configured")
            return
        }

		guard let path = userDefaults.instantUploadPath else {
            Log.warning(tagged: ["INSTANT_MEDIA_UPLOAD"], "Instant media upload enabled, but path not configured")
            return
        }

		if let bookmark = OCBookmarkManager.shared.bookmark(for: bookmarkUUID) {
			uploadMediaAssets(for: bookmark, at: path)
		}
	}

	private func uploadMediaAssets(for bookmark:OCBookmark, at path:String) {
		guard let userDefaults = OCAppIdentity.shared.userDefaults else { return }

		var photoAssets = [PHAsset]()

        Log.debug(tagged: ["INSTANT_MEDIA_UPLOAD"], "Fetching images created after \(String(describing: userDefaults.instantUploadPhotosAfter))")

		// Add photo assets
		if let uploadPhotosAfter = userDefaults.instantUploadPhotosAfter {
			let fetchResult = self.fetchAssetsFromCameraRoll(with: [.image], createdAfter: uploadPhotosAfter)
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

		var videoAssets = [PHAsset]()

        Log.debug(tagged: ["INSTANT_MEDIA_UPLOAD"], "Fetching videos created after \(String(describing: userDefaults.instantUploadVideosAfter))")

		// Add video assets
		if let uploadVideosAfter = userDefaults.instantUploadVideosAfter {
			let fetchResult = self.fetchAssetsFromCameraRoll(with: [.image], createdAfter: uploadVideosAfter)
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
	}

	private func fetchAssetsFromCameraRoll(with mediaTypes:[PHAssetMediaType], createdAfter:Date? = nil) -> PHFetchResult<PHAsset>? {

		guard PHPhotoLibrary.authorizationStatus() == .authorized else { return nil }

		let collectionResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
																	   subtype: .smartAlbumUserLibrary,
																	   options: nil)

		if let cameraRoll = collectionResult.firstObject {
			let imageTypePredicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
			let videoTypePredicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)

			var typePredicatesArray = [NSPredicate]()

			if mediaTypes.contains(.image) {
				typePredicatesArray.append(imageTypePredicate)
			}

			if mediaTypes.contains(.video) {
				typePredicatesArray.append(videoTypePredicate)
			}

			let mediaTypesPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: typePredicatesArray)

			let fetchOptions = PHFetchOptions()

			if let date = createdAfter {
				let creationDatePredicate = NSPredicate(format: "creationDate > %@", date as NSDate)
				fetchOptions.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [mediaTypesPredicate, creationDatePredicate])
			} else {
				fetchOptions.predicate = mediaTypesPredicate
			}

			let sort = NSSortDescriptor(key: "creationDate", ascending: true)
			fetchOptions.sortDescriptors = [sort]

            Log.debug(tagged: ["INSTANT_MEDIA_UPLOAD"], "Fetching assets with options \(fetchOptions.debugDescription)")

			return PHAsset.fetchAssets(in: cameraRoll, options: fetchOptions)
		}

		return nil
	}

	private func showFeatureDisabledAlert() {
		OnMainThread {
			let alertController = ThemedAlertController(with: "Auto upload disabled".localized,
																	message: "Auto upload of media was disabled since configured account / folder was not found".localized)
			UIApplication.shared.currentWindow()?.rootViewController?.present(alertController, animated: true, completion: nil)
		}
	}
}
