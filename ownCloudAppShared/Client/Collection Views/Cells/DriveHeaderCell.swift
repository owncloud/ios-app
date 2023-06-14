//
//  DriveHeaderCell.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 20.04.22.
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

class DriveHeaderCell: DriveListCell {
	let darkBackgroundView = UIView()

	var coverObservation : NSKeyValueObservation?
	var isRequestingCoverImage : Bool = true {
		didSet {
			recomputeHeight()
		}
	}

	weak var collectionViewController: CollectionViewController?
	var collectionItemRef: CollectionViewController.ItemRef?

	var coverImageHeightConstraint : NSLayoutConstraint?

	deinit {
		Theme.shared.unregister(client: self)
		coverObservation?.invalidate()
	}

	override func configure() {
		cssSelectors = [.header, .drive]

		darkBackgroundView.translatesAutoresizingMaskIntoConstraints = false
		darkBackgroundView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)

		contentView.clipsToBounds = true

		super.configure()

		titleLabel.font = UIFont.preferredFont(forTextStyle: .title1, with: .bold)
		titleLabel.makeLabelWrapText()

		subtitleLabel.font = UIFont.preferredFont(forTextStyle: .headline, with: .semibold)
		subtitleLabel.makeLabelWrapText()

		textOuterSpacing = 16

		coverImageResourceView.fallbackView = nil
		coverImageResourceView.cssSelector = .cover
		if let suggestedCellHeight {
			coverImageHeightConstraint = coverImageResourceView.heightAnchor.constraint(greaterThanOrEqualToConstant: suggestedCellHeight)
		}

		contentView.insertSubview(darkBackgroundView, belowSubview: titleLabel)

		coverObservation = coverImageResourceView.observe(\ResourceViewHost.contentStatus, options: [.initial], changeHandler: { [weak self] viewHost, _ in
			self?.darkBackgroundView.isHidden = (viewHost.contentStatus != .fromResource)
			self?.recomputeHeight()
		})
	}

	var suggestedCellHeight: CGFloat? {
		var newHeight : CGFloat = 160

		if !isRequestingCoverImage && (coverImageResourceView.contentStatus == .none) {
			newHeight = 80
		}

		return newHeight
	}

	func recomputeHeight() {
		if let newHeight = suggestedCellHeight, let constantHeight = coverImageHeightConstraint?.constant, constantHeight != newHeight {
			coverImageHeightConstraint?.constant = newHeight

			if let collectionViewController = collectionViewController, let collectionItemRef = collectionItemRef {
				collectionViewController.performDataSourceUpdate(with: { updateDone in
					collectionViewController.collectionViewDataSource.requestReconfigurationOfItems([collectionItemRef], animated: false)
					updateDone()
				})
			}
		}
	}

	override func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection, state: ThemeItemState) {
		coverImageResourceView.backgroundColor = collection.css.getColor(.fill, for: coverImageResourceView)

		// Different look (unified with navigation bar, problematic in light mode):
		// coverImageResourceView.backgroundColor = collection.navigationBarColors.backgroundColor

		titleLabel.textColor = .white
		subtitleLabel.textColor = .white
	}

	override func configureLayout() {
		var constraints = [
			coverImageResourceView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
			coverImageResourceView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
			coverImageResourceView.topAnchor.constraint(equalTo: contentView.topAnchor),
			coverImageResourceView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

			titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: textOuterSpacing),

			titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: textOuterSpacing),
			titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -textOuterSpacing).with(priority: .defaultHigh), // make constraint "overridable" for DriveGridCell subclass
			titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -textInterSpacing),

			subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: textOuterSpacing),
			subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -textOuterSpacing).with(priority: .defaultHigh), // make constraint "overridable" for DriveGridCell subclass
			subtitleLabel.bottomAnchor.constraint(equalTo: coverImageResourceView.bottomAnchor, constant: -textOuterSpacing),

			darkBackgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
			darkBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
			darkBackgroundView.topAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -textOuterSpacing),
			darkBackgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
		]

		if let coverImageHeightConstraint {
			constraints.append(coverImageHeightConstraint)
		}

		NSLayoutConstraint.activate(constraints)
	}
}

extension ThemeCSSSelector {
	static let drive = ThemeCSSSelector(rawValue: "drive")
	static let cover = ThemeCSSSelector(rawValue: "cover")
}
