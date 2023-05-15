//
//  CollectionViewSupplementaryCellProvider.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 21.02.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

open class CollectionViewSupplementaryCellProvider: NSObject {
	// MARK: - Types
	public typealias CellProvider = (_ collectionView: UICollectionView, _ section: CollectionViewSection?, _ supplementaryItem: CollectionViewSupplementaryItem, _ indexPath: IndexPath) -> UICollectionReusableView

	// MARK: - Global registry
	static var cellProviders : [CollectionViewSupplementaryItem.ElementKind:CollectionViewSupplementaryCellProvider] = [:]

	public static func register(_ cellProvider: CollectionViewSupplementaryCellProvider) {
		cellProviders[cellProvider.elementKind] = cellProvider
	}

	public static func providerFor(_ supplementaryItem: CollectionViewSupplementaryItem) -> CollectionViewSupplementaryCellProvider? {
		return cellProviders[supplementaryItem.elementKind]
	}

	public static func providerFor(_ itemType: CollectionViewSupplementaryItem.ElementKind) -> CollectionViewSupplementaryCellProvider? {
		return cellProviders[itemType]
	}

	// MARK: - Implementation

	var provider : CellProvider
	var elementKind: CollectionViewSupplementaryItem.ElementKind

	public func provideCell(for collectionView: UICollectionView, section: CollectionViewSection?, supplementaryItem: CollectionViewSupplementaryItem, indexPath: IndexPath) -> UICollectionReusableView {
		// Ask provider to provide cell and return it
		return provider(collectionView, section, supplementaryItem, indexPath)
	}

	public init(for elementKind : CollectionViewSupplementaryItem.ElementKind, with cellProvider: @escaping CellProvider) {
		self.provider = cellProvider
		self.elementKind = elementKind

		super.init()
	}

}
