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

class InstantMediaUploadTaskExtension : ScheduledTaskAction, OCCoreDelegate {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.instant_media_upload") }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.appBackgroundFetch] }
	override class var features : [String : Any]? { return [ FeatureKeys.runOnWifi : true] }

	override func run(background:Bool) {
		guard let userDefaults = OCAppIdentity.shared.userDefaults else { return }

		guard userDefaults.instantUploadPhotos == true || userDefaults.instantUploadVideos == true else { return }

		guard let bookmarkUUID = userDefaults.instantUploadBookmarkUUID else { return }

		guard let path = userDefaults.instantUploadPath else { return }

		if let bookmark = OCBookmarkManager.shared.bookmark(for: bookmarkUUID) {

			OCCoreManager.shared.requestCore(for: bookmark, setup:nil, completionHandler: { (core, _) in
				if let core = core {
					core.delegate = self
					// TODO:
				}
			})
		}


	}

	func core(_ core: OCCore, handleError error: Error?, issue: OCIssue?) {
		// TODO
	}

	func fetchAssetsFromCameraRoll(_ includeVideos:Bool, createdAfter:Date? = nil) -> PHFetchResult<PHAsset>? {

		guard PHPhotoLibrary.authorizationStatus() == .authorized else { return nil }

		let collectionResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
																	   subtype: .smartAlbumUserLibrary,
																	   options: nil)

		if let cameraRoll = collectionResult.firstObject {
			let imageTypePredicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
			let videoTypePredicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

			var typePredicatesArray = [NSPredicate]()
			typePredicatesArray.append(imageTypePredicate)
			if includeVideos {
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

			return PHAsset.fetchAssets(in: cameraRoll, options: fetchOptions)
		}

		return nil
	}
}
