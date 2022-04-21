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

class DriveListCell: UICollectionViewListCell {
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

			if let cellConfiguration = collectionItemRef.ocCellConfiguration {
				var itemRecord = cellConfiguration.record

				resourceManager = cellConfiguration.core?.vault.resourceManager

				if itemRecord == nil {
					if let collectionViewController = cellConfiguration.hostViewController {
						let (itemRef, _) = collectionViewController.unwrap(collectionItemRef)

						if let retrievedItemRecord = try? cellConfiguration.source?.record(forItemRef: itemRef) {
							itemRecord = retrievedItemRecord
						}
					}
				}

				if let itemRecord = itemRecord {
					if let item = itemRecord.item {
						if let presentable = OCDataRenderer.default.renderItem(item, asType: .presentable, error: nil, withOptions: nil) as? OCDataItemPresentable {

							title = presentable.title
							subtitle = presentable.subtitle

							coverImageRequest = try? presentable.provideResourceRequest(.coverImage, withOptions: nil)
						}
					} else {
						// Request reconfiguration of cell
						itemRecord.retrieveItem(completionHandler: { error, itemRecord in
							if let collectionViewController = cellConfiguration.hostViewController {
								collectionViewController.collectionViewDataSource.requestReconfigurationOfItems([collectionItemRef])
							}
						})
					}
				}
			}

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

			if let cellConfiguration = collectionItemRef.ocCellConfiguration {
				var itemRecord = cellConfiguration.record

				cell.collectionViewController = cellConfiguration.hostViewController

				resourceManager = cellConfiguration.core?.vault.resourceManager

				if itemRecord == nil {
					if let collectionViewController = cellConfiguration.hostViewController {
						let (itemRef, _) = collectionViewController.unwrap(collectionItemRef)

						if let retrievedItemRecord = try? cellConfiguration.source?.record(forItemRef: itemRef) {
							itemRecord = retrievedItemRecord
						}
					}
				}

				if let itemRecord = itemRecord {
					if let item = itemRecord.item {
						if let presentable = OCDataRenderer.default.renderItem(item, asType: .presentable, error: nil, withOptions: nil) as? OCDataItemPresentable {

							title = presentable.title
							subtitle = presentable.subtitle

							coverImageRequest = try? presentable.provideResourceRequest(.coverImage, withOptions: nil)
						}
					} else {
						// Request reconfiguration of cell
						itemRecord.retrieveItem(completionHandler: { error, itemRecord in
							if let collectionViewController = cellConfiguration.hostViewController {
								collectionViewController.collectionViewDataSource.requestReconfigurationOfItems([collectionItemRef])
							}
						})
					}
				}
			}

			cell.title = title
			cell.subtitle = subtitle

			cell.coverImageResourceView.request = coverImageRequest

			if let coverImageRequest = coverImageRequest {
				resourceManager?.start(coverImageRequest)
			}
		}

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .drive, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			if cellConfiguration?.style == .header {
				return collectionView.dequeueConfiguredReusableCell(using: driveHeaderCellRegistration, for: indexPath, item: itemRef)
			} else {
				return collectionView.dequeueConfiguredReusableCell(using: driveListCellRegistration, for: indexPath, item: itemRef)
			}
		}))
	}
}
