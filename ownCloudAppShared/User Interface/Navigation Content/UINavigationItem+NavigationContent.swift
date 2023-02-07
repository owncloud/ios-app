//
//  UINavigationItem+NavigationContent.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 24.01.23.
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

public extension UINavigationItem {
	var navigationContent: NavigationContent {
		let navigationContent: NavigationContent! = value(forAnnotatedProperty: "_navigationContent", withGenerator: {
			return NavigationContent(for: self)
		}) as? NavigationContent

		return navigationContent
	}

	func takeNavigationContentSnapshot(withIdentifier identifier: String, priority: NavigationContent.Priority, position: NavigationContent.Position) -> NavigationContent.Snapshot {
		let snapshot: NavigationContent.Snapshot = [
			NavigationContentItem(identifier: identifier, area: .left, priority: priority, position: position, items: leftBarButtonItems),
			NavigationContentItem(identifier: identifier, area: .right, priority: priority, position: position, items: rightBarButtonItems)
		]

		return snapshot
	}

	func applyNavigationContentSnapshot(_ snapshot: NavigationContent.Snapshot) {
		for item in snapshot {
			switch item.area {
				case .left:
					leftBarButtonItems = item.items

				case .right:
					rightBarButtonItems = item.items

				default: break
			}
		}
	}
}
