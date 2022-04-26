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
import ownCloudApp

public class ClientItemViewController: CollectionViewController {
	public var query: OCQuery?

	public var queryItemDataSourceSection : CollectionViewSection?

	public var driveSection : CollectionViewSection?

	public var driveSectionDataSource : OCDataSourceComposition?
	public var singleDriveDatasource : OCDataSourceComposition?
	private var singleDriveDatasourceSubscription : OCDataSourceSubscription?
	public var driveAdditionalItemsDataSource : OCDataSourceArray = OCDataSourceArray()

	public init(context inContext: ClientContext?, query inQuery: OCQuery, reveal inItem: OCItem? = nil) {
		query = inQuery

		var sections : [ CollectionViewSection ] = []

		let itemControllerContext = ClientContext(with: inContext)
		itemControllerContext.postInitializationModifier = { (owner, context) in
			if context.openItemHandler == nil {
				context.openItemHandler = owner as? OpenItemAction
			}
			if context.moreItemHandler == nil {
				context.moreItemHandler = owner as? MoreItemAction
			}

			context.query = (owner as? ClientItemViewController)?.query
		}

		if let queryDatasource = query?.queryResultsDataSource, let core = itemControllerContext.core {
			singleDriveDatasource = OCDataSourceComposition(sources: [core.drivesDataSource])

			if query?.queryLocation?.isRoot == true {
				// Create data source from one drive
				singleDriveDatasource?.filter = OCDataSourceComposition.itemFilter(withItemRetrieval: false, fromRecordFilter: { itemRecord in
					if let drive = itemRecord?.item as? OCDrive {
						if drive.identifier == itemControllerContext.drive?.identifier {
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

			queryItemDataSourceSection = CollectionViewSection(identifier: "items", dataSource: queryDatasource, clientContext: itemControllerContext)

			if let driveSection = driveSection {
				sections.append(driveSection)
			}

			if let queryItemDataSourceSection = queryItemDataSourceSection {
				sections.append(queryItemDataSourceSection)
			}
		}

		super.init(context: itemControllerContext, sections: sections, listAppearance: .plain)

		// Subscribe to singleDriveDatasource for changes, to update driveSectionDataSource
		singleDriveDatasourceSubscription = singleDriveDatasource?.subscribe(updateHandler: { [weak self] subscription in
			self?.updateAdditionalDriveItems(from: subscription)
		}, on: .main, trackDifferences: true, performIntialUpdate: true)

		query?.sortComparator = SortMethod.alphabetically.comparator(direction: .ascendant)

		if let navigationTitle = query?.queryLocation?.isRoot == true ? clientContext?.drive?.name : query?.queryLocation?.lastPathComponent {
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
			clientContext?.core?.start(query)
		}
	}

	open override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		if let query = query {
			clientContext?.core?.stop(query)
		}
	}

	public override func handleSelection(of record: OCDataItemRecord, at indexPath: IndexPath) -> Bool {
		if let item = record.item as? OCItem, let location = item.location, let clientContext = clientContext {
			collectionView.deselectItem(at: indexPath, animated: true)

			if let openHandler = clientContext.openItemHandler {
				openHandler.open(item: item, context: clientContext, animated: true, pushViewController: true)
			} else {
				let rootFolderViewController = ClientItemViewController(context: clientContext, query: OCQuery(for: location))
				self.navigationController?.pushViewController(rootFolderViewController, animated: true)
			}

			return true
		}

		if (record.item as? OCDrive) != nil {
			// Do not react to taps on the drive header cells (=> or show image in the future)
			return false
		}

		return super.handleSelection(of: record, at: indexPath)
	}

	public func updateAdditionalDriveItems(from subscription: OCDataSourceSubscription) {
		let snapshot = subscription.snapshotResettingChangeTracking(true)

		if let core = clientContext?.core,
		   let firstItemRef = snapshot.items.first,
	  	   let itemRecord = try? subscription.source?.record(forItemRef: firstItemRef),
		   let drive = itemRecord.item as? OCDrive,
		   let driveRepresentation = OCDataRenderer.default.renderItem(drive, asType: .presentable, error: nil) as? OCDataItemPresentable,
		   let descriptionResourceRequest = try? driveRepresentation.provideResourceRequest(.coverDescription) {
			descriptionResourceRequest.lifetime = .singleRun
			descriptionResourceRequest.changeHandler = { [weak self] (request, error, isOngoing, previousResource, newResource) in
				// Log.debug("REQ_Readme request: \(String(describing: request)) | error: \(String(describing: error)) | isOngoing: \(isOngoing) | newResource: \(String(describing: newResource))")
				if let textResource = newResource as? OCResourceText {
					self?.driveAdditionalItemsDataSource.setItems([textResource], updated: [textResource])
				}
			}

			core.vault.resourceManager?.start(descriptionResourceRequest)
		}
	}

	var _actionProgressHandler : ActionProgressHandler?
}
