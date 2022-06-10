//
//  ViewCell.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 31.05.22.
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

class ViewCell: ThemeableCollectionViewListCell {
	static func registerCellProvider() {
		let itemListCellRegistration = UICollectionView.CellRegistration<ViewCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let view = item as? UIView {
					let contentView = cell.contentView

					contentView.addSubview(view)

					NSLayoutConstraint.activate([
						// Fill cell.contentView
						view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
						view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
						view.topAnchor.constraint(equalTo: contentView.topAnchor),
						view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

						// Extend cell seperator to contentView.leadingAnchor
						cell.separatorLayoutGuide.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor)
					])
				}
			})
		}

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .view, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			return collectionView.dequeueConfiguredReusableCell(using: itemListCellRegistration, for: indexPath, item: itemRef)
		}))
	}
}
