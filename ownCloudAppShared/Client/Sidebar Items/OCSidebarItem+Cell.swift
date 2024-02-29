//
//  OCSidebarItem+Cell.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 28.02.24.
//  Copyright © 2024 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2024, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudApp

extension OCSidebarItem {
	static func registerCellProvider() {
		let sidebarItemSidebarCellRegistration = UICollectionView.CellRegistration<ThemeableCollectionViewListCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			var content = cell.defaultContentConfiguration()

			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let savedSearch = OCDataRenderer.default.renderItem(item, asType: .sidebarItem, error: nil, withOptions: nil) as? OCSidebarItem {
					content.text = savedSearch.location?.displayName(in: cellConfiguration.clientContext)
					content.image = OCSymbol.icon(forSymbolName: "folder")
				}
			})

			cell.backgroundConfiguration = .listSidebarCell()
			cell.contentConfiguration = content
			cell.applyThemeCollection(theme: Theme.shared, collection: Theme.shared.activeCollection, event: .initial)
		}

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .sidebarItem, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			return collectionView.dequeueConfiguredReusableCell(using: sidebarItemSidebarCellRegistration, for: indexPath, item: itemRef)
		}))
	}
}
