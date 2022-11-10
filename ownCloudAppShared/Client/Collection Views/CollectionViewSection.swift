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
		case list(appearance: UICollectionLayoutListConfiguration.Appearance, headerMode: UICollectionLayoutListConfiguration.HeaderMode? = nil, headerTopPadding : CGFloat? = nil, footerMode: UICollectionLayoutListConfiguration.FooterMode? = nil, contentInsets: NSDirectionalEdgeInsets? = nil)
		case fullWidth(itemHeightDimension: NSCollectionLayoutDimension, groupHeightDimension: NSCollectionLayoutDimension, edgeSpacing: NSCollectionLayoutEdgeSpacing? = nil, contentInsets: NSDirectionalEdgeInsets? = nil)
		case sideways(item: NSCollectionLayoutItem? = nil, groupSize: NSCollectionLayoutSize? = nil, innerInsets : NSDirectionalEdgeInsets? = nil, edgeSpacing: NSCollectionLayoutEdgeSpacing? = nil, contentInsets: NSDirectionalEdgeInsets? = nil, orthogonalScrollingBehaviour: UICollectionLayoutSectionOrthogonalScrollingBehavior = .continuousGroupLeadingBoundary)
		case custom(generator: ((_ collectionViewController: CollectionViewController?, _ layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection))

		func collectionLayoutSection(for collectionViewController: CollectionViewController? = nil, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
			switch self {
				// List
				case .list(let listAppearance, let headerMode, let headerTopPadding, let footerMode, let contentInsets):
					var config = UICollectionLayoutListConfiguration(appearance: listAppearance)

					// Appearance
					if let headerMode = headerMode {
						config.headerMode = headerMode
					}
					if let headerTopPadding = headerTopPadding {
						config.headerTopPadding = headerTopPadding
					}
					if let footerMode = footerMode {
						config.footerMode = footerMode
					}

					switch listAppearance {
						case .plain:
							config.backgroundColor = Theme.shared.activeCollection.tableBackgroundColor

						case .grouped, .insetGrouped:
							config.backgroundColor = Theme.shared.activeCollection.tableGroupBackgroundColor

						default: break
					}

					// Leading and trailing swipe actions
					if let collectionViewController = collectionViewController {
						let clientContext = ClientContext(with: collectionViewController.clientContext, modifier: { context in
							context.originatingViewController = collectionViewController
						})

						config.leadingSwipeActionsConfigurationProvider = { [weak collectionViewController] (_ indexPath: IndexPath) in
							var swipeConfiguration : UISwipeActionsConfiguration?

							collectionViewController?.retrieveItem(at: indexPath, synchronous: true, action: { record, indexPath in
								// Return early if leadingSwipes are not allowed
								if !clientContext.validate(interaction: .leadingSwipe, for: record) {
									return
								}

								// Use context's swipeActionsProvider
								if let item = record.item,
								   let collectionViewController = collectionViewController,
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

						config.trailingSwipeActionsConfigurationProvider = { [weak collectionViewController] (_ indexPath: IndexPath) in
							var swipeConfiguration : UISwipeActionsConfiguration?

							collectionViewController?.retrieveItem(at: indexPath, synchronous: true, action: { record, indexPath in
								// Return early if trailingSwipes are not allowed
								if !clientContext.validate(interaction: .trailingSwipe, for: record) {
									return
								}

								// Use context's swipeActionsProvider
								if let item = record.item,
								   let collectionViewController = collectionViewController,
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

					let layoutSection = NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
					if let contentInsets = contentInsets {
						layoutSection.contentInsets = contentInsets
					}
					return layoutSection

				// Full width
				case .fullWidth(let itemHeightDimension, let groupHeightDimension, let edgeSpacing, let contentInsets):
					let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: itemHeightDimension))
					if let edgeSpacing = edgeSpacing {
						item.edgeSpacing = edgeSpacing
					}

					let group = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: groupHeightDimension), subitems: [ item ])

					let layoutSection =  NSCollectionLayoutSection(group: group)
					if let contentInsets = contentInsets {
						layoutSection.contentInsets = contentInsets
					}
					return layoutSection

				case .sideways(let item, let groupSize, let innerInsets, let edgeSpacing, let contentInsets, let orthogonalScrollingBehaviour):
					let useItem = item ?? NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
					if let edgeSpacing = edgeSpacing {
						useItem.edgeSpacing = edgeSpacing
					}

					let layoutGroupSize = groupSize ?? NSCollectionLayoutSize(widthDimension: .absolute(64), heightDimension: .absolute(64))
					let group = NSCollectionLayoutGroup.horizontal(layoutSize: layoutGroupSize, subitems: [useItem])
					if let innerInsets = innerInsets {
						group.contentInsets = innerInsets
					}

					let layoutSection = NSCollectionLayoutSection(group: group)
					layoutSection.orthogonalScrollingBehavior = orthogonalScrollingBehaviour
					if let contentInsets = contentInsets {
						layoutSection.contentInsets = contentInsets
					}
					return layoutSection

				// Custom
				case .custom(let generator):
					return generator(collectionViewController, layoutEnvironment)
			}
		}
	}

	public typealias SectionIdentifier = String
	public typealias CellConfigurationCustomizer = (_ collectionView: UICollectionView, _ cellConfiguration: CollectionViewCellConfiguration, _ itemRecord: OCDataItemRecord, _ collectionItemRef: CollectionViewController.ItemRef, _ indexPath: IndexPath) -> Void

	public var identifier: SectionIdentifier

	public var contentDataSource: OCDataSource? {
		return combinedChildrenDataSource ?? dataSource
	}

	public var dataSource: OCDataSource? {
		willSet {
			dataSourceSubscription?.terminate()
			dataSourceSubscription = nil

			if let dataSource = dataSource {
				combinedChildrenDataSource?.removeSources([dataSource])
			}
		}

		didSet {
			if let dataSource = dataSource {
				combinedChildrenDataSource?.addSources([dataSource])
			}
			updateDatasourceSubscription()
		}
	}
	public var dataSourceSubscription : OCDataSourceSubscription?

	weak public var collectionViewController : CollectionViewController?

	private var _cellStyle : CollectionViewCellStyle
	public var cellStyle : CollectionViewCellStyle { //!< Use .cellConfigurationCustomizer for per-cell styling
		get {
			return _cellStyle
		}
		set {
			_cellStyle = newValue

			if _cellStyle != newValue {
				OnMainThread {
					self.collectionViewController?.reload(sections: [self], animated: false)
				}
			}
		}
	}
	public var clientContext: ClientContext?
	public var cellConfigurationCustomizer : CellConfigurationCustomizer?

	public var animateDifferences: Bool? //!< If not specified, falls back to collectionViewController.animateDifferences
	public var hidden : Bool = false

	private var _hideIfEmptyDataSourceSubscription: OCDataSourceSubscription?
	public var hideIfEmptyDataSource: OCDataSource? {
		willSet {
			_hideIfEmptyDataSourceSubscription = nil
		}
		didSet {
			_hideIfEmptyDataSourceSubscription = hideIfEmptyDataSource?.subscribe(updateHandler: { [weak self] subscription in
				let snapshot = subscription.snapshotResettingChangeTracking(true)

				OnMainThread { [weak self] in
					self?.hidden = snapshot.numberOfItems > 0
				}
			}, on: .main, trackDifferences: false, performIntialUpdate: true)
		}
	}

	public var cellLayout: CellLayout

	public init(identifier: SectionIdentifier, dataSource inDataSource: OCDataSource?, cellStyle : CollectionViewCellStyle = .init(with:.tableCell), cellLayout: CellLayout = .list(appearance: .plain), clientContext: ClientContext? = nil ) {
		self.identifier = identifier
		_cellStyle = cellStyle
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
		collectionViewController?.updateSource(animatingDifferences: animateDifferences ?? (collectionViewController?.animateDifferences ?? true))
	}

	// MARK: - Item provider
	func populate(snapshot: inout NSDiffableDataSourceSnapshot<CollectionViewSection.SectionIdentifier, CollectionViewController.ItemRef>) {
		if let datasourceSnapshot = dataSourceSubscription?.snapshotResettingChangeTracking(true) {
			if let collectionViewController = collectionViewController, let highlightItemReference = collectionViewController.highlightItemReference, collectionViewController.didHighlightItemReference == false {
				if datasourceSnapshot.items.contains(highlightItemReference) {
					collectionViewController.didHighlightItemReference = true

					OnMainThread(after: 0.1) {
						collectionViewController.highlight(itemRef: highlightItemReference, animated: true)
					}
				}
			}

			if let wrappedItems = collectionViewController?.wrap(references: datasourceSnapshot.items, forSection: identifier) {
				snapshot.appendItems(wrappedItems, toSection: identifier)
			}

			if let updatedItems = datasourceSnapshot.updatedItems, updatedItems.count > 0,
			   let wrappedUpdatedItems = collectionViewController?.wrap(references: Array(updatedItems), forSection: identifier) {
				snapshot.reconfigureItems(wrappedUpdatedItems)
			}
		}
	}

	func composeSectionSnapshot(from existingSnapshot: NSDiffableDataSourceSectionSnapshot<CollectionViewController.ItemRef>) -> (NSDiffableDataSourceSectionSnapshot<CollectionViewController.ItemRef>, [CollectionViewController.ItemRef]?) {
		var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<CollectionViewController.ItemRef>()
		var wrappedUpdatedItems : [CollectionViewController.ItemRef]?

		if let datasourceSnapshot = dataSourceSubscription?.snapshotResettingChangeTracking(true) {
			if let collectionViewController = collectionViewController, let highlightItemReference = collectionViewController.highlightItemReference, collectionViewController.didHighlightItemReference == false {
				if datasourceSnapshot.items.contains(highlightItemReference) {
					collectionViewController.didHighlightItemReference = true

					OnMainThread(after: 0.1) {
						collectionViewController.highlight(itemRef: highlightItemReference, animated: true)
					}
				}
			}

			if let wrappedItems = collectionViewController?.wrap(references: datasourceSnapshot.items, forSection: identifier) {
				sectionSnapshot.append(wrappedItems)

				for wrappedItem in wrappedItems {
					if existingSnapshot.contains(wrappedItem) {
						if existingSnapshot.isExpanded(wrappedItem) {
							sectionSnapshot.expand([wrappedItem])
						}
					}
				}
			}

			if let updatedItems = datasourceSnapshot.updatedItems, updatedItems.count > 0 {
				wrappedUpdatedItems = collectionViewController?.wrap(references: Array(updatedItems), forSection: identifier)
			}
		}

		return (sectionSnapshot, wrappedUpdatedItems)
	}

	// MARK: - Cell provider
	func provideReusableCell(for collectionView: UICollectionView, collectionItemRef: CollectionViewController.ItemRef, indexPath: IndexPath) -> UICollectionViewCell {
		var cell: UICollectionViewCell?

		if let collectionViewController = collectionViewController {
			let (dataItemRef, _) = collectionViewController.unwrap(collectionItemRef)

			var itemRecord = try? contentDataSource?.record(forItemRef: dataItemRef)

			// if itemRecord == nil, collectionViewController.supportsHierarchicContent == true {
			// 	itemRecord = try? combinedChildrenDataSource?.record(forItemRef: dataItemRef)
			// }

			if let itemRecord = itemRecord {
				var cellProvider = CollectionViewCellProvider.providerFor(itemRecord)

				if cellProvider == nil {
					cellProvider = CollectionViewCellProvider.providerFor(.presentable)
				}

				let doHighlight = collectionViewController.highlightItemReference == dataItemRef

				if let cellProvider = cellProvider, let dataSource = contentDataSource {
					let cellConfiguration = CollectionViewCellConfiguration(source: dataSource, core: collectionViewController.clientContext?.core, collectionItemRef: collectionItemRef, record: itemRecord, hostViewController: collectionViewController, style: cellStyle, highlight: doHighlight, clientContext: clientContext)

					if let cellConfigurationCustomizer = cellConfigurationCustomizer {
						cellConfigurationCustomizer(collectionView, cellConfiguration, itemRecord, collectionItemRef, indexPath)
					}

					cell = cellProvider.provideCell(for: collectionView, cellConfiguration: cellConfiguration, itemRecord: itemRecord, collectionItemRef: collectionItemRef, indexPath: indexPath)
				}
			}

			if cell == nil {
				cell = collectionViewController.provideEmptyFallbackCell(for: indexPath, item: collectionItemRef)
			}
		}

		return cell ?? UICollectionViewCell.emptyFallbackCell
	}

	// MARK: - Hierarchic content provider and child data source tracking
	public var combinedChildrenDataSource : OCDataSourceComposition?
	private var dataSourcesByParentItemRef : [OCDataItemReference : OCDataSource] = [:]
	private var dataSourceSubscriptionsByParentItemRef : [OCDataItemReference : OCDataSourceSubscription] = [:]

	func provideHierarchicContent(for collectionView: UICollectionView, parentItemRef: CollectionViewController.ItemRef, existingSectionSnapshot: NSDiffableDataSourceSectionSnapshot<CollectionViewController.ItemRef>?) -> NSDiffableDataSourceSectionSnapshot<CollectionViewController.ItemRef> {

		if let collectionViewController = collectionViewController, let dataSource = contentDataSource {
			let (parentDataItemRef, _) = collectionViewController.unwrap(parentItemRef)

			if let itemRecord = try? dataSource.record(forItemRef: parentDataItemRef) {
				if itemRecord.hasChildren {
					var childrenDataSource : OCDataSource? = dataSourcesByParentItemRef[parentDataItemRef]
					var childrenDataSourceSubscription : OCDataSourceSubscription?

					if childrenDataSource == nil {
						childrenDataSource = itemRecord.item?.dataSourceForChildren?(using: dataSource)

						if let childrenDataSource = childrenDataSource {
							let subscription = childrenDataSource.subscribe(updateHandler: { [weak self, weak collectionViewController] subscription in
								// Handle updates
								if let self = self, let collectionViewController = collectionViewController {
									// Determine updated items
									let dataSourceSnapshot = subscription.snapshotResettingChangeTracking(true)
									let updatedItems = dataSourceSnapshot.updatedItems
									let removedItems: Set<OCDataItemReference>? = dataSourceSnapshot.removedItems

									// Insert added items without replacing
									if let addedItems = dataSourceSnapshot.addedItems, addedItems.count > 0 {
										let allItems = dataSourceSnapshot.items
										var itemsToAdd = Set(addedItems)

										var sectionSnapshot = collectionViewController.collectionViewDataSource.snapshot(for: self.identifier)

										while itemsToAdd.count > 0 {
											let lastItemsToAddCount = itemsToAdd.count

											for itemToAdd in addedItems {
												if itemsToAdd.contains(itemToAdd) {
													if let idx = allItems.firstIndex(of: itemToAdd) {
														if let wrappedItemToAdd = collectionViewController.wrap(references: [ itemToAdd ], forSection: self.identifier).first {
															if idx == 0 {
																// Item at position 0
																if allItems.count > 1 {
																	// Try to insert item before the item that comes after it
																	if let wrappedItemAfter = collectionViewController.wrap(references: [allItems[1]], forSection: self.identifier).first, sectionSnapshot.contains(wrappedItemAfter) {
																		sectionSnapshot.insert([ wrappedItemToAdd ], before: wrappedItemAfter)
																		itemsToAdd.remove(itemToAdd)
																	}
																} else {
																	// Only one item. Append as subitem of parent item.
																	sectionSnapshot.append([wrappedItemToAdd], to: parentItemRef)
																	itemsToAdd.remove(itemToAdd)
																}
															} else {
																// Item not at position 0
																// Try to insert item after the item before it
																if let wrappedItemBefore = collectionViewController.wrap(references: [allItems[idx-1]], forSection: self.identifier).first,
																	   sectionSnapshot.contains(wrappedItemBefore) {
																	sectionSnapshot.insert([ wrappedItemToAdd ], after: wrappedItemBefore)
																	itemsToAdd.remove(itemToAdd)
																}
															}
														} else {
															// itemToAdd can't be wrapped
															Log.error("itemToAdd \(itemToAdd) can't be wrapped. This should never happen.")
															itemsToAdd.remove(itemToAdd) // avoid infinite loop
														}
													} else {
														// itemToAdd is not part of allItems (?!)
														Log.error("itemToAdd \(itemToAdd) not part of datasource, not adding. This should never happen.")
														itemsToAdd.remove(itemToAdd) // avoid infinite loop
													}
												}
											}

											if lastItemsToAddCount == itemsToAdd.count {
												// Couldn't insert any item, quit loop
												Log.warning("Could not insert items \(itemsToAdd). Quitting loop without inserting.")
											}
										}

										collectionViewController.collectionViewDataSource.apply(sectionSnapshot, to: self.identifier)

										/*
										// Replace section content if new items were added

										// Compile replacement content
										let replacementContent = self.provideHierarchicContent(for: collectionView, parentItemRef: parentItemRef, existingSectionSnapshot: nil)

										// Retrieve section snapshot and use replacementContent to replace the item's child items
										var sectionSnapshot = collectionViewController.collectionViewDataSource.snapshot(for: self.identifier)
										sectionSnapshot.replace(childrenOf: parentItemRef, using: replacementContent)

										// Apply replacementContent change
										collectionViewController.collectionViewDataSource.apply(sectionSnapshot, to: self.identifier)

										// removedItems already "applied", if any
										removedItems = nil
										*/
									}

									// Compile data source snapshot to notify collection view of updated items
									if updatedItems != nil || removedItems != nil {
										// Get snapshot of complete source
										var snapshot = collectionViewController.collectionViewDataSource.snapshot()

										// Tell snapshot that updatedItems were reconfigured
										if let updatedItems = updatedItems {
											let wrappedUpdatedItems = collectionViewController.wrap(references: Array(updatedItems), forSection: self.identifier)
											snapshot.reconfigureItems(wrappedUpdatedItems)
										}

										// Tell snapshot that removedItems were removed
										if let removedItems = removedItems {
											let wrappedRemovedItems = collectionViewController.wrap(references: Array(removedItems), forSection: self.identifier)
											snapshot.deleteItems(wrappedRemovedItems)
										}

										// Apply changes and animate them
										collectionViewController.collectionViewDataSource.apply(snapshot, animatingDifferences: true)
									}
								}
							}, on: .main, trackDifferences: true, performIntialUpdate: false)

							childrenDataSourceSubscription = subscription

							dataSourcesByParentItemRef[parentDataItemRef] = childrenDataSource
							dataSourceSubscriptionsByParentItemRef[parentDataItemRef] = childrenDataSourceSubscription
							if combinedChildrenDataSource == nil, let rootDataSource = self.dataSource {
								combinedChildrenDataSource = OCDataSourceComposition(sources: [rootDataSource, childrenDataSource])
							} else {
								combinedChildrenDataSource?.addSources([childrenDataSource])
							}
						}
					} else {
						childrenDataSourceSubscription = dataSourceSubscriptionsByParentItemRef[parentDataItemRef]
					}

					if let childrenDataSourceSubscription = childrenDataSourceSubscription {
						let childrenDataSourceSnapshot = childrenDataSourceSubscription.snapshotResettingChangeTracking(true)

						var childSnapshot = NSDiffableDataSourceSectionSnapshot<OCDataItemReference>()

						let wrappedItems = collectionViewController.wrap(references: childrenDataSourceSnapshot.items, forSection: identifier)
						childSnapshot.append(wrappedItems)

						return childSnapshot
					}
				}
			}
		}

		return existingSectionSnapshot ?? NSDiffableDataSourceSectionSnapshot()
	}

	// MARK: - Section layout
	open func provideCollectionLayoutSection(layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
		return cellLayout.collectionLayoutSection(for: self.collectionViewController, layoutEnvironment: layoutEnvironment)
	}
}
