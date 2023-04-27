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

public enum ItemLayout: CaseIterable {
	// MARK: - Layouts
	case list
	case grid
	case gridLowDetail
	case gridNoDetail

	public func labelAndIcon() -> (String, UIImage?) {
		switch self {
			case .list:
				return ("List".localized, OCSymbol.icon(forSymbolName: "list.bullet"))

			case .grid:
				return ("Grid".localized, OCSymbol.icon(forSymbolName: "square.grid.2x2"))

			case .gridLowDetail:
				return ("Item grid".localized, OCSymbol.icon(forSymbolName: "text.below.photo"))

			case .gridNoDetail:
				return ("Image grid".localized, OCSymbol.icon(forSymbolName: "photo"))
		}
	}

	// MARK: - Layout information
	public func sectionCellLayout(for traitCollection: UITraitCollection, collectionView: UICollectionView? = nil) -> CollectionViewSection.CellLayout {
		switch self {
			case .list:
				return .list(appearance: .plain, contentInsets: NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))

			case .grid, .gridLowDetail, .gridNoDetail:
				let titleAndDetailsHeight = UniversalItemListCell.titleAndDetailsHeight(withTitle: (self != .gridNoDetail), withPrimarySegment: (self == .grid), withSecondarySegment: (self == .grid))

				return .fillingGrid(minimumWidth: 130, maximumWidth: 160, computeHeight: { width in
					return (width * 3 / 4) + titleAndDetailsHeight
				}, cellSpacing: NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5), sectionInsets: NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5), center: true)
		}
	}

	public var cellStyleType: CollectionViewCellStyle.StyleType {
		switch self {
			case .list:
				return .tableCell

			case .grid:
				return .gridCell

			case .gridLowDetail:
				return .gridCellLowDetail

			case .gridNoDetail:
				return .gridCellNoDetail
		}
	}

	public var cellStyle: CollectionViewCellStyle {
		return CollectionViewCellStyle(with: cellStyleType)
	}
}
