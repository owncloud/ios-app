//
//  OCIdentity+UniversalItemListCellContentProvider.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 18.04.23.
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

extension OCIdentity: UniversalItemListCellContentProvider {
	public func provideContent(for cell: UniversalItemListCell, context: ClientContext?, configuration: CollectionViewCellConfiguration?, updateContent: @escaping UniversalItemListCell.ContentUpdater) {
		let content = UniversalItemListCell.Content(with: self)

		// Icon
		if let user {
			let avatarRequest = OCResourceRequestAvatar(for: user, maximumSize: OCAvatar.defaultSize, scale: 0, waitForConnectivity: false)
			content.icon = .resource(request: avatarRequest)
		}

		if group != nil, let groupIcon = OCSymbol.icon(forSymbolName: "person.3.fill") {
			content.icon = .icon(image: groupIcon)
		}

		// Title
		if let title = displayName ?? searchResultName {
			content.title = .text(title)
		}

		// Details
		var detailText: String?

		if let user {
			if let displayName = user.displayName {
				content.title = .text(displayName)
			}
			detailText = user.userName
		}

		if group != nil {
			detailText = "Group".localized
		}

		if let detailText {
			content.details = [
				.detailText(detailText)
			]
		}

		_ = updateContent(content)
	}
}

extension OCIdentity {
	static func registerUniversalCellProvider() {
		let identityCellRegistration = UICollectionView.CellRegistration<UniversalItemListCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let identity = OCDataRenderer.default.renderItem(item, asType: .identity, error: nil, withOptions: nil) as? OCIdentity {
					cell.fill(from: identity, context: cellConfiguration.clientContext, configuration: cellConfiguration)
				}
			})
		}

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .identity, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			return collectionView.dequeueConfiguredReusableCell(using: identityCellRegistration, for: indexPath, item: itemRef)
		}))
	}
}
