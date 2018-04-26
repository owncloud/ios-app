//
//  ClientItemCell.swift
//  ownCloud
//
//  Created by Felix Schwarz on 13.04.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2018, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

class ClientItemCell: ThemeTableViewCell {
	var titleLabel : UILabel = UILabel()
	var detailLabel : UILabel = UILabel()
	var iconView : UIImageView = UIImageView()

	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		prepareViewAndConstraints()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	func prepareViewAndConstraints() {
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		detailLabel.translatesAutoresizingMaskIntoConstraints = false
		iconView.translatesAutoresizingMaskIntoConstraints = false
		iconView.contentMode = .scaleAspectFit

		titleLabel.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.semibold)
		detailLabel.font = UIFont.systemFont(ofSize: 14)

		detailLabel.textColor = UIColor.gray

		self.contentView.addSubview(titleLabel)
		self.contentView.addSubview(detailLabel)
		self.contentView.addSubview(iconView)

		iconView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 20).isActive = true
		iconView.rightAnchor.constraint(equalTo: titleLabel.leftAnchor, constant: -25).isActive = true
		iconView.rightAnchor.constraint(equalTo: detailLabel.leftAnchor, constant: -25).isActive = true

		titleLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -20).isActive = true
		detailLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -20).isActive = true

		iconView.widthAnchor.constraint(equalToConstant: 40).isActive = true
		iconView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true

		titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 20).isActive = true
		titleLabel.bottomAnchor.constraint(equalTo: detailLabel.topAnchor, constant: -5).isActive = true
		detailLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -20).isActive = true

		iconView.setContentHuggingPriority(UILayoutPriority.required, for: UILayoutConstraintAxis.vertical)
		titleLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: UILayoutConstraintAxis.vertical)
		detailLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: UILayoutConstraintAxis.vertical)
	}

	// MARK: - Present item
	var item : OCItem? {
		willSet {
			if let item: OCItem = newValue {
				updateWith(item)
			}
		}
	}

	func updateWith(_ item: OCItem) {
		let iconSize : CGSize = CGSize(width: 40, height: 40)
		var iconImage : UIImage?

		iconImage = item.icon(fitInSize: iconSize)

		if item.type == .collection {
			self.detailLabel.text = "Folder".localized
			self.accessoryType = .disclosureIndicator
		} else {
			self.detailLabel.text = item.mimeType
			self.accessoryType = .none
		}

		self.iconView.image = iconImage
		self.titleLabel.text = item.name
	}

	// MARK: - Themeing
	override func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection) {
		let itemState = ThemeItemState.init(selected: self.isSelected)

		self.titleLabel.applyThemeCollection(collection, itemStyle: .title, itemState: itemState)
		self.detailLabel.applyThemeCollection(collection, itemStyle: .message, itemState: itemState)
	}
}
