//
//  OCItemPolicy+UniversalItemListCellContentProvider.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 20.02.23.
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

extension OCItemPolicy: UniversalItemListCellContentProvider {
	public func provideContent(for cell: UniversalItemListCell, context: ClientContext?, configuration: CollectionViewCellConfiguration?, updateContent: @escaping UniversalItemListCell.ContentUpdater) {
		let content = UniversalItemListCell.Content(with: self)
		let isFile = location?.type == .file

		// Icon
		content.icon = isFile ? .file : ((location?.isDriveRoot == true) ? .drive : .folder)

		// Title
		if location?.isDriveRoot == true, let driveID = location?.driveID, let drive = context?.core?.drive(withIdentifier: driveID), let driveName = drive.name {
			content.title = .drive(name: driveName)
		} else if let name = location?.lastPathComponent {
			content.title = isFile ? .file(name: name) : .folder(name: name)
		}

		// Details
		if let context, let location = isFile ? location?.parent : location {
			let breadcrumbs = location.breadcrumbs(in: context, includeServerName: context.core?.useDrives == false)
			var breadcrumbSegments = OCLocation.composeSegments(breadcrumbs: breadcrumbs, in: context)

			// More compact breadcrumbs
			for breadcrumbSegment in breadcrumbSegments {
			breadcrumbSegment.insets.trailing = 0
			breadcrumbSegment.insets.leading = 0
			}

			let availableOfflineInfoSegment = SegmentViewItem(with: UIImage(named: "cloud-available-offline"), title: "", style: .plain, titleTextStyle: .footnote)
			availableOfflineInfoSegment.insets = .zero
			availableOfflineInfoSegment.insets.trailing = 5
			availableOfflineInfoSegment.iconTitleSpacing = 3

			breadcrumbSegments.insert(availableOfflineInfoSegment, at: 0)

			content.details = breadcrumbSegments
		}

		// Accessories
		content.accessories = [ cell.revealButtonAccessory ]

		// Icon retrieval for files
		if let itemLocation = location {
		   	let tokenArray: NSMutableArray = NSMutableArray()

			if let trackItemToken = context?.core?.trackItem(at: itemLocation, trackingHandler: { [weak cell] error, item, isInitial in
				if let item, let cell {
					let updatedContent = UniversalItemListCell.Content(with: content)

					updatedContent.details?.first?.title = item.sizeLocalized

					OnMainThread {
						if isFile {
							updatedContent.icon = .resource(request: OCResourceRequestItemThumbnail.request(for: item, maximumSize: cell.thumbnailSize, scale: 0, waitForConnectivity: true, changeHandler: nil))
							updatedContent.onlyFields = [.icon, .details]
						} else {
							updatedContent.onlyFields = [.details]
						}

						if !updateContent(updatedContent) {
							tokenArray.removeAllObjects() // Drop token, end tracking
						}
					}
				}
			}) {
				tokenArray.add(trackItemToken)
			}

			cell.contentProviderUserInfo = tokenArray
		}

		_ = updateContent(content)
	}
}

extension OCItemPolicy {
	static func registerUniversalCellProvider() {
		let cellRegistration = UICollectionView.CellRegistration<UniversalItemListCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let itemPolicy = OCDataRenderer.default.renderItem(item, asType: .itemPolicy, error: nil, withOptions: nil) as? OCItemPolicy {
					cell.fill(from: itemPolicy, context: cellConfiguration.clientContext, configuration: cellConfiguration)
				}
			})
		}

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .itemPolicy, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
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
