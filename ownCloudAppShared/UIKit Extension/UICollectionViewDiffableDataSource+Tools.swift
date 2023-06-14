//
//  UICollectionViewDiffableDataSource+Tools.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 04.04.22.
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

public extension UICollectionViewDiffableDataSource {
	func requestReconfigurationOfItems(_ items: [ItemIdentifierType], animated: Bool = true) {
		var snapshot = snapshot()
		snapshot.reconfigureItems(items)
		apply(snapshot, animatingDifferences: animated)
	}

	func requestReloadOfItems(_ items: [ItemIdentifierType], animated: Bool = true) {
		var snapshot = snapshot()
		snapshot.reloadItems(items)
		apply(snapshot, animatingDifferences: animated)
	}
}
