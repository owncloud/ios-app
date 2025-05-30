//
//  RecentLocation+Interactions.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 21.05.25.
//  Copyright © 2025 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2025, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

extension RecentLocation : DataItemSelectionInteraction {
	func handleSelection(in viewController: UIViewController?, with context: ClientContext?, completion: ((Bool, Bool) -> Void)?) -> Bool {
		// Determine if this location is presented in the context of a ClientLocationPickerViewController ..
		var parentViewController = viewController

		while !(parentViewController is ClientLocationPickerViewController) && parentViewController?.parent != nil {
			parentViewController = parentViewController?.parent
		}

		// .. if it is: navigate to the location!
		if let locationPicker = (parentViewController as? ClientLocationPickerViewController)?.locationPicker, let location {
			locationPicker.navigate(to: location)
			return true
		}

		return false
	}
}
