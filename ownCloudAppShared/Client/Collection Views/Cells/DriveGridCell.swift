//
//  DriveGridCell.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 29.11.22.
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

class DriveGridCell: DriveHeaderCell {
	var moreButton: UIButton = UIButton()
	var moreAction: OCAction? {
		didSet {
			moreButton.isHidden = (moreAction == nil)
		}
	}

	override var suggestedCellHeight: CGFloat? {
		return nil
	}

	override func configure() {
		super.configure()

		contentView.layer.cornerRadius = 8
		titleLabel.numberOfLines = 1
		titleLabel.lineBreakMode = .byTruncatingTail
		subtitleLabel.numberOfLines = 1
		subtitleLabel.lineBreakMode = .byTruncatingTail

		let symbolConfig = UIImage.SymbolConfiguration(pointSize: 10)
		var buttonConfig = UIButton.Configuration.filled()
		buttonConfig.image = UIImage(systemName: "ellipsis", withConfiguration: symbolConfig)
		buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
		buttonConfig.buttonSize = .mini
		buttonConfig.cornerStyle = .capsule

		moreButton.configuration = buttonConfig
		moreButton.translatesAutoresizingMaskIntoConstraints = false
		moreButton.addAction(UIAction(handler: { [weak self] _ in
			self?.moreAction?.run()
		}), for: .primaryActionTriggered)
		moreButton.isHidden = true

		contentView.addSubview(moreButton)
	}

	override func configureLayout() {
		super.configureLayout()

		moreButton.setContentHuggingPriority(.required, for: .horizontal)

		NSLayoutConstraint.activate([
			titleLabel.centerYAnchor.constraint(equalTo: moreButton.centerYAnchor),
			titleLabel.trailingAnchor.constraint(equalTo: moreButton.leadingAnchor, constant: -10),
			moreButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10)
		])
	}

	override var subtitle: String? {
		didSet {
			subtitleLabel.text = subtitle ?? " " // Ensure the grid cells' titles align by always showing a subtitle - if necessary, an empty one
		}
	}

	override func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection, state: ThemeItemState) {
		super.applyThemeCollectionToCellContents(theme: theme, collection: collection, state: state)

		moreButton.apply(css: collection.css, properties: [.stroke, .fill])
	}
}
