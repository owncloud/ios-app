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

// MARK: - Selection > Open
extension OCDrive : DataItemSelectionInteraction {
	public func openItem(from viewController: UIViewController?, with context: ClientContext?, animated: Bool, pushViewController: Bool, completion: ((Bool) -> Void)?) -> UIViewController? {
		let driveContext = ClientContext(with: context, modifier: { context in
			context.drive = self
		})
		let query = OCQuery(for: self.rootLocation)
		DisplaySettings.shared.updateQuery(withDisplaySettings: query)

		let rootFolderViewController = context?.pushViewControllerToNavigation(context: driveContext, provider: { context in
			let location = self.rootLocation

			if location.bookmarkUUID == nil {
				location.bookmarkUUID = driveContext.core?.bookmark.uuid
			}

			return ClientItemViewController(context: context, query: query, location: location).revoke(in: context, when: [ .connectionClosed, .driveRemoved ])
		}, push: pushViewController, animated: animated)

		completion?(true)

		return rootFolderViewController
	}
}
