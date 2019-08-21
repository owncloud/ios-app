//
//  BackgroundFetchUpdateTaskAction.swift
//  ownCloud
//
//  Created by Michael Neuwert on 13.06.2019.
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

class BackgroundFetchUpdateTaskAction : ScheduledTaskAction, OCCoreDelegate {

	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.background_update") }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.appBackgroundFetch] }
	override class var features : [String : Any]? { return [ FeatureKeys.runOnWifi : true] }

	override func run(background:Bool) {

		self.completion = { (task) in
			Log.log("Background fetch of updates finished with result \(String(describing: task.result))")
		}

		super.run(background: background)

		var errorCount = 0
		var lastError: Error = NSError(ocError: .internal)
		let coreUpdateGroup = DispatchGroup()

		// Iterate through bookmarks
		OCBookmarkManager.shared.loadBookmarks()

		for bookmark in OCBookmarkManager.shared.bookmarks {

			// Request cores for the bookmarks and add them to the list
			coreUpdateGroup.enter()
			OCCoreManager.shared.requestCore(for: bookmark, setup:nil, completionHandler: { (core, _) in
				if let core = core {
					core.delegate = self

					// Fetch updates from the backend
					core.fetchUpdates(completionHandler: { (error, foundChanges) in

						if foundChanges {
							Log.log("Found changes in core \(core)")
						}

						if error != nil {
							lastError = error!
							errorCount += 1
							Log.error("fetchUpdates() for \(core) returned with error \(error!)")
						} else {
							Log.log("Fetched updates for core \(core)")
						}

						// Give up the core ASAP to minimize traffic
						OCCoreManager.shared.returnCore(for: bookmark, completionHandler: {
							coreUpdateGroup.leave()
						})
					})
				}
			})
		}

		// Handle update completion
		coreUpdateGroup.notify(queue: DispatchQueue.main) {
			if errorCount == 0 {
				self.result = .success(nil)
			} else {
				self.result = .failure(lastError)
			}
			self.completed()
		}
	}

	func core(_ core: OCCore, handleError error: Error?, issue: OCIssue?) {
		if let error = error {
			self.result = .failure(error)
			Log.error("Error \(String(describing: error))")
		}
		completed()
	}
}
