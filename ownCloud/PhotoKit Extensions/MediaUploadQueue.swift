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

class MediaUploadQueue : OCActivitySource {

	private var uploadActivity: MediaUploadActivity?

	static var shared = MediaUploadQueue()

	// MARK: - OCActivitySource protocol implementation

	func provideActivity() -> OCActivity {
		return self.uploadActivity!
	}

	var activityIdentifier: OCActivityIdentifier {
		if let activity = self.uploadActivity {
			return activity.identifier
		} else {
			return OCActivityIdentifier(rawValue: "")
		}
	}

	// MARK: - Public interface

	func addUpload(_ asset:PHAsset, for bookmark:OCBookmark, at path:String) {

		bookmark.modifyMediaUploadStorage { (storage) -> MediaUploadStorage in
			storage.addJob(with: asset.localIdentifier, targetPath: path)
			return storage
		}

		self.setNeedsScheduling(in: bookmark)
	}

	func addUploads(_ assets:[PHAsset], for bookmark:OCBookmark, at path:String) {
		bookmark.modifyMediaUploadStorage { (storage) -> MediaUploadStorage in
			for asset in assets {
				storage.addJob(with: asset.localIdentifier, targetPath: path)
			}
			return storage
		}
		self.setNeedsScheduling(in: bookmark)
	}

	private var _needsSchedulingCountByBookmarkUUID : [UUID : Int] = [:]
	func setNeedsScheduling(in bookmark: OCBookmark) {
		// Increment counter by one
		_needsSchedulingCountByBookmarkUUID[bookmark.uuid] = (_needsSchedulingCountByBookmarkUUID[bookmark.uuid] ?? 0) + 1

		// Schedule right away. If it's already busy, it'll return quickly. If not, it'll schedule.
		self.scheduleUploads(in: bookmark)
	}

	func scheduleUploads(in bookmark:OCBookmark) {

		var uploadStorageAlreadyProcessing = false
		var uploadStorageQueueEmpty = false
		var needsSchedulingCountAtEntry = _needsSchedulingCountByBookmarkUUID[bookmark.uuid]

		// Avoid race conditions by performing checks and modifications atomically
		bookmark.modifyMediaUploadStorage { (mediaUploadStorage) -> MediaUploadStorage in
			// First check if there are any media upload jobs stored
			if mediaUploadStorage.jobCount == 0 {
				uploadStorageQueueEmpty = true
			} else {
				// Check if upload queue processing can be started and no-one else is processing it
				if mediaUploadStorage.processing != nil {
					// Found OCProcessSession instance -> check if it is valid though
					if OCProcessManager.shared.isSessionValid(mediaUploadStorage.processing!, usingThoroughChecks: true) {
						// If the process session is valid, may be it is being used by running extension --> bail out
						uploadStorageAlreadyProcessing = true
					} else {
						// Remove invalid session
						mediaUploadStorage.processing = nil
					}
				}

				if mediaUploadStorage.processing == nil {
					// Mark the queue as being processed
                    			mediaUploadStorage.processing = OCProcessManager.shared.processSession
				}
			}

			return mediaUploadStorage
		}

		if uploadStorageAlreadyProcessing || uploadStorageQueueEmpty {
			// Already processing or nothing to do
			return
		}

		// Request a core for the passed bookmark
		OCCoreManager.shared.requestCore(for: bookmark, setup:nil, completionHandler: {(core, _) in

			if let core = core {

				// This method is called when media import is finished or cancelled either by published activity or through unrecoverable error
				func finalizeImport() {
					self.unpublishImportActivity(for: core)

					OCCoreManager.shared.returnCore(for: bookmark, completionHandler: nil)

					// Mark the media upload storage as not in use anymore
					bookmark.modifyMediaUploadStorage { (mediaUploadStorage) in
						mediaUploadStorage.processing = nil
						return mediaUploadStorage
					}

					// Check if .setNeedsScheduling() has been called since starting the scheduling:
					// since any new entries added to the queue after scheduling has started will not be handled,
					// it's important to start scheduling again if any change to the queue has been performed since
					if needsSchedulingCountAtEntry != self._needsSchedulingCountByBookmarkUUID[bookmark.uuid] {
						self.scheduleUploads(in: bookmark)
					}
				}

				// Publish activity including number of jobs to be processed
				guard let uploadStorage = bookmark.mediaUploadStorage else { return }

				self.publishImportActivity(for: core, itemCount: uploadStorage.jobCount)

				// Create background task used to continue media upload in the background
				let backgroundTask = OCBackgroundTask(name: "com.owncloud.media-upload-task", expirationHandler: { (bgTask) in
					Log.warning("UploadMediaAction background task expired")
					bgTask.end()
				}).start()

				let queue = DispatchQueue.global(qos: .background)
				let importGroup = DispatchGroup()

				queue.async {
					// Make copies to avoid side effects of caching that KVS might perform
					let assetIDQueue : [String] = uploadStorage.queue
					let jobsByAssetID : [String : [MediaUploadJob]] = uploadStorage.jobs

					// Iterate over PHObject local asset IDs
					for assetId in assetIDQueue {

						if let assetJobs = jobsByAssetID[assetId] {
							// Iterate over jobs associated with asset ID
							for job in assetJobs {

								// Check if the import activity has been cancelled
								if self.isImportActivityCancelled() {
									// Remove all stored jobs
									bookmark.modifyMediaUploadStorage { (_) -> MediaUploadStorage in
										return MediaUploadStorage()
									}

									finalizeImport()
									return
								}

								// Skip jobs for which local item IDs are valid and known in the scope of the current bookmark
								if let localID = job.scheduledUploadLocalID {
									if let existingItem = self.findItem(in: core, for: localID as String) {
										// If item is found and it's not a placeholder, upload was finished
										if existingItem.isPlaceholder == false {
											// Now upload is done and the job can be removed completely
											if let itemPath = existingItem.path {
												bookmark.modifyMediaUploadStorage { (storage) -> MediaUploadStorage in
													storage.removeJob(with: assetId, targetPath: itemPath)
													return storage
												}
											}
										}
										// Otherwise if isPlaceholder property is true, then upload is still ongoing, just skip it here
										continue
									}
								}

								// Found a job which requires an import operation
								if let asset = self.fetchAsset(with: assetId), let path = job.targetPath {

									importGroup.enter()

									// Convert target path to the OCItem object
									var tracking = core.trackItem(atPath: path) { (_, item, isInitial) in

										if isInitial == true {

											defer {
												importGroup.leave()
											}

											if let rootItem = item {
												// Perform asset import
												if let itemLocalId = self.importAsset(asset: asset, using: core, at: rootItem, uploadCompletion: {

													// Now upload is done and the job can be removed completely
													bookmark.modifyMediaUploadStorage { (storage) -> MediaUploadStorage in
														storage.removeJob(with: assetId, targetPath: path)
														return storage
													}

												})?.localID as OCLocalID? {

													// Update import activity
													self.updateActivityAfterFinishedImport(for: core)

													// Update media upload storage object
													bookmark.modifyMediaUploadStorage { (storage) in
														storage.update(localItemID: itemLocalId, assetId: assetId, targetPath: path)
														return storage
													}
												}
											}
										}
									}
								}

								importGroup.wait()
							}
						}
					}

					// Wait until all to-be-uploaded assets are processed
					importGroup.notify(queue: queue, execute: {
						// Finish background task
						backgroundTask?.end()
						finalizeImport()
					})
				}
			}
		})
	}

