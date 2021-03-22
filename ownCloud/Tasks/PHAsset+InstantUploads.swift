//
//  PHAsset+InstantUploads.swift
//  ownCloud
//
//  Created by Michael Neuwert on 25.05.20.
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

import Photos
import ownCloudAppShared

extension PHAsset {
	static func fetchAssetsFromCameraRoll(with mediaTypes:[PHAssetMediaType], createdAfter:Date? = nil, fetchLimit:Int = 0) -> PHFetchResult<PHAsset>? {

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
			fetchOptions.fetchLimit = fetchLimit

            Log.debug("Fetching assets with options \(fetchOptions.debugDescription)")

			return PHAsset.fetchAssets(in: cameraRoll, options: fetchOptions)
		}

		return nil
	}
}
