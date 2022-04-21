//
//  DriveHeaderCell.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 20.04.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

import UIKit

class DriveHeaderCell: DriveListCell, Themeable {
	let darkBackgroundView = UIView()

	weak var collectionViewController : CollectionViewController?

	deinit {
		Theme.shared.unregister(client: self)
	}

	override func configure() {
		darkBackgroundView.translatesAutoresizingMaskIntoConstraints = false
		darkBackgroundView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)

		contentView.clipsToBounds = true

		super.configure()

		titleLabel.font = UIFont.preferredFont(forTextStyle: .title1, with: .bold)
		titleLabel.makeLabelWrapText()

		subtitleLabel.font = UIFont.preferredFont(forTextStyle: .headline, with: .semibold)
		subtitleLabel.makeLabelWrapText()

		textOuterSpacing = 20

		coverImageResourceView.fallbackView = nil

		contentView.insertSubview(darkBackgroundView, belowSubview: titleLabel)

		Theme.shared.register(client: self, applyImmediately: true)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		coverImageResourceView.backgroundColor = collection.lightBrandColor

		titleLabel.textColor = .white
		subtitleLabel.textColor = .white
	}

	override func configureLayout() {
		coverImageHeightConstraint = coverImageResourceView.heightAnchor.constraint(greaterThanOrEqualToConstant: 160)

		NSLayoutConstraint.activate([
			coverImageHeightConstraint!,

			coverImageResourceView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
			coverImageResourceView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
			coverImageResourceView.topAnchor.constraint(equalTo: contentView.topAnchor),
			coverImageResourceView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

			titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: textOuterSpacing),

			titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: textOuterSpacing),
			titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -textOuterSpacing),
			titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -textInterSpacing),

			subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: textOuterSpacing),
			subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -textOuterSpacing),
			subtitleLabel.bottomAnchor.constraint(equalTo: coverImageResourceView.bottomAnchor, constant: -textOuterSpacing),

			darkBackgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
			darkBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
			darkBackgroundView.topAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -textOuterSpacing),
			darkBackgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
		])
	}

	var coverImageHeightConstraint : NSLayoutConstraint?

	@objc func growHeight() {
		coverImageHeightConstraint?.constant += 64
	}
}
