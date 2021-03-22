//
//  MediaUploadStorage.swift
//  ownCloud
//
//  Created by Michael Neuwert on 21.11.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
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

class MediaUploadJob : NSObject, NSSecureCoding {

	var targetPath: String?
	var scheduledUploadLocalID: OCLocalID?

	static var supportsSecureCoding: Bool {
		return true
	}

	func encode(with coder: NSCoder) {
		coder.encode(targetPath, forKey: "targetPath")
		coder.encode(scheduledUploadLocalID, forKey: "scheduledUploadLocalID")
	}

	required init?(coder: NSCoder) {
		self.targetPath = coder.decodeObject(forKey: "targetPath") as? String
		self.scheduledUploadLocalID = coder.decodeObject(forKey: "scheduledUploadLocalID") as? OCLocalID
	}

	init(_ path:String) {
		self.targetPath = path
	}
}

class MediaUploadStorage : NSObject, NSSecureCoding {

	var queue: [String]
	var jobs: [String : [MediaUploadJob]]
	var processing: OCProcessSession?

	static var supportsSecureCoding: Bool {
		return true
	}

	var jobCount: Int {
		jobs.reduce(0) {$0 + $1.value.count }
	}

	func encode(with coder: NSCoder) {
		coder.encode(queue, forKey: "queue")
		coder.encode(jobs, forKey: "jobs")
		coder.encode(processing, forKey: "processing")
	}

	required init?(coder: NSCoder) {
		let storedQueue = coder.decodeObject(forKey: "queue") as? [String]
		self.queue = storedQueue != nil ? storedQueue! : [String]()

		let storedJobs =  coder.decodeObject(forKey: "jobs") as? [String : [MediaUploadJob]]
		jobs = storedJobs != nil ? storedJobs! : [String : [MediaUploadJob]]()

		processing = coder.decodeObject(forKey: "processing") as? OCProcessSession
	}

	override init() {
		queue = [String]()
		jobs = [String : [MediaUploadJob]]()
	}

	func addJob(with assetID:String, targetPath:String) {
		if !queue.contains(assetID) {
			self.queue.append(assetID)
		}
		var existingJobs: [MediaUploadJob] = jobs[assetID] != nil ? jobs[assetID]! : [MediaUploadJob]()
		if existingJobs.filter({$0.targetPath == targetPath}).count == 0 {
			existingJobs.append(MediaUploadJob(targetPath))
		}
		jobs[assetID] = existingJobs
	}

	func removeJob(with assetID:String, targetPath:String) {
		if let remainingJobs = jobs[assetID]?.filter({$0.targetPath != targetPath}) {
			jobs[assetID] = remainingJobs
			if remainingJobs.count == 0 {
				if let assetIdQueueIndex = queue.firstIndex(of: assetID) {
					queue.remove(at: assetIdQueueIndex)
				}
			}
		}
	}

	func update(localItemID:OCLocalID, assetId:String, targetPath:String) {
		jobs[assetId]?.filter({$0.targetPath == targetPath}).first?.scheduledUploadLocalID = localItemID
	}
}

typealias MediaUploadStorageModifier = (_ storage:MediaUploadStorage) -> MediaUploadStorage

extension OCBookmark {
	private static let MediaUploadStorageKey = OCKeyValueStoreKey(rawValue: "com.owncloud.media-upload-storage")

	//
	// NOTE: Deriving KV store from bookmark rather than from OCCore since it simplifies adding upload jobs
	// significantly without a need to initialize full blown core for that
	//

	var kvStore : OCKeyValueStore? {
		let vault : OCVault = OCVault(bookmark: self)
		if let store = vault.keyValueStore {

			// Check if NSCoding-compatible classes are not yet registered?
			if store.registeredClasses(forKey: OCBookmark.MediaUploadStorageKey) == nil {

				// This weird trickery is required since Set<AnyHashable> can't be created directly
				if let classSet = NSSet(array: [MediaUploadStorage.self,
												MediaUploadJob.self,
												OCProcessSession.self,
												NSArray.self,
												NSDictionary.self,
												NSString.self]) as? Set<AnyHashable> {

					store.registerClasses(classSet, forKey: OCBookmark.MediaUploadStorageKey)
				}
			}
			return store
		}
		return nil
	}

	func modifyMediaUploadStorage(with modifier: @escaping MediaUploadStorageModifier) {
		self.kvStore?.updateObject(forKey: OCBookmark.MediaUploadStorageKey, usingModifier: { (value, changesMadePtr) -> Any? in
			var storage = value as? MediaUploadStorage

			if storage == nil {
				storage = MediaUploadStorage()
			}

			storage = modifier(storage!)

			changesMadePtr.pointee = true

			return storage
		})
	}

	var mediaUploadStorage : MediaUploadStorage? {
		return self.kvStore?.readObject(forKey: OCBookmark.MediaUploadStorageKey) as? MediaUploadStorage
	}
}
