//
//  RecentLocation+UniversalItemListCellContentProvider.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 23.05.25.
//  Copyright © 2025 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2025, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

extension RecentLocation: UniversalItemListCellContentProvider {
	public func provideContent(for cell: UniversalItemListCell, context: ClientContext?, configuration: CollectionViewCellConfiguration?, updateContent: @escaping UniversalItemListCell.ContentUpdater) {
		let content = UniversalItemListCell.Content(with: self)

		// Icon
		content.icon = (location?.isDriveRoot == true) ? .drive : .folder

		// Title
		if let displayName {
			content.title = .folder(name: displayName)
		}

		// Details
		var detailsLine: [SegmentViewItem] = []

		if let driveName, location?.type != .drive {
			let driveDetailItem = SegmentViewItem(with: OCSymbol.icon(forSymbolName: "square.grid.2x2.fill"), title: driveName, style: .plain, titleTextStyle: .footnote, linebreakMode: .byTruncatingMiddle)
			driveDetailItem.lines = [ .primary, .singleLine ]
			detailsLine.append(driveDetailItem)
		}

		if let bookmarkUUID = location?.bookmarkUUID, let bookmark = OCBookmarkManager.shared.bookmark(for: bookmarkUUID) {
			let accountDetailItem = SegmentViewItem(with: OCSymbol.icon(forSymbolName: "server.rack"), title: bookmark.displayName ?? bookmark.shortName, style: .plain, titleTextStyle: .footnote, linebreakMode: .byTruncatingMiddle)
			accountDetailItem.lines = [ .secondary, .singleLine ]
			detailsLine.append(accountDetailItem)
		}

		for item in detailsLine {
			item.insets = .zero
			item.iconTitleSpacing = 3
		}

		content.details = detailsLine

		_ = updateContent(content)
	}
}

extension RecentLocation {
	static func registerUniversalCellProvider() {
		let cellRegistration = UICollectionView.CellRegistration<RecentLocationCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let recentLocation = OCDataRenderer.default.renderItem(item, asType: .recentLocation, error: nil, withOptions: nil) as? RecentLocation {
					cell.fill(from: recentLocation, context: cellConfiguration.clientContext, configuration: cellConfiguration)
				}
			})
		}

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .recentLocation, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			switch cellConfiguration?.style.type {
				default:
					let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemRef)

					if cellConfiguration?.highlight == true {
						cell.revealHighlight = true
					}

					return cell
			}
		}))
	}
}
