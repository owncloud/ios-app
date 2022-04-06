//
//  UICollectionViewDiffableDataSource+Tools.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 04.04.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

import UIKit

public extension UICollectionViewDiffableDataSource {
	func requestReconfigurationOfItems(_ items: [ItemIdentifierType], animated: Bool = true) {
		var snapshot = snapshot()
		snapshot.reconfigureItems(items)
		apply(snapshot, animatingDifferences: true)
	}
}
