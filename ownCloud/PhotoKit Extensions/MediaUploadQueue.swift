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

	// MARK: - Notifications emitted by MediaUploadQueue

	static let AssetImportStarted = Notification(name: Notification.Name(rawValue: "AssetImportStarted"))
	static let AssetImportFinished = Notification(name: Notification.Name(rawValue: "AssetImportFinished"))
	static let AssetImported = Notification(name: Notification.Name(rawValue: "AssetImported"))

	private static let UploadPendingKey = OCKeyValueStoreKey(rawValue: "com.owncloud.upload.queue.upload-pending-flag")
	private static let PendingAssetsKey = OCKeyValueStoreKey(rawValue: "com.owncloud.upload.queue.upload-pending-assets")

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
			// Store persistent flag indicating that media upload was started
			let vault : OCVault = OCVault(bookmark: weakCore!.bookmark)
			let flag = NSNumber(value: true)
			vault.keyValueStore?.storeObject(flag, forKey: MediaUploadQueue.UploadPendingKey)

			OnMainThread {
				NotificationCenter.default.post(name: MediaUploadQueue.AssetImportStarted.name, object: NSNumber(value: assets.count))
			}

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
						if result?.0 != nil {
							assetUploadCompletion?(asset, false)
							MediaUploadQueue.removePending(asset: asset.localIdentifier, for: weakCore!.bookmark)

							OnMainThread {
								NotificationCenter.default.post(name: MediaUploadQueue.AssetImported.name, object: nil)
							}
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

					OnMainThread {
						NotificationCenter.default.post(name: MediaUploadQueue.AssetImportFinished.name, object: nil)
					}
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

		vault.keyValueStore?.updateObject(forKey: MediaUploadQueue.PendingAssetsKey, usingModifier: { (_, changesMadePtr) -> Any? in
			changesMadePtr.pointee = true
			return uploads as NSDictionary?
		})

		vault.keyValueStore?.storeObject(uploads as NSDictionary, forKey: MediaUploadQueue.PendingAssetsKey)
	}

	class func removePending(asset identifier:String, for bookmark:OCBookmark) {
		let vault : OCVault = OCVault(bookmark: bookmark)

		vault.keyValueStore?.updateObject(forKey: MediaUploadQueue.PendingAssetsKey, usingModifier: { (value, changesMadePtr) -> Any? in
			var uploads = value as? [String : String]

			if uploads != nil {
				uploads?.removeValue(forKey: identifier)
				changesMadePtr.pointee = true
			}

			return uploads as NSDictionary?
		})
	}

	class func pendingAssetUploads(for bookmark:OCBookmark) -> [PHAsset : String]? {
		let vault : OCVault = OCVault(bookmark: bookmark)
		if let uploads = vault.keyValueStore?.readObject(forKey: MediaUploadQueue.PendingAssetsKey) as? [String : String] {
			let assetIds = uploads.keys
			let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: Array(assetIds), options: nil)
			if fetchResult.count > 0 {
				var assetUploads = [PHAsset : String]()
				fetchResult.enumerateObjects({ (asset, _, _) in
					let path = uploads[asset.localIdentifier]
					assetUploads[asset] = path
				})
				return assetUploads
			}
		}
		return nil
	}
}
