//
//  OCLocation+Interactions.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 21.11.22.
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
extension OCLocation : DataItemSelectionInteraction {
	public func openItem(from viewController: UIViewController?, with context: ClientContext?, animated: Bool, pushViewController: Bool, completion: ((Bool) -> Void)?) -> UIViewController? {
		let driveContext = ClientContext(with: context, modifier: { context in
			if let driveID = self.driveID, let core = context.core {
				context.drive = core.drive(withIdentifier: driveID)
			}
		})
		let query = OCQuery(for: self)
		DisplaySettings.shared.updateQuery(withDisplaySettings: query)

		let locationViewController = context?.pushViewControllerToNavigation(context: driveContext, provider: { context in
			let viewController = ClientItemViewController(context: context, query: query)

			viewController.revoke(in: context, when: [ .connectionClosed, .driveRemoved ])

			if let presentable = OCDataRenderer.default.renderItem(self, asType: .presentable, error: nil, withOptions: nil) as? OCDataItemPresentable {
				viewController.navigationTitle = presentable.title
			}

			return viewController
		}, push: pushViewController, animated: animated)

		completion?(true)

		return locationViewController
	}
}
