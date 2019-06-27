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

	var cores = [OCCore]()

	override func run(background:Bool) {

		self.completion = { (task) in

			// Return cores synchronously
			for bookmark in OCBookmarkManager.shared.bookmarks {
				let waitForCoreSemaphore = DispatchSemaphore(value: 0)
				OCCoreManager.shared.returnCore(for: bookmark, completionHandler: {
					waitForCoreSemaphore.signal()
				})
				_ = waitForCoreSemaphore.wait()
			}

			Log.log("Background fetch of updates finished with result \(String(describing: task.result))")
		}

		super.run(background: background)

		// Iterate through bookmarks
		OCBookmarkManager.shared.loadBookmarks()

		for bookmark in OCBookmarkManager.shared.bookmarks {

			// Request cores for the bookmarks and add them to the list
			let waitForCoreSemaphore = DispatchSemaphore(value: 0)
			OCCoreManager.shared.requestCore(for: bookmark, setup:nil, completionHandler: { (core, _) in
				if let core = core {
					core.delegate = self
					self.cores.append(core)
				}
				waitForCoreSemaphore.signal()
			})
			_ = waitForCoreSemaphore.wait()
		}

		// Start fetching updates for requested cores
		var coresUpdated = 0
		if cores.count > 0 {
			for core in cores {
				core.fetchUpdates { (error, success) in
					coresUpdated += 1
					if self.cores.count == coresUpdated {
						if success {
							self.result = .success(nil)
						} else if error != nil {
							self.result = .failure(error!)
						}
						self.completed()
					}
				}
			}
		} else {
			completed()
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
