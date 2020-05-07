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

extension ThemedAlertController {

	class func alertControllerForLinkResolution(error:Error?) -> ThemedAlertController {

		var message = "Couldn't find an item corresponding to a private link. If there is no internet connection, eventually it was not yet retrieved from the server".localized

		if let errorMessage = error?.localizedDescription {
			message += "\n\n"
			message += errorMessage
		}

		let alert = ThemedAlertController(title: "Link not resolved".localized, message: message, preferredStyle: .alert)

		let okAction = UIAlertAction(title: "OK", style: .default)

		alert.addAction(okAction)

		return alert
	}
}
