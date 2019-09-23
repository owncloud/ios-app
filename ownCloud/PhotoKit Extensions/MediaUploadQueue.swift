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

	private let uploadSerialQueue = DispatchQueue(label: "com.owncloud.upload.queue", target: DispatchQueue.global(qos: .background))

	static let shared = MediaUploadQueue()

	static let UploadPendingKey = OCKeyValueStoreKey(rawValue: "com.owncloud.upload.queue.upload-pending-flag")

	func uploadAssets(_ assets:[PHAsset], with core:OCCore?, at rootItem:OCItem, progressHandler:((Progress) -> Void)? = nil, assetUploadCompletion:((_ asset:PHAsset?, _ finished:Bool) -> Void)? = nil ) {

		let backgroundTask = OCBackgroundTask(name: "UploadMediaAction", expirationHandler: { (bgTask) in
			Log.warning("UploadMediaAction background task expired")
			bgTask.end()
		}).start()

		let queue = DispatchQueue.global(qos: .userInitiated)

		weak var weakCore = core

		if weakCore != nil {
			let vault : OCVault = OCVault(bookmark: weakCore!.bookmark)
			let flag = NSNumber(value: true)
			vault.keyValueStore?.storeObject(flag, forKey: MediaUploadQueue.UploadPendingKey)
		}

		queue.async {

			guard let userDefaults = OCAppIdentity.shared.userDefaults else { return }

			var prefferedMediaOutputFormats = [String]()
			if userDefaults.convertHeic {
				prefferedMediaOutputFormats.append(String(kUTTypeJPEG))
			}
			if userDefaults.convertVideosToMP4 {
				prefferedMediaOutputFormats.append(String(kUTTypeMPEG4))
			}

			let uploadGroup = DispatchGroup()
			var uploadFailed = false

			for asset in assets {
				if uploadFailed == false {
					uploadGroup.enter()
					self.uploadSerialQueue.async {
						if weakCore != nil {
							weakCore!.perform(inRunningCore: { (runningCoreCompletion) in
								asset.upload(with: weakCore!, at: rootItem, preferredFormats: prefferedMediaOutputFormats, completionHandler: { (item, _) in
									if item == nil {
										uploadFailed = true
									} else {
										assetUploadCompletion?(asset, false)
									}
									runningCoreCompletion()
									uploadGroup.leave()
								}, progressHandler: { (progress) in
									progressHandler?(progress)
								})
							}, withDescription: "Uploading \(assets.count) photo assets")

						} else {
							uploadGroup.leave()
							// Core reference became nil
							uploadFailed = true
						}
					}
					// Avoid submitting to many jobs simultaneously to reduce memory pressure
					_ = uploadGroup.wait()

				} else {
					// Escape on first failed download
					break
				}
			}

			uploadGroup.notify(queue: queue, execute: {
				if weakCore != nil {
					MediaUploadQueue.resetUploadPendingFlag(for:  weakCore!.bookmark)
				}
				backgroundTask?.end()
				assetUploadCompletion?(nil, true)
			})
		}
	}

	class func isMediaUploadPendingFlagSet(for bookmark:OCBookmark) -> Bool {
		let vault : OCVault = OCVault(bookmark: bookmark)
		if vault.keyValueStore?.readObject(forKey: MediaUploadQueue.UploadPendingKey) != nil {
			return true
		} else {
			return false
		}
	}

	class func resetUploadPendingFlag(for bookmark:OCBookmark) {
		let vault : OCVault = OCVault(bookmark: bookmark)
		vault.keyValueStore?.storeObject(nil, forKey: MediaUploadQueue.UploadPendingKey)
	}
}
