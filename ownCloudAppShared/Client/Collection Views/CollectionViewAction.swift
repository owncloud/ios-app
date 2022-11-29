//
//  CollectionViewAction.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 24.11.22.
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

public class CollectionViewAction: NSObject {
	public enum Kind {
		case select(animated: Bool, scrollPosition: UICollectionView.ScrollPosition)
		case expand(animated: Bool)
	}

	public var kind: Kind
	public var itemReference: CollectionViewController.ItemRef

	public init(kind: Kind, itemReference: CollectionViewController.ItemRef) {
		self.kind = kind
		self.itemReference = itemReference
	}

	public func apply(on viewController: CollectionViewController, completion: (() -> Void)?) -> Bool {
		if let indexPath = viewController.collectionViewDataSource?.indexPath(for: itemReference), let collectionView = viewController.collectionView {
			switch kind {
				case .select(animated: let animated, scrollPosition: let scrollPosition):
					viewController.performDataSourceUpdate { updateDone in
						if viewController.collectionView(collectionView, shouldSelectItemAt: indexPath) {
							collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: scrollPosition)
							viewController.collectionView(collectionView, didSelectItemAt: indexPath)
						}

						completion?()
						updateDone()
					}
					return true

				case .expand(animated: let animated):
					let (_, sectionID) = viewController.unwrap(itemReference)

					viewController.performDataSourceUpdate { updateDone in
						if let datasource = viewController.collectionViewDataSource, let sectionID {
							var sectionSnapshot = datasource.snapshot(for: sectionID)
							sectionSnapshot.expand([ self.itemReference ])
							datasource.apply(sectionSnapshot, to: sectionID, animatingDifferences: animated, completion: {
								completion?()
								updateDone()
							})
						} else {
							completion?()
							updateDone()
						}
					}

					return true
			}
		}

		return false
	}
}
