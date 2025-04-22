//
//  TitleSupplementaryCell.swift
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
	static let title = "title"
	static let mediumTitle = "mediumTitle"
	static let smallTitle = "smallTitle"
}

class TitleSupplementaryCell: UICollectionReusableView, Themeable {
	// MARK: - Content
	var label: UILabel?

	override init(frame: CGRect) {
		super.init(frame: frame)
		configure()
	}

	required init?(coder: NSCoder) {
		fatalError()
	}

	var elementKind: CollectionViewSupplementaryItem.ElementKind = .title {
		didSet {
			updateCSSSelectors()

			if themeRegistered {
				applyThemeCollection(theme: Theme.shared, collection: Theme.shared.activeCollection, event: .update)
			}
		}
	}

	var itemStyle: ThemeItemStyle {
		switch elementKind {
			case .smallTitle:
				return .system(textStyle: .footnote, weight: .regular)

			case .mediumTitle:
				return .system(textStyle: .subheadline, weight: .bold)

			default: // case .title:
				return .system(textStyle: .title3, weight: .bold)
		}
	}

	func updateCSSSelectors() {
		cssSelectors = [
			.sectionHeader,
			ThemeCSSSelector(rawValue: elementKind)
		]
	}

	var text: String? {
		didSet {
			var transformedText = text

			switch elementKind {
				case .mediumTitle, .smallTitle:
					transformedText = transformedText?.uppercased()

				default: break
			}

			label?.text = transformedText
		}
	}

	func configure() {
		label = UILabel()
		label?.translatesAutoresizingMaskIntoConstraints = false
		label?.accessibilityTraits = .header

		label?.setContentHuggingPriority(.required, for: .vertical)
		label?.setContentCompressionResistancePriority(.required, for: .vertical)

		if let label {
			addSubview(label)

			NSLayoutConstraint.activate([
				label.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 15),
				label.trailingAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.trailingAnchor, constant: -15),
				label.topAnchor.constraint(equalTo: topAnchor, constant: 15),
				label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3)
			])
		}

		updateCSSSelectors()
	}

	private var themeRegistered = false
	open override func didMoveToWindow() {
		super.didMoveToWindow()

		if !themeRegistered {
			// Postpone registration with theme until we actually need to. Makes sure self.applyThemeCollection() can take all properties into account
			Theme.shared.register(client: self, applyImmediately: true)
			themeRegistered = true
		}
	}

	// MARK: - Themeing
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		label?.applyThemeCollection(collection, itemStyle: itemStyle)
		backgroundColor = collection.css.getColor(.fill, for: self)
	}

	// MARK: - Prepare for reuse
	override func prepareForReuse() {
		super.prepareForReuse()
		label?.text = ""
	}

	// MARK: - Registration
	static func registerSupplementaryCellProvider() {
		let elementKinds: [CollectionViewSupplementaryItem.ElementKind] = [
			.title,
			.mediumTitle,
			.smallTitle
		]

		for elementKind in elementKinds {
			let supplementaryCellRegistration = UICollectionView.SupplementaryRegistration<TitleSupplementaryCell>(elementKind: elementKind) { supplementaryView, elementKind, indexPath in
				supplementaryView.elementKind = elementKind
			}

			CollectionViewSupplementaryCellProvider.register(CollectionViewSupplementaryCellProvider(for: elementKind, with: { collectionView, section, supplementaryItem, indexPath in
				let cellView = collectionView.dequeueConfiguredReusableSupplementary(using: supplementaryCellRegistration, for: indexPath)

				cellView.text = supplementaryItem.content as? String

				return cellView
			}))
		}
	}
}

public extension CollectionViewSupplementaryItem {
	static func title(_ title: String, elementKind: ElementKind, estimatedHeight: CGFloat, pinned: Bool) -> CollectionViewSupplementaryItem {
	        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(estimatedHeight))
		let supplementaryItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: elementKind, alignment: .top)

		if pinned {
			supplementaryItem.pinToVisibleBounds = true
			supplementaryItem.zIndex = 200
		}

		return CollectionViewSupplementaryItem(supplementaryItem: supplementaryItem, content: title)
	}

	static func title(_ title: String, pinned: Bool = false) -> CollectionViewSupplementaryItem {
		return .title(title, elementKind: .title, estimatedHeight: 24, pinned: pinned)
	}

	static func mediumTitle(_ title: String, pinned: Bool = false) -> CollectionViewSupplementaryItem {
		return .title(title, elementKind: .mediumTitle, estimatedHeight: 21, pinned: pinned)
	}

	static func smallTitle(_ title: String) -> CollectionViewSupplementaryItem {
		return .title(title, elementKind: .smallTitle, estimatedHeight: 19, pinned: false)
	}
}

extension ThemeCSSSelector {
	static let mediumTitle = ThemeCSSSelector(rawValue: CollectionViewSupplementaryItem.ElementKind.mediumTitle)
	static let smallTitle = ThemeCSSSelector(rawValue: CollectionViewSupplementaryItem.ElementKind.smallTitle)
}
