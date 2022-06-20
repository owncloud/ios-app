//
//  CollectionViewController+DragDropSupport.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 13.06.22.
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
import ownCloudApp
import ownCloudSDK

// MARK: - Drag and drop support
extension CollectionViewController : UICollectionViewDragDelegate {
	public func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
		if let item = targetedDataItem(for: indexPath, interaction: .drag),
		   let dragInteraction = item as? DataItemDragInteraction {
			if let dragItems = dragInteraction.provideDragItems(with: clientContext) {
				return dragItems
			}
		}

		return []
	}

	public func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
		if let item = targetedDataItem(for: indexPath, interaction: .drag),
		   let dragInteraction = item as? DataItemDragInteraction {
			if let dragItems = dragInteraction.provideDragItems(with: clientContext) {
				return dragItems
			}
		}

		return []
	}
}

extension CollectionViewController : UICollectionViewDropDelegate {
	public func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
		if let item = targetedDataItem(for: destinationIndexPath, interaction: .acceptDrop),
		   let dropInteraction = item as? DataItemDropInteraction {
			if let dropProposal = dropInteraction.allowDropOperation?(for: session, with: clientContext) {
				return dropProposal
			}
		}

		return UICollectionViewDropProposal(operation: .forbidden, intent: .unspecified)
	}

	public func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		if let item = targetedDataItem(for: coordinator.destinationIndexPath, interaction: .acceptDrop),
		   let dropInteraction = item as? DataItemDropInteraction {
			let dragItems = coordinator.items.compactMap { collectionViewDropItem in collectionViewDropItem.dragItem }

			dropInteraction.performDropOperation(of: dragItems, with: clientContext, handlingCompletion: { didSucceed in
			})
		}
	}
}
