//
//  PendingMediaUploadTaskExtension.swift
//  ownCloud
//
//  Created by Michael Neuwert on 09.10.2019.
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
import ownCloudSDK
import Photos

class PendingMediaUploadTaskExtension : ScheduledTaskAction {

	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.pending_media_upload") }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.appDidComeToForeground] }

	override func run(background:Bool) {

		Log.debug(tagged: ["REMAINING_MEDIA_UPLOAD"], "Preparing...")

		// Do we have a selected bookmark?
		guard let bookmark = OCBookmarkManager.lastBookmarkSelectedForConnection else {
			Log.debug(tagged: ["REMAINING_MEDIA_UPLOAD"], "No bookmark selected...")
			self.completed()
			return
		}

		MediaUploadQueue.shared.setNeedsScheduling(in: bookmark)

		self.completed()
	}
}