	// MARK: - Private helper methods

	private func findItem(in core:OCCore, for localID:String) -> OCItem? {
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

	private func importAsset(asset:PHAsset, using core:OCCore, at rootItem:OCItem, uploadCompletion: @escaping () -> Void) -> OCItem? {

		// Determine the list of preferred media formats
		var prefferedMediaOutputFormats = [String]()

		if let userDefaults = OCAppIdentity.shared.userDefaults {
			if userDefaults.convertHeic {
				prefferedMediaOutputFormats.append(String(kUTTypeJPEG))
			}
			if userDefaults.convertVideosToMP4 {
				prefferedMediaOutputFormats.append(String(kUTTypeMPEG4))
			}
		}

		if let result = asset.upload(with: core, at: rootItem, preferredFormats: prefferedMediaOutputFormats, progressHandler: nil, uploadCompleteHandler: {
			uploadCompletion()
		}) {
			if let error = result.1 {
				Log.error("Asset upload failed with error \(error)")
			}

			return result.0
		}

		return nil
	}

	// MARK: - Activity management

	private func publishImportActivity(for core:OCCore, itemCount:Int) {
		let activityId = "MediaUploadQueue:\(UUID())"
        self.uploadActivity = MediaUploadActivity(identifier: OCActivityIdentifier(rawValue: activityId), assetCount: itemCount)
		core.activityManager.update(OCActivityUpdate.publishingActivity(for: self))
	}

	private func updateActivityAfterFinishedImport(for core:OCCore) {
		self.uploadActivity?.updateAfterSingleFinishedUpload()
		core.activityManager.update(OCActivityUpdate.updatingActivity(for: self))
	}

	private func unpublishImportActivity(for core:OCCore) {
		core.activityManager.update(OCActivityUpdate.unpublishActivity(for: self))
	}

	private func isImportActivityCancelled() -> Bool {
		if let activity = self.uploadActivity {
			return activity.isCancelled
		}
		return false
	}

}
