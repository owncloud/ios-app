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
import AVFoundation
import ownCloudAppShared

extension OCCellularSwitchIdentifier {
    static let photoUploadCellularSwitchIdentifier = OCCellularSwitchIdentifier(rawValue: "cellular-photo-upload")
    static let videoUploadCellularSwitchIdentifier = OCCellularSwitchIdentifier(rawValue: "video-photo-upload")
}

class MediaUploadQueue : OCActivitySource {

	private var uploadActivity: MediaUploadActivity?

	static var shared = MediaUploadQueue()

	let importQueue = OperationQueue()

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

	func setup() {
		let photoCellularSwitch = OCCellularSwitch(identifier: .photoUploadCellularSwitchIdentifier, localizedName: "Photo upload".localized, defaultValue: true, maximumTransferSize: 0)
		let videoCellularSwitch = OCCellularSwitch(identifier: .videoUploadCellularSwitchIdentifier, localizedName: "Video upload".localized, defaultValue: true, maximumTransferSize: 0)

		OCCellularManager.shared.registerSwitch(photoCellularSwitch)
		OCCellularManager.shared.registerSwitch(videoCellularSwitch)

		importQueue.qualityOfService = .utility
		importQueue.maxConcurrentOperationCount = ProcessInfo.processInfo.activeProcessorCount
	}

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

	func cancelUploads() {
		importQueue.cancelAllOperations()
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
		let needsSchedulingCountAtEntry = _needsSchedulingCountByBookmarkUUID[bookmark.uuid]

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
					Log.warning("MediaUploadQueue background task expired")
					self.importQueue.cancelAllOperations()
					bgTask.end()
				}).start()

				OnBackgroundQueue {
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

								// Create an upload operation and schedule it
								let operation = MediaUploadOperation(core: core, mediaUploadJob: job, assetId: assetId)
								operation.completionBlock = {
									// Update import activity
									self.updateActivityAfterFinishedImport(for: core)
								}
								self.importQueue.addOperation(operation)

							}
						}
					}

					// Wait until all to-be-uploaded assets are processed
					self.importQueue.waitUntilAllOperationsAreFinished()
					// Finish background task
					backgroundTask?.end()
					finalizeImport()
				}
			}
		})
	}

	// MARK: - Activity management

	private func publishImportActivity(for core:OCCore, itemCount:Int) {
		let activityId = "MediaUploadQueue:\(UUID())"
        self.uploadActivity = MediaUploadActivity(identifier: activityId, assetCount: itemCount)
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
