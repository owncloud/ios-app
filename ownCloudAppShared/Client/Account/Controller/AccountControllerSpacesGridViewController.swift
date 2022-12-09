//
//  AccountControllerSpacesGridViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 29.11.22.
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

class AccountControllerSpacesGridViewController: CollectionViewController, ViewControllerPusher {
	var spacesSection: CollectionViewSection

	init(with context: ClientContext) {
		let gridContext = ClientContext(with: context)

		gridContext.postInitializationModifier = { (owner, context) in
			context.viewControllerPusher = owner as? ViewControllerPusher
		}

		spacesSection = CollectionViewSection(identifier: "spaces", dataSource: context.core?.projectDrivesDataSource, cellStyle: .init(with: .gridCell), cellLayout: .grid(itemWidthDimension: .fractionalWidth(0.33), itemHeightDimension: .absolute(200), contentInsets: NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)))

		super.init(context: gridContext, sections: [ spacesSection ], useStackViewRoot: true, hierarchic: false)

		self.revoke(in: gridContext, when: [ .connectionClosed ])

		navigationItem.title = "Spaces".localized
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func pushViewController(context: ClientContext?, provider: (ClientContext) -> UIViewController?, push: Bool, animated: Bool) -> UIViewController? {
		var viewController: UIViewController?

		if let context {
			viewController = provider(context)
		}

		if push, let viewController {
			navigationController?.pushViewController(viewController, animated: animated)
		}

		return viewController
	}
}
