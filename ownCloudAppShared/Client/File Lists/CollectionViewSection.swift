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

	func updateDatasourceSubscription() {
		if let dataSource = dataSource {
			dataSourceSubscription = dataSource.subscribe(updateHandler: { [weak self] (subscription) in
				self?.handleListUpdates(from: subscription)
			}, on: .main, trackDifferences: true, performIntialUpdate: true)
		}
	}

	public init(identifier: SectionIdentifier, dataSource inDataSource: OCDataSource?) {
		self.identifier = identifier
		super.init()

		self.dataSource = inDataSource
		updateDatasourceSubscription() // dataSource.didSet is not called during initialization
	}

	deinit {
		dataSourceSubscription?.terminate()
	}

	func handleListUpdates(from subscription: OCDataSourceSubscription) {
		collectionViewController?.updateSource(animatingDifferences: true)
	}

	func provideReusableCell(for collectionView: UICollectionView, itemRef: OCDataItemReference, indexPath: IndexPath) -> UICollectionViewCell {
		var cell: UICollectionViewCell?

		if let itemRecord = try? dataSource?.record(forItemRef: itemRef), let itemRecord = itemRecord {
			var cellProvider = CollectionViewCellProvider.providerFor(itemRecord)

			if cellProvider == nil {
				cellProvider = CollectionViewCellProvider.providerFor(.presentable)
			}

			if let cellProvider = cellProvider, let dataSource = dataSource {
				let cellConfiguration = OCDataItemCellConfiguration(source: dataSource)

				cellConfiguration.reference = itemRef
				cellConfiguration.record = itemRecord
				cellConfiguration.hostViewController = self.collectionViewController

				cell = cellProvider.provideCell(for: collectionView, cellConfiguration: cellConfiguration, itemRecord: itemRecord, itemRef: itemRef, indexPath: indexPath)
			}
		}

		return cell ?? UICollectionViewCell()
	}
}
