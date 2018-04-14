//
//  ClientItemCell.swift
//  ownCloud
//
//  Created by Felix Schwarz on 13.04.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

class ClientItemCell: UITableViewCell, Themeable {
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

		Theme.shared.register(client: self, applyImmediately: true)
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.titleLabel.textColor = collection.tableRowColorBarCollection.labelColor
		self.detailLabel.textColor = collection.tableRowColorBarCollection.secondaryLabelColor
		self.backgroundColor = collection.tableRowColorBarCollection.backgroundColor
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)

		// Configure the view for the selected state
	}

	var _item : OCItem?
	var item : OCItem? {
		set(newItem) {
			_item = newItem

			if let item : OCItem = _item {
				updateWith(item)
			}
		}

		get {
			return _item
		}
	}

	func updateWith(_ item: OCItem) {
		let iconSize : CGSize = CGSize(width: 40, height: 40)
		var iconImage : UIImage?

		iconImage = item.icon(fitInSize: iconSize)

		if item.type == .collection {
			self.detailLabel.text = "Folder"
		} else {
			self.detailLabel.text = item.mimeType
		}

		self.iconView.image = iconImage
		self.titleLabel.text = item.name

		if item.type == .collection {
			self.accessoryType = .disclosureIndicator
		} else {
			self.accessoryType = .none
		}
	}
}
