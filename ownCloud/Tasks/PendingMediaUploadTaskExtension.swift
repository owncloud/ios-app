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
	private var startedUploads: Bool = false

	override func run(background:Bool) {

		func assets(from dictionary:[PHAsset : String], with uploadPath:String) -> [PHAsset] {
			let assets = dictionary.reduce(into: [PHAsset]()) { (result, kvPair) in
				let (key, value) = kvPair
				if value == uploadPath {
					result.append(key)
				}
			}
			return assets
		}

		Log.debug(tagged: ["REMAINING_MEDIA_UPLOAD"], "Started remaining media upload...")

		if let bookmark = OCBookmarkManager.lastBookmarkSelectedForConnection {
			OCCoreManager.shared.requestCore(for: bookmark, setup:nil, completionHandler: {(core, coreError) in
				if core != nil {

					func finalize() {
						OCCoreManager.shared.returnCore(for: bookmark, completionHandler: {
							self.completed()
						})
					}

					guard let pendingUploads = MediaUploadQueue.pendingAssetUploads(for: bookmark) else {
						finalize()
						return
					}

					let uniquePaths = Array(Set(pendingUploads.values))

					core?.fetchUpdates(completionHandler: {(fetchError, _) in
						if fetchError == nil && self.startedUploads == false {

							self.startedUploads = true

							// Iterate over unique upload paths
							let uploadGroup = DispatchGroup()
							for path in uniquePaths {
								uploadGroup.enter()
								// Get assets for current upload path
								let assetsToUpload = assets(from: pendingUploads, with: path)
								// Perform upload
								self.upload(assets: assetsToUpload, with: core!, at: path) {
									uploadGroup.leave()
								}
							}

							uploadGroup.notify(queue: .main, execute: {
								finalize()
							})

						} else {
							Log.error(tagged: ["REMAINING_MEDIA_UPLOAD"], "Fetching bookmark update failed with \(String(describing: fetchError))")
							finalize()
						}
					})
				} else {
					if coreError != nil {
						Log.error(tagged: ["REMAINING_MEDIA_UPLOAD"], "No core returned with error \(String(describing: coreError))")
						self.result = .failure(coreError!)
					}
					self.completed()
				}
			})
		}
	}

	private func upload(assets:[PHAsset], with core:OCCore, at path:String, completion:@escaping () -> Void) {

		self.uploadDirectoryTracking = core.trackItem(atPath: path, trackingHandler: { [weak self] (error, item, isInitial) in

			if isInitial {
				if error != nil {
					Log.error(tagged: ["REMAINING_MEDIA_UPLOAD"], "Error tracking path \(String(describing: error))")
					completion()
				} else {
					if item != nil {
						// Upload assets
						Log.debug(tagged: ["REMAINING_MEDIA_UPLOAD"], "Uploading \(assets.count) assets at \(path)")
						self?.uploadDirectoryTracking = nil
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
