//
//  OCDrive+Interactions.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 30.05.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK
import ownCloudApp

extension OCDrive {
	func rootLocation(with context: ClientContext?) -> OCLocation {
		let location = self.rootLocation

		if location.bookmarkUUID == nil {
			location.bookmarkUUID = context?.core?.bookmark.uuid
		}

		return location
	}
}

// MARK: - Selection > Open
extension OCDrive: DataItemSelectionInteraction {
	public func openItem(from viewController: UIViewController?, with context: ClientContext?, animated: Bool, pushViewController: Bool, completion: ((Bool) -> Void)?) -> UIViewController? {
		let rootLocation = self.rootLocation(with: context)
		return rootLocation.openItem(from: viewController, with: context, animated: animated, pushViewController: pushViewController, completion: completion)
	}
}
