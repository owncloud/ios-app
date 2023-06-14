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
		// Register cell providers
		DriveListCell.registerCellProvider()		// Cell providers for .drive
		ExpandableResourceCell.registerCellProvider()	// Cell providers for .textResource
		ActionCell.registerCellProvider()		// Cell providers for .action
		AccountControllerCell.registerCellProvider()	// Cell providers for .accountController
		SavedSearchCell.registerCellProvider()		// Cell providers for .savedSearch
		ViewCell.registerCellProvider()			// Cell providers for .view

		// Register UniversalItemListCell based cell providers
		OCItem.registerUniversalCellProvider()		// Cell providers for .item
		OCShare.registerUniversalCellProvider()		// Cell providers for .share
		OCShareRole.registerUniversalCellProvider()	// Cell providers for .shareRole
		OCItemPolicy.registerUniversalCellProvider()	// Cell providers for .itemPolicy
		OCIdentity.registerUniversalCellProvider()	// Cell providers for .identity
		OptionItem.registerUniversalCellProvider()	// Cell providers for .optionItem

		// Register cell providers for .presentable
		registerPresentableCellProvider()
	}

	static func registerPresentableCellProvider() {
		let presentableCellRegistration = UICollectionView.CellRegistration<ThemeableCollectionViewListCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			var content = cell.defaultContentConfiguration()
			var hasDisclosureIndicator : Bool = false

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

							let coverImageRequest = try? presentable.provideResourceRequest(.coverImage, withOptions: nil)
							let readmeRequest = try? presentable.provideResourceRequest(.coverDescription, withOptions: nil)

							coverImageRequest?.changeHandler = { (request, error, isOngoing, previousResource, newResource) in
								Log.debug("REQ_Cover image request: \(String(describing: request)) | error: \(String(describing: error)) | isOngoing: \(isOngoing) | newResource: \(String(describing: newResource))")
								if let imageResource = newResource as? OCResourceImage {
									imageResource.image?.request(completionHandler: { ocImage, error, image in
										Log.debug("REQ_Cover image: \(String(describing: image))")
									})
								}
							}

							readmeRequest?.changeHandler = { (request, error, isOngoing, previousResource, newResource) in
								Log.debug("REQ_Readme request: \(String(describing: request)) | error: \(String(describing: error)) | isOngoing: \(isOngoing) | newResource: \(String(describing: newResource))")
								if let textResource = newResource as? OCResourceText {
									Log.debug("REQ_Readme text: \(String(describing: textResource.text))")
								}
							}

							if let coverImageRequest = coverImageRequest {
								cellConfiguration.core?.vault.resourceManager?.start(coverImageRequest)
							}

							if let readmeRequest = readmeRequest {
								cellConfiguration.core?.vault.resourceManager?.start(readmeRequest)
							}

							if let datasource = cellConfiguration.source {
								hasDisclosureIndicator = presentable.hasChildren(using: datasource)
							}
						}
					} else {
						// Request reconfiguration of cell
						itemRecord.retrieveItem(completionHandler: { error, itemRecord in
							if let collectionViewController = cellConfiguration.hostViewController {
								collectionViewController.performDataSourceUpdate(with: { updateDone in
									collectionViewController.collectionViewDataSource.requestReconfigurationOfItems([collectionItemRef])
									updateDone()
								})
							}
						})
					}
				}
			}

			cell.contentConfiguration = content
			cell.applyThemeCollection(theme: Theme.shared, collection: Theme.shared.activeCollection, event: .initial)
			cell.accessories = hasDisclosureIndicator ? [ .disclosureIndicator() ] : [ ]
		}

		let presentableSidebarCellRegistration = UICollectionView.CellRegistration<ThemeableCollectionViewListCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			var title: String?
			var image: UIImage?
			var hasChildren: Bool = false

			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let presentable = OCDataRenderer.default.renderItem(item, asType: .presentable, error: nil, withOptions: nil) as? OCDataItemPresentable {
					title = presentable.title
					image = presentable.image
					if let source = cellConfiguration.source {
						hasChildren = presentable.hasChildren(using: source)
					}
				}
			})

			var content = cell.defaultContentConfiguration()

			content.text = title
			if let image = image {
				content.image = image
			}

			cell.backgroundConfiguration = .listSidebarCell()
			cell.contentConfiguration = content
			cell.applyThemeCollection(theme: Theme.shared, collection: Theme.shared.activeCollection, event: .initial)

			if hasChildren {
				let headerDisclosureOption = UICellAccessory.OutlineDisclosureOptions(style: .header)
				// let hostViewController = collectionItemRef.ocCellConfiguration?.hostViewController

				cell.accessories = [.outlineDisclosure(options: headerDisclosureOption)] /* , actionHandler: { [weak hostViewController] in
					hostViewController?.expandCollapse(collectionItemRef)
				})]*/
			} else {
				cell.accessories = []
			}
		}

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .presentable, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			switch cellConfiguration?.style.type {
				case .sideBar:
					return collectionView.dequeueConfiguredReusableCell(using: presentableSidebarCellRegistration, for: indexPath, item: itemRef)

				default:
					return collectionView.dequeueConfiguredReusableCell(using: presentableCellRegistration, for: indexPath, item: itemRef)
			}
		}))

		// This registration performs conversion to .presentable where necessary, so it can also be used for other types OCDataItemTypes. Example:
		// CollectionViewCellProvider.register(CollectionViewCellProvider(for: .item, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
		// 	return collectionView.dequeueConfiguredReusableCell(using: presentableCellRegistration, for: indexPath, item: itemRef)
		// }))
	}
}
