//
//  MeidaUploadQueue.swift
//  ownCloud
//
//  Created by Michael Neuwert on 07.08.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import Foundation
import ownCloudSDK
import Photos
import MobileCoreServices

class MediaUploadQueue {
	private let uploadSerialQueue = DispatchQueue(label: "com.owncloud.upload.queue", target: DispatchQueue.global(qos: .background))

	static let shared = MediaUploadQueue()

	func uploadAssets(_ assets:[PHAsset], with core:OCCore, at rootItem:OCItem, progressHandler:((Progress)->Void)? = nil, assetUploadCompletion:((_ asset:PHAsset)->Void)? = nil ) {

		let queue = DispatchQueue.global(qos: .userInitiated)

		queue.async {

			guard let userDefaults = OCAppIdentity.shared.userDefaults else { return }

			var prefferedMediaOutputFormats = [String]()
			if userDefaults.convertHeic {
				prefferedMediaOutputFormats.append(String(kUTTypeJPEG))
			}
			if userDefaults.convertVideosToMP4 {
				prefferedMediaOutputFormats.append(String(kUTTypeJPEG))
			}

			core.perform(inRunningCore: { (runningCoreCompletion) in

				let uploadGroup = DispatchGroup()
				var uploadFailed = false

				for asset in assets {
					if uploadFailed == false {
						// Upload image on a background queue
						uploadGroup.enter()

						self.uploadSerialQueue.async {
							asset.upload(with: core, at: rootItem, preferredFormats: prefferedMediaOutputFormats, completionHandler: { (item, _) in
								if item == nil {
									uploadFailed = true
								} else {
									assetUploadCompletion?(asset)
								}
								uploadGroup.leave()
							}, progressHandler: { (progress) in
								progressHandler?(progress)
							})
						}

						// Avoid submitting to many jobs simultaneously to reduce memory pressure
						_ = uploadGroup.wait(timeout: .now() + 0.5)

					} else {
						// Escape on first failed download
						break
					}
				}

				uploadGroup.notify(queue: queue, execute: {
					runningCoreCompletion()
				})

			}, withDescription: "Uploading \(assets.count) photo assets")
		}
	}

}
