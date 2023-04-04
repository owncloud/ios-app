//
//  ItemLayout.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 04.04.23.
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

public enum ItemLayout {
	// MARK: - Layouts
	case list
	case grid

	// MARK: - Layout information
	public func sectionCellLayout(for traitCollection: UITraitCollection) -> CollectionViewSection.CellLayout {
		switch self {
			case .list:
				return .list(appearance: .plain, contentInsets: NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))

			case .grid:
				return .grid(itemWidthDimension: .absolute(142), itemHeightDimension: .absolute(180), contentInsets: NSDirectionalEdgeInsets(top: 10, leading: 5, bottom: 10, trailing: 5))
		}
	}

	public var cellStyleType: CollectionViewCellStyle.StyleType {
		switch self {
			case .list:
				return .tableCell

			case .grid:
				return .gridCell
		}
	}

	public var cellStyle: CollectionViewCellStyle {
		return CollectionViewCellStyle(with: cellStyleType)
	}
}
