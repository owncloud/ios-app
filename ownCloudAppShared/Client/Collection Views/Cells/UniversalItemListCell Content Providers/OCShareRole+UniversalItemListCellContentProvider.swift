//
//  OCShareRole+UniversalItemListCellContentProvider.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 20.04.23.
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
import ownCloudSDK

extension OCShareRole: UniversalItemListCellContentProvider {
	public func provideContent(for cell: UniversalItemListCell, context: ClientContext?, configuration: CollectionViewCellConfiguration?, updateContent: @escaping UniversalItemListCell.ContentUpdater) {
		let content = UniversalItemListCell.Content(with: self)

		if let icon = OCSymbol.icon(forSymbolName: symbolName) {
			content.icon = .icon(image: icon)
		}

		content.title = .text(localizedName)

		let detailTextSegment = SegmentViewItem(with: nil, title: localizedDescription, style: .plain, titleTextStyle: .footnote)
		detailTextSegment.insets = .zero

		content.details = [
			detailTextSegment
		]

		_ = updateContent(content)
	}
}

extension OCShareRole {
	static func registerUniversalCellProvider() {
		let cellRegistration = UICollectionView.CellRegistration<UniversalItemListCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let shareRole = OCDataRenderer.default.renderItem(item, asType: .shareRole, error: nil, withOptions: nil) as? OCShareRole {
					cell.fill(from: shareRole, context: cellConfiguration.clientContext, configuration: cellConfiguration)
				}
			})
		}

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .shareRole, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemRef)
		}))
	}
}
