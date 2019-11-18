//
//  MediaUploadQueue.swift
//  ownCloud
//
//  Created by Michael Neuwert on 07.08.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2019, ownCloud GmbH.
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
import MobileCoreServices


class MediaUploadQueue {

	private static let PendingAssetsKey = OCKeyValueStoreKey(rawValue: "com.owncloud.upload.queue.upload-pending-assets")

	static var shared = MediaUploadQueue()

	func uploadAssets(_ assets:[PHAsset], with core:OCCore?, at rootItem:OCItem, progressHandler:((Progress) -> Void)? = nil, assetUploadCompletion:((_ asset:PHAsset?, _ finished:Bool) -> Void)? = nil ) {

		guard let userDefaults = OCAppIdentity.shared.userDefaults else { return }

		// Determine the list of preferred media formats
		var prefferedMediaOutputFormats = [String]()
		if userDefaults.convertHeic {
			prefferedMediaOutputFormats.append(String(kUTTypeJPEG))
		}
		if userDefaults.convertVideosToMP4 {
			prefferedMediaOutputFormats.append(String(kUTTypeMPEG4))
		}

		// Create background task used to continue media upload in the background
		let backgroundTask = OCBackgroundTask(name: "UploadMediaAction", expirationHandler: { (bgTask) in
			Log.warning("UploadMediaAction background task expired")
			bgTask.end()
		}).start()

		let queue = DispatchQueue.global(qos: .background)

		weak var weakCore = core

		if weakCore != nil {

			// TODO: Activity started

			// Submit upload job on the background queue
			queue.async {

				// Add pending assets
				MediaUploadQueue.updatePending(assets, for: weakCore!.bookmark, at: rootItem)

				let uploadGroup = DispatchGroup()
				uploadGroup.enter()
				weakCore!.perform(inRunningCore: { (runningCoreCompletion) in

					for asset in assets {
						let result = asset.upload(with: weakCore!, at: rootItem, preferredFormats: prefferedMediaOutputFormats, progressHandler: { (progress) in
							progressHandler?(progress)
						})

						// Was OCItem created upon importing the asset file?
						if result?.0 != nil, let path = rootItem.path {
							assetUploadCompletion?(asset, false)
							MediaUploadQueue.removePending(asset: asset.localIdentifier, path:path, for: weakCore!.bookmark)

						}
					}
					runningCoreCompletion()
					uploadGroup.leave()

				}, withDescription: "Uploading \(assets.count) photo assets")

				// Wait until all to-be-uploaded assets are processed
				uploadGroup.notify(queue: queue, execute: {

					// Finish background task
					backgroundTask?.end()
					assetUploadCompletion?(nil, true)

					// TODO: Activity completed
				})
			}
		}
	}

	class func updatePending(_ assets:[PHAsset], for bookmark:OCBookmark, at rootItem:OCItem) {
		let vault : OCVault = OCVault(bookmark: bookmark)
		let assetIds : [String] = assets.map({ $0.localIdentifier })
		var uploads = [String : String]()

		assetIds.forEach { (assetLocalId) in
			uploads[assetLocalId] = rootItem.path
		}

		vault.keyValueStore?.updateObject(forKey: MediaUploadQueue.PendingAssetsKey, usingModifier: { (oldValue, changesMadePtr) -> Any? in
			changesMadePtr.pointee = true

			var newValue = oldValue as? NSMutableDictionary

			if newValue == nil {
				newValue = NSMutableDictionary()
			}

			for (assetId, path) in uploads {
				if newValue![assetId] != nil {
					let oldPathSet = newValue![assetId] as? NSMutableSet
					oldPathSet?.add(path)
				} else {
					let pathSet = NSMutableSet()
					pathSet.add(path)
					newValue?.setObject(pathSet, forKey: NSString(string: assetId))
				}
			}

			return newValue
		})
	}

	class func removePending(asset identifier:String, path:String, for bookmark:OCBookmark) {
		let vault : OCVault = OCVault(bookmark: bookmark)

		vault.keyValueStore?.updateObject(forKey: MediaUploadQueue.PendingAssetsKey, usingModifier: { (value, changesMadePtr) -> Any? in
			let uploads = value as? NSMutableDictionary

			if uploads?[identifier] != nil {
				let pathSet = uploads?[identifier] as? NSMutableSet
				pathSet?.remove(path)
				if pathSet?.count == 0 {
					uploads?.removeObject(forKey: identifier)
				}
				changesMadePtr.pointee = true
			}

			return uploads
		})
	}

	class func pendingAssetUploads(for bookmark:OCBookmark) -> [String : Set<PHAsset>]? {
		let vault : OCVault = OCVault(bookmark: bookmark)

		if let uploads = vault.keyValueStore?.readObject(forKey: MediaUploadQueue.PendingAssetsKey) as? NSDictionary {

			if let assetIds = uploads.allKeys as? [String] {

				// Fetch assets from the photo library
				let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: Array(assetIds), options: nil)
				if fetchResult.count > 0 {
					var assetUploads = [String : Set<PHAsset>]()
					fetchResult.enumerateObjects({ (asset, _, _) in
						// Transform dictionary where key is the asset id and value set of paths into
						// k: path, v: set of assets
						if let pathSet = uploads[asset.localIdentifier] as? Set<String> {
							for path in pathSet {
								if assetUploads[path] == nil {
									assetUploads[path] = Set<PHAsset>([asset])
								} else {
									assetUploads[path]?.insert(asset)
								}
							}
						}
					})
					return assetUploads
				}
			}
		}
		return nil
	}
}
