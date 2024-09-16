//
//  UIAlertViewController+SystemPermissions.swift
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
import ownCloudAppShared
import ownCloudSDK

extension UIAlertController {

	class func alertControllerForPhotoLibraryAuthorizationInSettings() -> UIAlertController {
		let alert = ThemedAlertController(title: OCLocalizedString("Missing permissions", nil), message: OCLocalizedString("This permission is needed to upload photos and videos from your photo library.", nil), preferredStyle: .alert)

		let settingAction = UIAlertAction(title: OCLocalizedString("Settings", nil), style: .default, handler: { _ in
			UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
		})
		let notNowAction = UIAlertAction(title: OCLocalizedString("Not now", nil), style: .cancel)

		alert.addAction(settingAction)
		alert.addAction(notNowAction)

		return alert
	}
}
