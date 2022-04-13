//
//  CollectionViewCellProvider+StandardImplementations.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 08.04.22.
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

public extension CollectionViewCellProvider {
	static func registerStandardImplementations() {
		// Register cell providers for .drive and .presentable
		let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			var content = cell.defaultContentConfiguration()

			if let cellConfiguration = collectionItemRef.ocCellConfiguration {
				var itemRecord = cellConfiguration.record

				if itemRecord == nil {
					if let collectionViewController = cellConfiguration.hostViewController {
						let (itemRef, _) = collectionViewController.unwrap(collectionItemRef)

						if let retrievedItemRecord = try? cellConfiguration.source?.record(forItemRef: itemRef) {
							itemRecord = retrievedItemRecord
						}
					}
				}

				if let itemRecord = itemRecord {
					if let item = itemRecord.item {
						if let presentable = OCDataRenderer.default.renderItem(item, asType: .presentable, error: nil, withOptions: nil) as? OCDataItemPresentable {
							content.text = presentable.title
							content.secondaryText = presentable.subtitle

//							presentable.requestResource(.coverImage, withOptions: [.core : core], completionHandler: { error, resource in
//							})
						}
					} else {
						// Request reconfiguration of cell
						itemRecord.retrieveItem(completionHandler: { error, itemRecord in
							if let collectionViewController = cellConfiguration.hostViewController {
								collectionViewController.collectionViewDataSource.requestReconfigurationOfItems([collectionItemRef])
							}
						})
					}
				}
			}

			cell.contentConfiguration = content
			cell.accessories = [ .disclosureIndicator() ]
		}

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .drive, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemRef)
		}))

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .presentable, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemRef)
		}))
	}
}
