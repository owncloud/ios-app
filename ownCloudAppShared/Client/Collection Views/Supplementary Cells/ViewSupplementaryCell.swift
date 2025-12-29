//
//  ViewSupplementaryCell.swift
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

public extension CollectionViewSupplementaryItem.ElementKind {
	static let view = "view"
}

class ViewSupplementaryCell: UICollectionReusableView {
	// MARK: - Content
	var view: UIView? {
		willSet {
			view?.removeFromSuperview()
		}

		didSet {
			if let view {
				embed(toFillWith: view, insets: .zero, enclosingAnchors: safeAreaAnchorSet)
			}
		}
	}

	// MARK: - Prepare for reuse
	override func prepareForReuse() {
		super.prepareForReuse()
		view = nil
	}

	// MARK: - Registration
	static func registerSupplementaryCellProvider() {
		let supplementaryViewElementKinds: [CollectionViewSupplementaryItem.ElementKind] = [ .view ]

		for supplementaryViewElementKind in supplementaryViewElementKinds {
			let viewSupplementaryCellRegistration = UICollectionView.SupplementaryRegistration<ViewSupplementaryCell>(elementKind: supplementaryViewElementKind) { supplementaryView, elementKind, indexPath in
			}

			CollectionViewSupplementaryCellProvider.register(CollectionViewSupplementaryCellProvider(for: supplementaryViewElementKind, with: { collectionView, section, supplementaryItem, indexPath in
				let cellView = collectionView.dequeueConfiguredReusableSupplementary(using: viewSupplementaryCellRegistration, for: indexPath)

				cellView.view = supplementaryItem.content as? UIView

				return cellView
			}))
		}
	}
}

public extension CollectionViewSupplementaryItem {
	static func view(_ view: UIView, pinned: Bool = false, elementKind: CollectionViewSupplementaryItem.ElementKind = .view, alignment: NSRectAlignment = .top) -> CollectionViewSupplementaryItem {
		// Fix UIKit framework warning (logged as "Invalid estimated dimension, must be > 0. NOTE: This will be a hard-assert soon, please update your call site.")
		var estimatedHeight = view.frame.size.height

		if estimatedHeight == 0 {
			// Force layout of view (hoping its height will be > 0 afterwards)
			view.setNeedsLayout()
			view.layoutIfNeeded()
			estimatedHeight = view.frame.size.height
		}

		if estimatedHeight == 0 {
			// If height is still 0, use a minimum height to avoid the warning / assert, but log a warning
			estimatedHeight = 1
			Log.warning("CollectionViewSupplementaryItem.view: estimatedHeight is still 0, using a default value of 1")
		}

	        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(estimatedHeight))
		let supplementaryItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: elementKind, alignment: alignment)

		if pinned {
			supplementaryItem.pinToVisibleBounds = true
			supplementaryItem.zIndex = 200
		}

		return CollectionViewSupplementaryItem(supplementaryItem: supplementaryItem, content: view)
	}
}
