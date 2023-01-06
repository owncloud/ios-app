//
//  OCShare+UniversalItemListCellContentProvider.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 05.01.23.
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

extension OCShare: UniversalItemListCellContentProvider {
	public func provideContent(for cell: UniversalItemListCell, context: ClientContext?, configuration: CollectionViewCellConfiguration?, updateContent: UniversalItemListCell.ContentUpdater) {
		let content = UniversalItemListCell.Content(with: self)
		let isFile = (itemType == .file)

		// Icon
		if let mimeType = itemMIMEType, isFile {
			content.icon = .mime(type: mimeType)
		} else {
			content.icon = isFile ? .file : .folder
		}

		// Title
		if let name = itemLocation.lastPathComponent {
			content.title = isFile ? .file(name: name) : .folder(name: name)
		}

		// Details
		let ownerName = owner?.displayName ?? owner?.userName ?? ""
		let ownerSegment = SegmentViewItem(with: nil, title: "Shared by {{owner}}".localized([ "owner" : ownerName ]), style: .plain, titleTextStyle: .footnote)
		ownerSegment.insets = .zero

		content.details = [
			ownerSegment
		]

		_ = updateContent(content)
	}
}

extension OCShare {
	static func registerUniversalCellProvider() {
		let shareCellRegistration = UICollectionView.CellRegistration<UniversalItemListCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let share = OCDataRenderer.default.renderItem(item, asType: .share, error: nil, withOptions: nil) as? OCShare {
					cell.fill(from: share, context: cellConfiguration.clientContext, configuration: cellConfiguration)
				}
			})
		}

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .share, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			switch cellConfiguration?.style.type {
//				case .sideBar:
//					return collectionView.dequeueConfiguredReusableCell(using: savedSearchSidebarCellRegistration, for: indexPath, item: itemRef)
//
				default:
					return collectionView.dequeueConfiguredReusableCell(using: shareCellRegistration, for: indexPath, item: itemRef)
			}
		}))
	}
}
