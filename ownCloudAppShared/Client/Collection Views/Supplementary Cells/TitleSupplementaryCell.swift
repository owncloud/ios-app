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

	func configure() {
		label = UILabel()
		label?.translatesAutoresizingMaskIntoConstraints = false

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

		Theme.shared.register(client: self, applyImmediately: true)
	}

	// MARK: - Themeing
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		label?.applyThemeCollection(collection, itemStyle: .system(textStyle: .title3, weight: .bold))
		backgroundColor = collection.tableBackgroundColor
	}

	// MARK: - Prepare for reuse
	override func prepareForReuse() {
		super.prepareForReuse()
		label?.text = ""
	}

	// MARK: - Registration
	static func registerSupplementaryCellProvider() {
		let supplementaryCellRegistration = UICollectionView.SupplementaryRegistration<TitleSupplementaryCell>(elementKind: CollectionViewSupplementaryItem.ElementKind.title) { supplementaryView, elementKind, indexPath in
		}

		CollectionViewSupplementaryCellProvider.register(CollectionViewSupplementaryCellProvider(for: .title, with: { collectionView, section, supplementaryItem, indexPath in
			let cellView = collectionView.dequeueConfiguredReusableSupplementary(using: supplementaryCellRegistration, for: indexPath)

			cellView.label?.text = supplementaryItem.content as? String

			return cellView
		}))
	}
}

public extension CollectionViewSupplementaryItem {
	static func title(_ title: String, pinned: Bool = false) -> CollectionViewSupplementaryItem {
	        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(30))
		let supplementaryItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: .title, alignment: .top)

		if pinned {
			supplementaryItem.pinToVisibleBounds = true
			supplementaryItem.zIndex = 2
		}

		return CollectionViewSupplementaryItem(supplementaryItem: supplementaryItem, content: title)
	}
}
