//
//  PHPhotoLibrary+Extension.swift
//  ownCloud
//
//  Created by Michael Neuwert on 17.07.2019.
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

import UIKit
import Photos

extension PHPhotoLibrary {

	class func requestAccess(completion:@escaping (_ accessGranted:Bool) -> Void) {
		let permisson = PHPhotoLibrary.authorizationStatus()

		func requestAuthorization() {
			PHPhotoLibrary.requestAuthorization({ newStatus in
				let authorized = newStatus == .authorized ? true : false
				OnMainThread {
					completion(authorized)
				}
			})
		}

		switch permisson {
		case .authorized:
			OnMainThread {
				completion(true)
			}

		case .notDetermined:
			requestAuthorization()

		default:
			requestAuthorization()
		}
	}
}
