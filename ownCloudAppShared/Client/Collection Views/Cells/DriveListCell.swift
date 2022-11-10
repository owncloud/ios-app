//
//  DriveCell.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 14.04.22.
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

class DriveListCell: ThemeableCollectionViewListCell {
	let coverImageResourceView = ResourceViewHost()
	let spaceFallbackImageView = UIImageView()

	let titleLabel = UILabel()
	let subtitleLabel = UILabel()

	override init(frame: CGRect) {
		super.init(frame: frame)
		configure()
		configureLayout()
	}

	required init?(coder: NSCoder) {
		fatalError()
	}

	var textOuterSpacing : CGFloat = 10
	var textInterSpacing : CGFloat = 5

	var title : String? {
		didSet {
			titleLabel.text = title
		}
	}
	var subtitle : String? {
		didSet {
			subtitleLabel.text = subtitle
		}
	}

	func configure() {
		coverImageResourceView.translatesAutoresizingMaskIntoConstraints = false
		spaceFallbackImageView.translatesAutoresizingMaskIntoConstraints = false

		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

		contentView.addSubview(coverImageResourceView)
		contentView.addSubview(titleLabel)
		contentView.addSubview(subtitleLabel)

		let configuration = UIImage.SymbolConfiguration(hierarchicalColor: .lightGray)

		spaceFallbackImageView.image = UIImage(systemName: "rectangle.grid.2x2.fill", withConfiguration: configuration)?.withAlignmentRectInsets(UIEdgeInsets(top: -textOuterSpacing*2, left: -textOuterSpacing*2, bottom: -textOuterSpacing*2, right: -textOuterSpacing*2)).withTintColor(.darkGray)
		spaceFallbackImageView.contentMode = .scaleAspectFill

		coverImageResourceView.backgroundColor = .lightGray
		coverImageResourceView.fallbackView = spaceFallbackImageView
		coverImageResourceView.viewProviderContext = OCViewProviderContext(attributes: [.contentMode : UIView.ContentMode.scaleAspectFill.rawValue ])

		titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
		titleLabel.adjustsFontForContentSizeCategory = true
		titleLabel.textColor = UIColor.label
		subtitleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
		subtitleLabel.adjustsFontForContentSizeCategory = true
		subtitleLabel.textColor = UIColor.secondaryLabel

		titleLabel.setContentHuggingPriority(.required, for: .vertical)
		subtitleLabel.setContentHuggingPriority(.required, for: .vertical)

		coverImageResourceView.backgroundColor = .white
	}

	func configureLayout() {
		NSLayoutConstraint.activate([
			coverImageResourceView.widthAnchor.constraint(equalToConstant: 64),

			coverImageResourceView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
			coverImageResourceView.topAnchor.constraint(equalTo: contentView.topAnchor),
			coverImageResourceView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

			titleLabel.leadingAnchor.constraint(equalTo: coverImageResourceView.trailingAnchor, constant: textOuterSpacing),
			titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -textOuterSpacing),
			titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: textOuterSpacing),
			titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -textInterSpacing),

			subtitleLabel.leadingAnchor.constraint(equalTo: coverImageResourceView.trailingAnchor, constant: textOuterSpacing),
			subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -textOuterSpacing),
			subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -textOuterSpacing),

			separatorLayoutGuide.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor)
		])
	}

//	func updateWith(item: OCDataItem?, cellConfiguration: CollectionViewCellConfiguration?) {
//		var coverImageRequest : OCResourceRequest?
//
//		if let item = item,
//		   let cellConfiguration = cellConfiguration,
//		   let presentable = OCDataRenderer.default.renderItem(item, asType: .presentable, error: nil, withOptions: nil) as? OCDataItemPresentable {
//			title = presentable.title
//			subtitle = presentable.subtitle
//
//			if let resourceManager = cellConfiguration.core?.vault.resourceManager {
//				coverImageRequest = try? presentable.provideResourceRequest(.coverImage, withOptions: nil)
//			}
//		}
//	}
}

extension DriveListCell {
	static func registerCellProvider() {
		let driveListCellRegistration = UICollectionView.CellRegistration<DriveListCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			var coverImageRequest : OCResourceRequest?
			var resourceManager : OCResourceManager?
			var title : String?
			var subtitle : String?

			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let presentable = OCDataRenderer.default.renderItem(item, asType: .presentable, error: nil, withOptions: nil) as? OCDataItemPresentable {
					title = presentable.title
					subtitle = presentable.subtitle

					resourceManager = cellConfiguration.core?.vault.resourceManager

					coverImageRequest = try? presentable.provideResourceRequest(.coverImage, withOptions: nil)
				}
			})

			cell.title = title
			cell.subtitle = subtitle

			cell.coverImageResourceView.request = coverImageRequest

			if let coverImageRequest = coverImageRequest {
				resourceManager?.start(coverImageRequest)
			}

			cell.accessories = [ .disclosureIndicator() ]
		}

		let driveHeaderCellRegistration = UICollectionView.CellRegistration<DriveHeaderCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			var coverImageRequest : OCResourceRequest?
			var resourceManager : OCResourceManager?
			var title : String?
			var subtitle : String?

			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let presentable = OCDataRenderer.default.renderItem(item, asType: .presentable, error: nil, withOptions: nil) as? OCDataItemPresentable {
					title = presentable.title
					subtitle = presentable.subtitle

					resourceManager = cellConfiguration.core?.vault.resourceManager

					coverImageRequest = try? presentable.provideResourceRequest(.coverImage, withOptions: nil)
				}
			})

			cell.title = title
			cell.subtitle = subtitle

			cell.coverImageResourceView.request = coverImageRequest
			cell.isRequestingCoverImage = (coverImageRequest != nil)

			cell.collectionItemRef = collectionItemRef
			cell.collectionViewController = collectionItemRef.ocCellConfiguration?.hostViewController

			if let coverImageRequest = coverImageRequest {
				resourceManager?.start(coverImageRequest)
			}
		}

		let driveSideBarCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			var title : String?
			// var subtitle : String?

			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let presentable = OCDataRenderer.default.renderItem(item, asType: .presentable, error: nil, withOptions: nil) as? OCDataItemPresentable {
					title = presentable.title
					// subtitle = presentable.subtitle
				}
			})

			var content = cell.defaultContentConfiguration()

			content.text = title
			content.image = UIImage(systemName: "square.grid.2x2")

			cell.contentConfiguration = content
		}

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .drive, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			switch cellConfiguration?.style.type {
				case .header:
					return collectionView.dequeueConfiguredReusableCell(using: driveHeaderCellRegistration, for: indexPath, item: itemRef)

				case .sideBar:
					return collectionView.dequeueConfiguredReusableCell(using: driveSideBarCellRegistration, for: indexPath, item: itemRef)

				default:
					return collectionView.dequeueConfiguredReusableCell(using: driveListCellRegistration, for: indexPath, item: itemRef)
			}
		}))
	}
}
