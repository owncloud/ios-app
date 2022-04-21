//
//  ClientItemViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 14.04.22.
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

public class ClientItemViewController: CollectionViewController {

	public weak var drive: OCDrive?
	public var query: OCQuery?

	public var queryItemDataSourceSection : CollectionViewSection?

	public var driveSection : CollectionViewSection?

	public var driveSectionDataSource : OCDataSourceComposition?
	public var singleDriveDatasource : OCDataSourceComposition?
	private var singleDriveDatasourceSubscription : OCDataSourceSubscription?
	public var driveAdditionalItemsDataSource : OCDataSourceArray = OCDataSourceArray()

	public init(core inCore: OCCore, drive inDrive: OCDrive?, query inQuery: OCQuery, reveal inItem: OCItem? = nil, rootViewController: UIViewController?) {
		drive = inDrive
		query = inQuery

		var sections : [ CollectionViewSection ] = []

		if let queryDatasource = query?.queryResultsDataSource {
			singleDriveDatasource = OCDataSourceComposition(sources: [inCore.drivesDataSource])

			if query?.queryLocation?.isRoot == true {
				// Create data source from one drive
				singleDriveDatasource?.filter = OCDataSourceComposition.itemFilter(withItemRetrieval: false, fromRecordFilter: { itemRecord in
					if let drive = itemRecord?.item as? OCDrive {
						if drive.identifier == inDrive?.identifier {
							return true
						}
					}

					return false
				})

				// Create combined data source from drive + additional items
				driveSectionDataSource = OCDataSourceComposition(sources: [ singleDriveDatasource!, driveAdditionalItemsDataSource ])

				// Create drive section from combined data source
				driveSection = CollectionViewSection(identifier: "drive", dataSource: driveSectionDataSource, cellStyle: .header)
			}

			queryItemDataSourceSection = CollectionViewSection(identifier: "items", dataSource: queryDatasource)

			if let driveSection = driveSection {
				sections.append(driveSection)
			}

			if let queryItemDataSourceSection = queryItemDataSourceSection {
				sections.append(queryItemDataSourceSection)
			}
		}

		super.init(core: inCore, rootViewController: rootViewController, sections: sections, listAppearance: .plain)

		// Subscribe to singleDriveDatasource for changes, to update driveSectionDataSource
		singleDriveDatasourceSubscription = singleDriveDatasource?.subscribe(updateHandler: { [weak self] subscription in
			self?.updateAdditionalDriveItems(from: subscription)
		}, on: .main, trackDifferences: true, performIntialUpdate: true)

		query?.sortComparator = SortMethod.alphabetically.comparator(direction: .ascendant)

		if let navigationTitle = query?.queryLocation?.isRoot == true ? drive?.name : query?.queryLocation?.lastPathComponent {
			navigationItem.title = navigationTitle
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		singleDriveDatasourceSubscription?.terminate()
	}

	public override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if let query = query {
			core?.start(query)
		}
	}

	open override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		if let query = query {
			core?.stop(query)
		}
	}

	public override func handleSelection(of record: OCDataItemRecord, at indexPath: IndexPath) -> Bool {
		if let core = self.core, let rootViewController = self.rootViewController {
			if let item = record.item as? OCItem, let location = item.location {
				let query = OCQuery(for: location)
				let rootFolderViewController = ClientItemViewController(core: core, drive: drive, query: query, rootViewController: rootViewController)

				collectionView.deselectItem(at: indexPath, animated: true)

				self.navigationController?.pushViewController(rootFolderViewController, animated: true)

				return true
			}
		}

		return super.handleSelection(of: record, at: indexPath)
	}

	public func updateAdditionalDriveItems(from subscription: OCDataSourceSubscription) {
		let snapshot = subscription.snapshotResettingChangeTracking(true)

		if let firstItemRef = snapshot.items.first,
	  	   let itemRecord = try? subscription.source?.record(forItemRef: firstItemRef),
		   let drive = itemRecord?.item as? OCDrive,
		   let driveRepresentation = OCDataRenderer.default.renderItem(drive, asType: .presentable, error: nil) as? OCDataItemPresentable,
		   let descriptionResourceRequest = try? driveRepresentation.provideResourceRequest(.coverDescription) {
			descriptionResourceRequest.lifetime = .singleRun
			descriptionResourceRequest.changeHandler = { [weak self] (request, error, isOngoing, previousResource, newResource) in
				// Log.debug("REQ_Readme request: \(String(describing: request)) | error: \(String(describing: error)) | isOngoing: \(isOngoing) | newResource: \(String(describing: newResource))")
				if let textResource = newResource as? OCResourceText {
					self?.driveAdditionalItemsDataSource.setItems([textResource], updated: [textResource])
				}
			}

			core?.vault.resourceManager?.start(descriptionResourceRequest)
		}
	}
}

extension ClientItemViewController: ItemListCellDelegate {
	public func moreButtonTapped(cell: ItemListCell) {

	}

	public func messageButtonTapped(cell: ItemListCell) {

	}

	public func revealButtonTapped(cell: ItemListCell) {

	}

	public func hasMessage(for item: OCItem) -> Bool {
		return false
	}
}
