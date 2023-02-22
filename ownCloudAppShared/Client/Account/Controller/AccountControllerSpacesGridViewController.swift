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
import ownCloudSDK

class AccountControllerSpacesGridViewController: CollectionViewController, ViewControllerPusher {
	var spacesSection: CollectionViewSection
	var noSpacesCondition: DataSourceCondition?

	init(with context: ClientContext) {
		let gridContext = ClientContext(with: context)

		gridContext.postInitializationModifier = { (owner, context) in
			context.viewControllerPusher = owner as? ViewControllerPusher
		}

		spacesSection = CollectionViewSection(identifier: "spaces", dataSource: context.core?.projectDrivesDataSource, cellStyle: .init(with: .gridCell), cellLayout: .grid(itemWidthDimension: .fractionalWidth(0.33), itemHeightDimension: .absolute(200), contentInsets: NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)))

		super.init(context: gridContext, sections: [ spacesSection ], useStackViewRoot: true, hierarchic: false)

		self.revoke(in: gridContext, when: [ .connectionClosed ])

		navigationItem.title = "Spaces".localized

		if let projectDrivesDataSource = context.core?.projectDrivesDataSource {
			let noSpacesMessage = ComposedMessageView(elements: [
				.image(OCSymbol.icon(forSymbolName: "square.grid.2x2")!, size: CGSize(width: 64, height: 48), alignment: .centered),
				.text("No spaces".localized, style: .system(textStyle: .title3, weight: .semibold), alignment: .centered)
			])

			noSpacesCondition = DataSourceCondition(.empty, with: projectDrivesDataSource, initial: true, action: { [weak self] condition in
				let coverView = (condition.fulfilled == true) ? noSpacesMessage : nil
				self?.setCoverView(coverView, layout: .top)
			})
		}
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
