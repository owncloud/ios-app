//
//  UIAlertController+UniversalLinks.swift
//  ownCloud
//
//  Created by Michael Neuwert on 20.04.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
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

extension ThemedAlertController {

	class func alertControllerForUnresolvedLink(offline:Bool, accountFound:Bool) -> ThemedAlertController {

		var message = ""

		if !accountFound {
			message = "Link points to an account bookmark which is not configured in the app.".localized
		} else if offline {
			message = "Couldn't resolve a private link since you are offline and corresponding item is not cached locally.".localized
		} else {
			message = "Couldn't resolve a private link since the item is not known to the server.".localized
		}

		let alert = ThemedAlertController(title: "Link resolution failed".localized, message: message, preferredStyle: .alert)

		let okAction = UIAlertAction(title: "OK", style: .default)

		alert.addAction(okAction)

		return alert
	}
}
