//
//  PendingMediaUploadTaskExtension.swift
//  ownCloud
//
//  Created by Michael Neuwert on 09.10.2019.
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

class PendingMediaUploadTaskExtension : ScheduledTaskAction {

	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.pending_media_upload") }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.appDidComeToForeground] }
	override class var features : [String : Any]? { return [ FeatureKeys.runOnWifi : true] }

	private var uploadDirectoryTracking: OCCoreItemTracking?
	private var selectedBookmark: OCBookmark?
	private weak var weakCore: OCCore?
	private var coreUpdatesHandler: OCCoreItemListFetchUpdatesCompletionHandler?

	override func run(background:Bool) {

		Log.debug(tagged: ["REMAINING_MEDIA_UPLOAD"], "Preparing...")

		self.coreUpdatesHandler = {(fetchError:Error?, foundUpdates:Bool) in
			if fetchError != nil {
				Log.error(tagged: ["REMAINING_MEDIA_UPLOAD"], "Fetching bookmark update failed with \(String(describing: fetchError))")
				self.cleanup()
				return
			}

			self.coreUpdatesHandler = nil

			Log.debug(tagged: ["REMAINING_MEDIA_UPLOAD"], "Started remaining media upload...")

			self.fetchAndContinuePendingUploads()
		}

		// Do we have a selected bookmark?
		guard let bookmark = OCBookmarkManager.lastBookmarkSelectedForConnection else {
			Log.debug(tagged: ["REMAINING_MEDIA_UPLOAD"], "No bookmark selected...")
			self.completed()
			return
		}
		self.selectedBookmark = bookmark

		// Request a core for the bookmark
		OCCoreManager.shared.requestCore(for: bookmark, setup:nil, completionHandler: { [weak self] (core, coreError) in
			if coreError != nil {
				Log.error(tagged: ["REMAINING_MEDIA_UPLOAD"], "No core returned with error \(String(describing: coreError))")
				self?.result = .failure(coreError!)
				self?.cleanup()
				return
			}

			self?.weakCore = core

			// Fetch core updates
			if let core = self?.weakCore {
				core.fetchUpdates(completionHandler: {(fetchError, foundUpdates) in
					self?.coreUpdatesHandler?(fetchError, foundUpdates)
				})
			}
		})
	}

	private func cleanup() {
		if let bookmark = self.selectedBookmark {
			OCCoreManager.shared.returnCore(for: bookmark, completionHandler: {
				self.completed()
			})
		}
	}

	private func fetchAndContinuePendingUploads() {
		guard let bookmark = self.selectedBookmark else {
			cleanup()
			return
		}

		guard let pendingUploads = MediaUploadQueue.pendingAssetUploads(for: bookmark) else {
			cleanup()
			return
		}

		guard let core = weakCore else {
			cleanup()
			return
		}

		Log.debug(tagged: ["REMAINING_MEDIA_UPLOAD"], "Started remaining media upload...")

		// Iterate assets and paths of unfinished uploads
		let uploadGroup = DispatchGroup()

		for (path, assetSet) in pendingUploads {
			uploadGroup.enter()
			// Perform upload
			self.upload(assets: Array(assetSet), with: core, at: path) {
				uploadGroup.leave()
			}
		}

		// All uploads are finished
		uploadGroup.notify(queue: .main, execute: {
			Log.debug(tagged: ["REMAINING_MEDIA_UPLOAD"], "Finished remaining media upload...")
			self.cleanup()
		})
	}

	private func upload(assets:[PHAsset], with core:OCCore, at path:String, completion:@escaping () -> Void) {

		Log.debug(tagged: ["REMAINING_MEDIA_UPLOAD"], "Starting tracking \(path)")
		self.uploadDirectoryTracking = core.trackItem(atPath: path, trackingHandler: { [weak self] (error, item, isInitial) in

			if isInitial {
				if error != nil {
					Log.error(tagged: ["REMAINING_MEDIA_UPLOAD"], "Error tracking path \(String(describing: error))")
					completion()
				} else {
					if item != nil {
						Log.debug(tagged: ["REMAINING_MEDIA_UPLOAD"], "Uploading \(assets.count) assets at \(path)")

						// Stop tracking
						self?.uploadDirectoryTracking = nil

						// Upload assets
						MediaUploadQueue.shared.uploadAssets(assets, with: core, at: item!) { (_, finished) in
							if finished {
								completion()
							}
						}
					} else {
						Log.warning(tagged: ["REMAINING_MEDIA_UPLOAD"], "Upload directory not found")
						completion()
					}
				}
			} else {
				self?.uploadDirectoryTracking = nil
			}
		})
	}
}
