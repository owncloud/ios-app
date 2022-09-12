//
//  CollectionViewCellProvider.swift
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

public class CollectionViewCellProvider: NSObject {
	// MARK: - Types
	public typealias CellProvider = (_ collectionView: UICollectionView, _ cellConfiguration: CollectionViewCellConfiguration?, _ itemRecord: OCDataItemRecord, _ collectionItemRef: CollectionViewController.ItemRef, _ indexPath: IndexPath) -> UICollectionViewCell

	// MARK: - Global registry
	static var cellProviders : [OCDataItemType:CollectionViewCellProvider] = [:]

	public static func register(_ cellProvider: CollectionViewCellProvider) {
		cellProviders[cellProvider.dataItemType] = cellProvider
	}

	public static func providerFor(_ itemRecord: OCDataItemRecord) -> CollectionViewCellProvider? {
		return cellProviders[itemRecord.type]
	}

	public static func providerFor(_ itemType: OCDataItemType) -> CollectionViewCellProvider? {
		return cellProviders[itemType]
	}

	// MARK: - Implementation

	var provider : CellProvider
	var dataItemType : OCDataItemType

	public func provideCell(for collectionView: UICollectionView, cellConfiguration: CollectionViewCellConfiguration?, itemRecord: OCDataItemRecord, collectionItemRef: CollectionViewController.ItemRef, indexPath: IndexPath) -> UICollectionViewCell {
		// Save any existing cell configuration
		let previousCellConfiguration = collectionItemRef.ocCellConfiguration

		// Set cell configuration
		collectionItemRef.ocCellConfiguration = cellConfiguration

		// Ask provider to provide cell
		let cell = provider(collectionView, cellConfiguration, itemRecord, collectionItemRef, indexPath)

		// Restore previously existing cell configuration
		collectionItemRef.ocCellConfiguration = previousCellConfiguration

		return cell
	}

	public init(for type : OCDataItemType, with cellProvider: @escaping CellProvider) {
		provider = cellProvider
		dataItemType = type

		super.init()
	}
}
