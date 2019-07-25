//
//  InstantMediaUploadTaskExtension.swift
//  ownCloud
//
//  Created by Michael Neuwert on 24.07.2019.
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

class InstantMediaUploadTaskExtension : ScheduledTaskAction, OCCoreDelegate {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.instant_media_upload") }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.appBackgroundFetch] }
	override class var features : [String : Any]? { return [ FeatureKeys.runOnWifi : true] }

	override func run(background:Bool) {
		
	}

	func core(_ core: OCCore, handleError error: Error?, issue: OCIssue?) {
		// TODO
	}
}
