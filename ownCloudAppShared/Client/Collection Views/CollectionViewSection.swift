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
	public enum CellLayout {
		case list(appearance: UICollectionLayoutListConfiguration.Appearance)
		case fullWidth(heightDimension: NSCollectionLayoutDimension, interItemSpacing: NSCollectionLayoutSpacing? = nil, contentInsets: NSDirectionalEdgeInsets = .zero)

		func collectionLayoutSection(for collectionViewController: CollectionViewController? = nil, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
			switch self {
				// List
				case .list(let listAppearance):
					var config = UICollectionLayoutListConfiguration(appearance: listAppearance)

					// Appearance
					switch listAppearance {
						case .plain:
							config.headerMode = .firstItemInSection
							config.headerTopPadding = 0
							config.backgroundColor = Theme.shared.activeCollection.tableBackgroundColor

						case .grouped, .insetGrouped:
							config.backgroundColor = Theme.shared.activeCollection.tableGroupBackgroundColor

						default: break
					}

//					config.headerTopPadding = 0
//					config.headerMode = .none
//					config.footerMode = .none

					// Leading and trailing swipe actions
					if let collectionViewController = collectionViewController {
						let clientContext = ClientContext(with: collectionViewController.clientContext, modifier: { context in
							context.originatingViewController = collectionViewController
						})

						config.leadingSwipeActionsConfigurationProvider = { (_ indexPath: IndexPath) in
							var swipeConfiguration : UISwipeActionsConfiguration?

							collectionViewController.retrieveItem(at: indexPath, synchronous: true, action: { record, indexPath in
								// Return early if leadingSwipes are not allowed
								if !clientContext.validate(permission: .leadingSwipe, for: record) {
									return
								}

								// Use context's swipeActionsProvider
								if let item = record.item,
								   let swipeActionsProvider = clientContext.swipeActionsProvider,
								   (swipeActionsProvider as? NSObject)?.responds(to: #selector(SwipeActionsProvider.provideLeadingSwipeActions(for:item:context:))) == true {
									swipeConfiguration = swipeActionsProvider.provideLeadingSwipeActions?(for: collectionViewController, item: item, context: clientContext)
								}

								// Use item's DataItemSwipeInteraction
								if swipeConfiguration == nil,
								   let dataItem = record.item as? DataItemSwipeInteraction,
								   dataItem.responds(to: #selector(DataItemSwipeInteraction.provideLeadingSwipeActions(with:))) {
									swipeConfiguration = dataItem.provideLeadingSwipeActions?(with: clientContext)
								}
							})

							return swipeConfiguration
						}

						config.trailingSwipeActionsConfigurationProvider = { (_ indexPath: IndexPath) in
							var swipeConfiguration : UISwipeActionsConfiguration?

							collectionViewController.retrieveItem(at: indexPath, synchronous: true, action: { record, indexPath in
								// Return early if trailingSwipes are not allowed
								if !clientContext.validate(permission: .trailingSwipe, for: record) {
									return
								}

								// Use context's swipeActionsProvider
								if let item = record.item,
								   let swipeActionsProvider = clientContext.swipeActionsProvider,
								   (swipeActionsProvider as? NSObject)?.responds(to: #selector(SwipeActionsProvider.provideTrailingSwipeActions(for:item:context:))) == true {
									swipeConfiguration = swipeActionsProvider.provideTrailingSwipeActions?(for: collectionViewController, item: item, context: clientContext)
								}

								// Use item's DataItemSwipeInteraction
								if swipeConfiguration == nil,
								   let dataItem = record.item as? DataItemSwipeInteraction,
								   dataItem.responds(to: #selector(DataItemSwipeInteraction.provideTrailingSwipeActions(with:))) {
									swipeConfiguration = dataItem.provideTrailingSwipeActions?(with: clientContext)
								}
							})

							return swipeConfiguration
						}
					}

					return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)

				// Full width
				case .fullWidth(let heightDimension, let interItemSpacing, let contentInsets):
					let group = NSCollectionLayoutGroup(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: heightDimension))
					group.interItemSpacing = interItemSpacing
					group.contentInsets = contentInsets
					return NSCollectionLayoutSection(group: group)
			}
		}
	}

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

	public var cellLayout: CellLayout

	public init(identifier: SectionIdentifier, dataSource inDataSource: OCDataSource?, cellStyle : CollectionViewCellStyle = .tableCell, cellLayout: CellLayout = .list(appearance: .plain), clientContext: ClientContext? = nil ) {
		self.identifier = identifier
		self.cellStyle = cellStyle
		self.cellLayout = cellLayout

		super.init()

		self.clientContext = clientContext
		self.dataSource = inDataSource
		updateDatasourceSubscription() // dataSource.didSet is not called during initialization
	}

	deinit {
		dataSourceSubscription?.terminate()
	}

	// MARK: - Data source handling
	func updateDatasourceSubscription() {
		if let dataSource = dataSource {
			dataSourceSubscription = dataSource.subscribe(updateHandler: { [weak self] (subscription) in
				self?.handleListUpdates(from: subscription)
			}, on: .main, trackDifferences: true, performIntialUpdate: true)
		}
	}

	func handleListUpdates(from subscription: OCDataSourceSubscription) {
		collectionViewController?.updateSource(animatingDifferences: true)
	}

	// MARK: - Item provider
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

//	func provideDataItem(for collectionView: UICollectionView, collectionItemRef: CollectionViewController.ItemRef) -> OCDataItem? {
//		var dataItem: OCDataItem?
//
//		if let (dataItemRef, _) = collectionViewController?.unwrap(collectionItemRef) {
//			if let itemRecord = try? dataSource?.record(forItemRef: dataItemRef) {
//				dataItem = itemRecord.item
//			}
//		}
//
//		return dataItem
//	}

	// MARK: - Cell provider
	func provideReusableCell(for collectionView: UICollectionView, collectionItemRef: CollectionViewController.ItemRef, indexPath: IndexPath) -> UICollectionViewCell {
		var cell: UICollectionViewCell?

		if let (dataItemRef, _) = collectionViewController?.unwrap(collectionItemRef) {
			if let itemRecord = try? dataSource?.record(forItemRef: dataItemRef) {
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

	// MARK: - Section layout
	open func provideCollectionLayoutSection(layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
		return cellLayout.collectionLayoutSection(for: self.collectionViewController, layoutEnvironment: layoutEnvironment)
	}
}
