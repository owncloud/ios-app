//
//  CollectionViewSection.swift
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

public class CollectionViewSection: NSObject {
	public typealias SectionIdentifier = String
	public typealias CellConfigurationCustomizer = (_ collectionView: UICollectionView, _ cellConfiguration: CollectionViewCellConfiguration, _ itemRecord: OCDataItemRecord, _ collectionItemRef: CollectionViewController.ItemRef, _ indexPath: IndexPath) -> Void

	public var identifier: SectionIdentifier

	public var dataSource: OCDataSource? {
		willSet {
			dataSourceSubscription?.terminate()
			dataSourceSubscription = nil
		}

		didSet {
			updateDatasourceSubscription()
		}
	}
	public var dataSourceSubscription : OCDataSourceSubscription?

	weak public var collectionViewController : CollectionViewController?

	public var cellStyle : CollectionViewCellStyle //!< Use .cellConfigurationCustomizer for per-cell styling
	public var clientContext: ClientContext?
	public var cellConfigurationCustomizer : CellConfigurationCustomizer?

	func updateDatasourceSubscription() {
		if let dataSource = dataSource {
			dataSourceSubscription = dataSource.subscribe(updateHandler: { [weak self] (subscription) in
				self?.handleListUpdates(from: subscription)
			}, on: .main, trackDifferences: true, performIntialUpdate: true)
		}
	}

	public init(identifier: SectionIdentifier, dataSource inDataSource: OCDataSource?, cellStyle : CollectionViewCellStyle = .tableCell, clientContext: ClientContext? = nil ) {
		self.identifier = identifier
		self.cellStyle = cellStyle

		super.init()

		self.clientContext = clientContext
		self.dataSource = inDataSource
		updateDatasourceSubscription() // dataSource.didSet is not called during initialization
	}

	deinit {
		dataSourceSubscription?.terminate()
	}

	func handleListUpdates(from subscription: OCDataSourceSubscription) {
		collectionViewController?.updateSource(animatingDifferences: true)
	}

	func populate(snapshot: inout NSDiffableDataSourceSnapshot<CollectionViewSection.SectionIdentifier, CollectionViewController.ItemRef>) {
		if let datasourceSnapshot = dataSourceSubscription?.snapshotResettingChangeTracking(true) {
			if let wrappedItems = collectionViewController?.wrap(references: datasourceSnapshot.items, forSection: identifier) {
				snapshot.appendItems(wrappedItems, toSection: identifier)
			}

			if let updatedItems = datasourceSnapshot.updatedItems, updatedItems.count > 0,
			   let wrappedUpdatedItems = collectionViewController?.wrap(references: Array(updatedItems), forSection: identifier) {
				snapshot.reloadItems(wrappedUpdatedItems)
			}
		}
	}

	func provideReusableCell(for collectionView: UICollectionView, collectionItemRef: CollectionViewController.ItemRef, indexPath: IndexPath) -> UICollectionViewCell {
		var cell: UICollectionViewCell?

		if let (dataItemRef, _) = collectionViewController?.unwrap(collectionItemRef) {
			if let itemRecord = try? dataSource?.record(forItemRef: dataItemRef), let itemRecord = itemRecord {
				var cellProvider = CollectionViewCellProvider.providerFor(itemRecord)

				if cellProvider == nil {
					cellProvider = CollectionViewCellProvider.providerFor(.presentable)
				}

				if let cellProvider = cellProvider, let dataSource = dataSource {
					let cellConfiguration = CollectionViewCellConfiguration(source: dataSource, core: collectionViewController?.clientContext?.core, collectionItemRef: collectionItemRef, record: itemRecord, hostViewController: collectionViewController, style: cellStyle, clientContext: clientContext)

					if let cellConfigurationCustomizer = cellConfigurationCustomizer {
						cellConfigurationCustomizer(collectionView, cellConfiguration, itemRecord, collectionItemRef, indexPath)
					}

					cell = cellProvider.provideCell(for: collectionView, cellConfiguration: cellConfiguration, itemRecord: itemRecord, collectionItemRef: collectionItemRef, indexPath: indexPath)
				}
			}
		}

		return cell ?? UICollectionViewCell()
	}
}
