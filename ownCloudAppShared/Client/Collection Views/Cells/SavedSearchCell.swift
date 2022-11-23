//
//  SavedSearchCell.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 22.09.22.
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
import ownCloudSDK
import ownCloudApp

class SavedSearchCell: ThemeableCollectionViewCell {
	override init(frame: CGRect) {
		super.init(frame: frame)
		configure()
		configureLayout()
	}

	required init?(coder: NSCoder) {
		fatalError()
	}

	let iconView = UIImageView()
	let titleLabel = UILabel()
	let segmentView = SegmentView(with: [], truncationMode: .truncateTail)

	var iconInsets: UIEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 0, right: 5)
	var titleInsets: UIEdgeInsets = UIEdgeInsets(top: 5, left: 3, bottom: 5, right: 3)
	var titleSegmentSpacing: CGFloat = 5

	var title: String? {
		didSet {
			titleLabel.text = title
		}
	}
	var icon: UIImage? {
		didSet {
			iconView.image = icon
		}
	}
	var items: [SegmentViewItem]? {
		didSet {
			segmentView.items = items ?? []
		}
	}
	var type: OCActionType = .regular {
		didSet {
			if superview != nil {
				applyThemeCollectionToCellContents(theme: Theme.shared, collection: Theme.shared.activeCollection, state: .normal)
			}
		}
	}

	func configure() {
		iconView.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		segmentView.translatesAutoresizingMaskIntoConstraints = false

		contentView.addSubview(titleLabel)
		contentView.addSubview(iconView)
		contentView.addSubview(segmentView)

		iconView.image = icon
		iconView.contentMode = .scaleAspectFit

		titleLabel.setContentHuggingPriority(.required, for: .vertical)
		titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

		titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
		titleLabel.lineBreakMode = .byWordWrapping
		titleLabel.numberOfLines = 1

		iconView.setContentHuggingPriority(.required, for: .horizontal)

		let backgroundConfig = UIBackgroundConfiguration.clear()
		backgroundConfiguration = backgroundConfig
	}

	func configureLayout() {
		iconInsets = UIEdgeInsets(top: 11, left: 10, bottom: 13, right: 5)
		titleInsets = UIEdgeInsets(top: 13, left: 3, bottom: 13, right: 10)

		titleLabel.textAlignment = .left

		titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
		titleLabel.adjustsFontForContentSizeCategory = true

		self.configuredConstraints = [
			iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: iconInsets.left),
			iconView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -(iconInsets.right + titleInsets.left)),
			iconView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
			// iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: iconInsets.top),
			// iconView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -iconInsets.bottom),
			// iconView.widthAnchor.constraint(equalTo: iconView.heightAnchor),
			iconView.widthAnchor.constraint(equalToConstant: 24),
			iconView.heightAnchor.constraint(equalToConstant: 24),

			titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -titleInsets.right),
			titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: titleInsets.top),
			titleLabel.bottomAnchor.constraint(equalTo: segmentView.topAnchor, constant: -titleSegmentSpacing),

			segmentView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
			segmentView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
			segmentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -titleInsets.bottom)
		]
	}

	override func updateConfiguration(using state: UICellConfigurationState) {
		let collection = Theme.shared.activeCollection
		var backgroundConfig = backgroundConfiguration?.updated(for: state)

		if state.isHighlighted || state.isSelected || (state.cellDropState == .targeted) {
			backgroundConfig?.backgroundColor = (type == .destructive) ? collection.destructiveColors.highlighted.background : collection.tableRowButtonColors.filledColorPairCollection.highlighted.background
		} else {
			backgroundConfig?.backgroundColor = (type == .destructive) ? collection.destructiveColors.normal.background : collection.tableRowButtonColors.filledColorPairCollection.normal.background
		}

		backgroundConfig?.cornerRadius = 8

		backgroundConfiguration = backgroundConfig
	}

	override func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection, state: ThemeItemState) {
		super.applyThemeCollectionToCellContents(theme: theme, collection: collection, state: state)

		titleLabel.textColor = (type == .destructive) ? collection.destructiveColors.normal.foreground : collection.tintColor
		iconView.tintColor = (type == .destructive) ? collection.destructiveColors.normal.foreground : collection.tintColor

		setNeedsUpdateConfiguration()
	}
}

extension OCSavedSearch {
	private var queryConditionsForDisplay: [OCQueryCondition] {
		let searchSegments = (searchTerm as NSString).segmentedForSearch(withQuotationMarks: true)
		var queryConditions: [OCQueryCondition] = []

		for searchSegment in searchSegments {
			if let queryCondition = OCQueryCondition.forSearchSegment(searchSegment) {
				queryConditions.append(queryCondition)
			}
		}

		return queryConditions
	}

	public var segmentViewItemsForDisplay: [SegmentViewItem] {
		let conditions = queryConditionsForDisplay
		var items: [SegmentViewItem] = []

		for condition in conditions {
			var item: SegmentViewItem?

			if condition.property == .name || (condition.localizedDescription == nil) {
				item = SegmentViewItem(with: nil, title: condition.searchSegment, style: .plain, titleTextStyle: .footnote)
				item?.insets = .zero
			} else {
				item = SegmentViewItem(with: OCSymbol.icon(forSymbolName: condition.symbolName), title: condition.localizedDescription, style: .token, titleTextStyle: .caption1)
				item?.cornerStyle = .round(points: 3)
			}

			if let item = item {
				items.append(item)
			}
		}

		return items
	}
}

extension OCSavedSearch {
	var displayName: String {
		return (isNameUserDefined && name.count > 0) ? name : (isTemplate ? "Search template".localized : "Search view".localized)
	}

	var sideBarDisplayName: String {
		return (isNameUserDefined && name.count > 0) ? name : searchTerm
	}
}

extension SavedSearchCell {
	static let savedTemplateIcon = OCSymbol.icon(forSymbolName: "square.dashed.inset.filled")
	static let savedSearchIcon = OCSymbol.icon(forSymbolName: "gearshape.fill")

	static func registerCellProvider() {
		let savedSearchCellRegistration = UICollectionView.CellRegistration<SavedSearchCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let savedSearch = OCDataRenderer.default.renderItem(item, asType: .savedSearch, error: nil, withOptions: nil) as? OCSavedSearch {
					cell.title = savedSearch.displayName
					cell.icon = savedSearch.isTemplate ? savedTemplateIcon : savedSearchIcon
					cell.items = savedSearch.segmentViewItemsForDisplay
				}
			})
		}

		let savedSearchSidebarCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			var content = cell.defaultContentConfiguration()

			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let savedSearch = OCDataRenderer.default.renderItem(item, asType: .savedSearch, error: nil, withOptions: nil) as? OCSavedSearch {
					content.text = savedSearch.sideBarDisplayName
					content.image = savedSearch.isTemplate ? savedTemplateIcon : savedSearchIcon
				}
			})

			cell.contentConfiguration = content
		}

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .savedSearch, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			switch cellConfiguration?.style.type {
				case .sideBar:
					return collectionView.dequeueConfiguredReusableCell(using: savedSearchSidebarCellRegistration, for: indexPath, item: itemRef)

				default:
					return collectionView.dequeueConfiguredReusableCell(using: savedSearchCellRegistration, for: indexPath, item: itemRef)
			}
		}))
	}
}
