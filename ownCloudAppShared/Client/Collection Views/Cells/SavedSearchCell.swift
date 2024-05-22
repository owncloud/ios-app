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
	let titleLabel = ThemeCSSLabel(withSelectors: [.title])
	let segmentView = SegmentView(with: [], truncationMode: .truncateTail)
	let sideButton = UIButton()

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
			hasItemsConstraint?.isActive = segmentView.items.count > 0
		}
	}

	private var sideButtonUIAction: UIAction?
	var sideButtonAction: OCAction? {
		didSet {
			if let sideButtonUIAction {
				sideButton.removeAction(sideButtonUIAction, for: .primaryActionTriggered)
				self.sideButtonUIAction = nil
			}

			if let sideButtonAction {
				sideButton.configuration?.image = sideButtonAction.icon
				sideButton.configuration?.imagePadding = (sideButtonAction.icon != nil) ? 5 : 0
				sideButton.configuration?.title = sideButtonAction.title
				sideButton.configuration?.buttonSize = .small
				sideButton.isEnabled = true
				sideButton.isHidden = false

				sideButtonUIAction = sideButtonAction.uiAction()
				if let sideButtonUIAction {
					sideButton.addAction(sideButtonUIAction, for: .primaryActionTriggered)
				}
			} else {
				sideButton.isHidden = true
				sideButton.isEnabled = false
				sideButton.configuration?.image = nil
				sideButton.configuration?.title = ""
			}
		}
	}

	private var hasItemsConstraint: NSLayoutConstraint?

	func configure() {
		cssSelector = .savedSearch

		iconView.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		segmentView.translatesAutoresizingMaskIntoConstraints = false
		sideButton.translatesAutoresizingMaskIntoConstraints = false

		contentView.addSubview(titleLabel)
		contentView.addSubview(iconView)
		contentView.addSubview(segmentView)
		contentView.addSubview(sideButton)

		iconView.image = icon
		iconView.contentMode = .scaleAspectFit

		titleLabel.setContentHuggingPriority(.required, for: .vertical)
		titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

		titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
		titleLabel.lineBreakMode = .byWordWrapping
		titleLabel.numberOfLines = 1

		iconView.setContentHuggingPriority(.required, for: .horizontal)

		sideButton.configuration = .tinted()
		sideButton.configuration?.title = "Add to sidebar".localized

		var backgroundConfig = UIBackgroundConfiguration.clear()
		backgroundConfig.cornerRadius = 10
		backgroundConfiguration = backgroundConfig
	}

	func configureLayout() {
		iconInsets = UIEdgeInsets(top: 11, left: 10, bottom: 13, right: 5)
		titleInsets = UIEdgeInsets(top: 13, left: 3, bottom: 13, right: 10)

		titleLabel.textAlignment = .left

		titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
		titleLabel.adjustsFontForContentSizeCategory = true

		hasItemsConstraint = titleLabel.bottomAnchor.constraint(equalTo: segmentView.topAnchor, constant: -titleSegmentSpacing)

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
			titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -titleInsets.bottom).with(priority: .defaultHigh), // Constraint effective if the cell has no items, overridden by hasItemsConstraint if active
			hasItemsConstraint!, // Constraint effective if the cell has items

			segmentView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
			segmentView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
			segmentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -titleInsets.bottom),

			sideButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -titleInsets.right),
			sideButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
		]
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
		return (isNameUserDefined && name.count > 0) ? name : (isTemplate ? "Search template".localized : "Saved search".localized)
	}

	var sideBarDisplayName: String {
		return (isNameUserDefined && name.count > 0) ? name : searchTerm
	}
}

extension SavedSearchCell {
	static let savedTemplateIcon = OCSymbol.icon(forSymbolName: "square.dashed.inset.filled")
	static let savedSearchIcon = OCSymbol.icon(forSymbolName: "folder.badge.gearshape")

	static func registerCellProvider() {
		let savedSearchCellRegistration = UICollectionView.CellRegistration<SavedSearchCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let savedSearch = OCDataRenderer.default.renderItem(item, asType: .savedSearch, error: nil, withOptions: nil) as? OCSavedSearch {
					var icon: UIImage?

					if let customIconName = savedSearch.customIconName {
						icon = OCSymbol.icon(forSymbolName: customIconName)
					}

					if icon == nil {
						icon = savedSearch.isTemplate ? savedTemplateIcon : savedSearchIcon
					}

					cell.title = savedSearch.displayName
					cell.icon = icon
					cell.items = (savedSearch.isQuickAccess == true) ? nil : savedSearch.segmentViewItemsForDisplay

					let clientContext = cellConfiguration.clientContext

					cell.sideButtonAction = savedSearch.isQuickAccess == true && savedSearch.isTemplate ? OCAction(title: "Add to sidebar".localized, icon: OCSymbol.icon(forSymbolName: "plus.circle.fill"), action: { [weak clientContext] _, _, completed in
						// Make a copy of the saved search object, so it has a different UUID (avoiding ID clashes in collection views) and can be modified
						if let saveSearch = savedSearch.copy() as? OCSavedSearch {
							saveSearch.isQuickAccess = true
							saveSearch.isTemplate = false
							clientContext?.core?.vault.add(saveSearch)
						}
						completed(nil)
					}) : nil

					if let sideButtonAction = cell.sideButtonAction {
						cell.accessibilityCustomActions = [
							sideButtonAction.accessibilityCustomAction()
						]
					} else {
						cell.accessibilityCustomActions = nil
					}
				}
			})
		}

		let savedSearchSidebarCellRegistration = UICollectionView.CellRegistration<ThemeableCollectionViewListCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			var content = cell.defaultContentConfiguration()

			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let savedSearch = OCDataRenderer.default.renderItem(item, asType: .savedSearch, error: nil, withOptions: nil) as? OCSavedSearch {
					content.text = savedSearch.sideBarDisplayName
					if let customIconName = savedSearch.customIconName {
						content.image = OCSymbol.icon(forSymbolName: customIconName)
					} else {
						content.image = savedSearch.isTemplate ? savedTemplateIcon : savedSearchIcon
					}
				}
			})

			cell.backgroundConfiguration = .listSidebarCell()
			cell.contentConfiguration = content
			cell.applyThemeCollection(theme: Theme.shared, collection: Theme.shared.activeCollection, event: .initial)
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

extension ThemeCSSSelector {
	public static let savedSearch = ThemeCSSSelector(rawValue: "savedSearch")
}
