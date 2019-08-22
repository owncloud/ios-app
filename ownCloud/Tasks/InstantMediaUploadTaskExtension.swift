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

	enum MediaType {
		case images, videos, imagesAndVideos
	}

	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.instant_media_upload") }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.appDidComeToForeground] }
	override class var features : [String : Any]? { return [ FeatureKeys.photoLibraryChanged : true, FeatureKeys.runOnWifi : true] }

	override func run(background:Bool) {
		guard let userDefaults = OCAppIdentity.shared.userDefaults else { return }

		guard userDefaults.instantUploadPhotos == true || userDefaults.instantUploadVideos == true else { return }

		guard let bookmarkUUID = userDefaults.instantUploadBookmarkUUID else { return }

		guard let path = userDefaults.instantUploadPath else { return }

		if let bookmark = OCBookmarkManager.shared.bookmark(for: bookmarkUUID) {

			OCCoreManager.shared.requestCore(for: bookmark, setup:nil, completionHandler: { (core, _) in
				if let core = core {
					core.delegate = self

					let pathQuery = OCQuery(forPath: path)
					pathQuery.changesAvailableNotificationHandler = { query in
						if query.state == .idle {
							core.stop(query)

							let uploadGroup = DispatchGroup()

							if let rootItem = query.rootItem {

								var assets = [PHAsset]()

								// Add photo assets
								if let uploadPhotosAfter = userDefaults.instantUploadPhotosAfter {
									let fetchResult = self.fetchAssetsFromCameraRoll(.images, createdAfter: uploadPhotosAfter)
									if fetchResult != nil {
										fetchResult!.enumerateObjects({ (asset, _, _) in
											assets.append(asset)
										})
									}
								}

								// Add video assets
								if let uploadVideosAfter = userDefaults.instantUploaVideosAfter {
									let fetchResult = self.fetchAssetsFromCameraRoll(.videos, createdAfter: uploadVideosAfter)
									if fetchResult != nil {
										fetchResult!.enumerateObjects({ (asset, _, _) in
											assets.append(asset)
										})
									}
								}

								if assets.count > 0 {
									uploadGroup.enter()
									self.upload(assets: assets, with: core, at: rootItem, completion: { () in
										uploadGroup.leave()
									})
								}
							}

							uploadGroup.notify(queue: DispatchQueue.main, execute: {
								OCCoreManager.shared.returnCore(for: bookmark, completionHandler: {
									self.completed()
								})
							})
						}
					}
					core.start(pathQuery)
				}
			})
		}
	}

	func core(_ core: OCCore, handleError error: Error?, issue: OCIssue?) {
		if let error = error {
			self.result = .failure(error)
			Log.error("Error \(String(describing: error))")
		}
		completed()
	}

	private func upload(assets:[PHAsset], with core:OCCore, at rootItem:OCItem, completion:@escaping () -> Void) {
		
		guard let userDefaults = OCAppIdentity.shared.userDefaults else { return }

		if assets.count > 0 {
			MediaUploadQueue.shared.uploadAssets(assets, with: core, at: rootItem, assetUploadCompletion: { (asset, finished) in
				if let asset = asset {
					switch asset.mediaType {
					case .image:
						userDefaults.instantUploadPhotosAfter = asset.modificationDate
					case .video:
						userDefaults.instantUploaVideosAfter = asset.modificationDate
					default:
						break
					}
				}
				if finished {
					completion()
				}
			})
		}
	}

	private func fetchAssetsFromCameraRoll(_ mediaType:MediaType, createdAfter:Date? = nil) -> PHFetchResult<PHAsset>? {

		guard PHPhotoLibrary.authorizationStatus() == .authorized else { return nil }

		let collectionResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
																	   subtype: .smartAlbumUserLibrary,
																	   options: nil)

		if let cameraRoll = collectionResult.firstObject {
			let imageTypePredicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
			let videoTypePredicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)

			var typePredicatesArray = [NSPredicate]()

			switch mediaType {
			case .images:
				typePredicatesArray.append(imageTypePredicate)
			case .videos:
				typePredicatesArray.append(videoTypePredicate)
			case .imagesAndVideos:
				typePredicatesArray.append(imageTypePredicate)
				typePredicatesArray.append(videoTypePredicate)
			}

			let mediaTypesPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: typePredicatesArray)

			let fetchOptions = PHFetchOptions()

			if let date = createdAfter {
				let creationDatePredicate = NSPredicate(format: "modificationDate > %@", date as NSDate)
				fetchOptions.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [mediaTypesPredicate, creationDatePredicate])
			} else {
				fetchOptions.predicate = mediaTypesPredicate
			}

			let sort = NSSortDescriptor(key: "modificationDate", ascending: true)
			fetchOptions.sortDescriptors = [sort]

			return PHAsset.fetchAssets(in: cameraRoll, options: fetchOptions)
		}

		return nil
	}
}
