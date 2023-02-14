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
		case highlight(animated: Bool, scrollPosition: UICollectionView.ScrollPosition)
		case unhighlightAll(animated: Bool)
		case expand(animated: Bool)
	}

	public var kind: Kind
	public var itemReference: CollectionViewController.ItemRef?
	public var itemReferences: [CollectionViewController.ItemRef]?

	public init(kind: Kind, itemReference: CollectionViewController.ItemRef? = nil) {
		self.kind = kind
		self.itemReference = itemReference
	}

	convenience public init?(kind: Kind, itemReferences: [CollectionViewController.ItemRef]) {
		guard itemReferences.count > 0, let itemReference = itemReferences.first else { return nil }

		self.init(kind: kind, itemReference: itemReference)
		self.itemReferences = itemReferences
	}

	public func apply(on viewController: CollectionViewController, completion: (() -> Void)?) -> Bool {
		if let itemReferences {
			for itemRef in itemReferences {
				if apply(on: viewController, for: itemRef, completion: completion) {
					return true
				}
			}

			return false
		}

		return apply(on: viewController, for: itemReference, completion: completion)
	}

	func apply(on viewController: CollectionViewController, for itemRef: CollectionViewController.ItemRef?, completion: (() -> Void)?) -> Bool {
		guard let collectionView = viewController.collectionView else {
			return false
		}

		if let itemRef, let indexPath = viewController.collectionViewDataSource?.indexPath(for: itemRef) {
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

				case .highlight(animated: let animated, scrollPosition: let scrollPosition):
					viewController.performDataSourceUpdate { updateDone in
						if viewController.collectionView(collectionView, shouldSelectItemAt: indexPath) {
							collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: scrollPosition)
							// viewController.recordSelection(ofItemAt: indexPath, operation: .replace)
						}

						completion?()
						updateDone()
					}
					return true

				case .expand(animated: let animated):
					let (_, sectionID) = viewController.unwrap(itemRef)

					viewController.performDataSourceUpdate { updateDone in
						if let datasource = viewController.collectionViewDataSource, let sectionID {
							var sectionSnapshot = datasource.snapshot(for: sectionID)
							sectionSnapshot.expand([ itemRef ])
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

				default: break
			}
		} else {
			switch kind {
				case .unhighlightAll(animated: let animated):
					viewController.performDataSourceUpdate { updateDone in
						if let selectedIndexPaths = collectionView.indexPathsForSelectedItems {
							for selectedIndexPath in selectedIndexPaths {
								collectionView.deselectItem(at: selectedIndexPath, animated: animated)
							}
						}

						completion?()
						updateDone()
					}

					return true

				default: break
			}
		}

		return false
	}
}
