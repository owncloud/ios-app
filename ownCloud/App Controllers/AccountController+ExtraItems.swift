//
//  AccountController+ExtraItems.swift
//  ownCloud
//
//  Created by Felix Schwarz on 23.11.22.
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
import ownCloudAppShared

extension AccountController: ownCloudAppShared.AccountControllerExtraItems {
	var activitySideBarItem: CollectionSidebarAction? {
		var sideBarItem: CollectionSidebarAction? = specialItems[.activity] as? CollectionSidebarAction

		if sideBarItem == nil {
			sideBarItem = CollectionSidebarAction(with: OCLocalizedString("Status", nil), icon: OCSymbol.icon(forSymbolName: "bolt"), viewControllerProvider: { [weak self] (context, action) in
				if let context {
					return self?.provideExtraItemViewController(for: .activity, in: context)
				}
				return nil
			})
			sideBarItem?.identifier = specialItemsDataReferences[.activity] as? String

			let messageCountObservation = connection?.observe(\.messageCount, options: .initial, changeHandler: { [weak sideBarItem] connection, change in
				let messageCount = connection.messageCount

				OnMainThread(inline: true) { [weak self, weak sideBarItem] in
					sideBarItem?.badgeCount = (messageCount == 0) ? nil : messageCount
					if let sideBarItemReference = sideBarItem?.dataItemReference {
						self?.extraItemsDataSource.signalUpdates(forItemReferences: Set([sideBarItemReference]))
					}
				}
			})

			sideBarItem?.properties[OCActionPropertyKey(rawValue: "messageCountObservation")] = messageCountObservation

			specialItems[.activity] = sideBarItem
		}

		return sideBarItem
	}

	public func updateExtraItems(dataSource: OCDataSourceArray) {
		if let activitySideBarItem = activitySideBarItem, configuration.showActivity {
			dataSource.setVersionedItems([ activitySideBarItem ])
		}
	}

	public func provideExtraItemViewController(for specialItem: SpecialItem, in context: ClientContext) -> UIViewController? {
		switch specialItem {
			case .activity:
				let activityViewController = ClientActivityViewController(connection: context.accountConnection, clientContext: context)
				activityViewController.revoke(in: context, when: [ .connectionClosed ])
				activityViewController.navigationBookmark = BrowserNavigationBookmark(type: .specialItem, bookmarkUUID: context.accountConnection?.bookmark.uuid, specialItem: .activity)
				return activityViewController

			default:
				return nil
		}
	}
}
