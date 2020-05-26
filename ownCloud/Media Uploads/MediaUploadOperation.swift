//
//  MediaUploadOperation.swift
//  ownCloud
//
//  Created by Michael Neuwert on 26.05.20.
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

import Foundation
import Photos
import ownCloudSDK
import ownCloudAppShared

class MediaUploadOperation : Operation {

	private weak var core: OCCore?
	private var mediaUploadJob: MediaUploadJob
	private var assetId: String

	init(core:OCCore, mediaUploadJob:MediaUploadJob, assetId:String) {
		self.core = core
		self.mediaUploadJob = mediaUploadJob
		self.assetId = assetId
	}

	override func main() {

		guard let core = self.core else {
			return
		}

		// Skip jobs for which local item IDs are valid and known in the scope of the current bookmark
		if let localID = mediaUploadJob.scheduledUploadLocalID {
			if let existingItem = self.findItem(for: localID as String) {
				// If item is found and it's not a placeholder, upload was finished
				if existingItem.isPlaceholder == false {
					// Now upload is done and the job can be removed completely
					if let itemPath = existingItem.path {
						removeUploadJob(with: itemPath)
					}
				}
				// Otherwise if isPlaceholder property is true, then upload is still ongoing, just skip it here
				return
			}
		}

		// Cancellation check-point #1
		if self.isCancelled {
			return
		}

		// Make sure that we have valid upload path
		guard let path = mediaUploadJob.targetPath else { return }

		// Make sure that valid PHAsset is existing
		guard let asset = self.fetchAsset(with: assetId) else {
			// Otherwise remove the job
			removeUploadJob(with: path)
			return
		}

		let importGroup = DispatchGroup()

		// Track the target path
		importGroup.enter()

		OCItemTracker().item(for: core.bookmark, at: path) { (_, _, item) in
			defer {
				importGroup.leave()
			}

			guard let item = item else {
				return
			}

			// Cancellation checkpoint #2
			if self.isCancelled {
				return
			}

			// Perform asset import
			importGroup.enter()
			if let itemLocalId = self.importAsset(asset: asset, at: item, uploadCompletion: {
				// Import successful
				self.removeUploadJob(with: path)
				importGroup.leave()
			})?.localID as OCLocalID? {

				// Update media upload storage object
				core.bookmark.modifyMediaUploadStorage { (storage) in
					storage.update(localItemID: itemLocalId, assetId: self.assetId, targetPath: path)
					return storage
				}
			}
		}

		importGroup.wait()
	}

	// MARK: - Private helpers

	private func removeUploadJob(with targetPath:String) {
		core?.bookmark.modifyMediaUploadStorage { (storage) -> MediaUploadStorage in
			storage.removeJob(with: self.assetId, targetPath: targetPath)
			return storage
		}
	}

	private func findItem(for localID:String) -> OCItem? {
		guard let core = self.core else { return nil }
		guard let database = core.vault.database else { return nil }
		var foundItem: OCItem?

		let semaphore = DispatchSemaphore(value: 0)

		database.retrieveCacheItem(forLocalID: localID, completionHandler: { (_, _, _, item) in
			foundItem = item
			semaphore.signal()
		})

		semaphore.wait()

		return foundItem
	}

	private func fetchAsset(with assetID:String) -> PHAsset? {
		let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
		if fetchResult.count > 0 {
			return fetchResult.object(at: 0)
		}
		return nil
	}

	private func importAsset(asset:PHAsset, at rootItem:OCItem, uploadCompletion: @escaping () -> Void) -> OCItem? {

		guard let core = self.core else { return nil }

		// Determine the list of preferred media formats
		var utisToConvert = [String]()
		var preserveOriginalNames = false

		if let userDefaults = OCAppIdentity.shared.userDefaults {
			if userDefaults.convertHeic {
				utisToConvert.append(AVFileType.heic.rawValue)
			}
			if userDefaults.convertVideosToMP4 {
				utisToConvert.append(AVFileType.mov.rawValue)
			}
			preserveOriginalNames = userDefaults.preserveOriginalMediaFileNames
		}

		if let result = asset.upload(with: core, at: rootItem, utisToConvert: utisToConvert, preserveOriginalName: preserveOriginalNames, progressHandler: nil, uploadCompleteHandler: {
			uploadCompletion()
		}) {
			if let error = result.1 {
				Log.error("Asset upload failed with error \(error)")
			}

			return result.0
		}

		return nil
	}
}
