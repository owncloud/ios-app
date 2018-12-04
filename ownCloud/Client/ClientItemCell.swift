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

protocol ClientItemCellDelegate: class {

	func moreButtonTapped(cell: ClientItemCell)

}

class ClientItemCell: ThemeTableViewCell {

	weak var delegate: ClientItemCellDelegate?

	var titleLabel : UILabel = UILabel()
	var detailLabel : UILabel = UILabel()
	var iconView : UIImageView = UIImageView()
	var moreButton: UIButton = UIButton()

	var activeThumbnailRequestProgress : Progress?

	weak var core : OCCore?

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
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
		moreButton.translatesAutoresizingMaskIntoConstraints = false

		titleLabel.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.semibold)
		detailLabel.font = UIFont.systemFont(ofSize: 14)

		detailLabel.textColor = UIColor.gray

		self.contentView.addSubview(titleLabel)
		self.contentView.addSubview(detailLabel)
		self.contentView.addSubview(iconView)
		self.contentView.addSubview(moreButton)

		iconView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 20).isActive = true
		iconView.rightAnchor.constraint(equalTo: titleLabel.leftAnchor, constant: -15).isActive = true
		iconView.rightAnchor.constraint(equalTo: detailLabel.leftAnchor, constant: -15).isActive = true

		moreButton.setAttributedTitle(NSAttributedString(string: "● ● ●", attributes:
			[NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10)]), for: .normal)

		moreButton.contentMode = .scaleToFill

		moreButton.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
		moreButton.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
		moreButton.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
		moreButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
		moreButton.rightAnchor.constraint(equalTo: self.contentView.rightAnchor).isActive = true
		moreButton.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)

		moreButton.contentEdgeInsets.left = -20
		moreButton.titleEdgeInsets.right = 10
		moreButton.titleEdgeInsets.left = 15
		moreButton.contentEdgeInsets.right = -15

		titleLabel.rightAnchor.constraint(equalTo: moreButton.leftAnchor, constant: -20).isActive = true
		detailLabel.rightAnchor.constraint(equalTo: moreButton.leftAnchor, constant: -20).isActive = true

		iconView.widthAnchor.constraint(equalToConstant: 60).isActive = true
		iconView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true

		titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 20).isActive = true
		titleLabel.bottomAnchor.constraint(equalTo: detailLabel.topAnchor, constant: -5).isActive = true
		detailLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -20).isActive = true

		iconView.setContentHuggingPriority(UILayoutPriority.required, for: NSLayoutConstraint.Axis.vertical)
		titleLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: NSLayoutConstraint.Axis.vertical)
		detailLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: NSLayoutConstraint.Axis.vertical)
		moreButton.setContentHuggingPriority(UILayoutPriority.required, for: NSLayoutConstraint.Axis.horizontal)

		NSLayoutConstraint.activate([
			iconView.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor, constant: 10),
			iconView.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -10)
		])
	}

	// MARK: - Present item
	var item : OCItem? {
		didSet {
			if let newItem: OCItem = item {
				updateWith(newItem)
			}
		}
	}

	func updateWith(_ item: OCItem) {
		let iconSize : CGSize = CGSize(width: 40, height: 40)
		let thumbnailSize : CGSize = CGSize(width: 60, height: 60)
		var iconImage : UIImage?

		// Cancel any already active request
		if activeThumbnailRequestProgress != nil {
			activeThumbnailRequestProgress?.cancel()
		}

		iconImage = item.icon(fitInSize: iconSize)

		var size: String = item.sizeInReadableFormat

		if item.size < 0 {
			size = "Pending".localized
		}

		self.detailLabel.text = size + " - " + item.lastModifiedInReadableFormat

		self.accessoryType = .none

		if item.thumbnailAvailability != .none {
			let displayThumbnail = { (thumbnail: OCItemThumbnail?) in
				_ = thumbnail?.requestImage(for: thumbnailSize, scale: 0, withCompletionHandler: { (thumbnail, error, _, image) in
					if error == nil,
					   image != nil,
					   self.item?.itemVersionIdentifier == thumbnail?.itemVersionIdentifier {
						OnMainThread {
							self.iconView.image = image
						}
					}
				})
			}

			if let thumbnail = item.thumbnail {
				displayThumbnail(thumbnail)
			} else {
				activeThumbnailRequestProgress = core?.retrieveThumbnail(for: item, maximumSize: thumbnailSize, scale: 0, retrieveHandler: { [weak self] (_, _, _, thumbnail, _, progress) in
					displayThumbnail(thumbnail)

					if self?.activeThumbnailRequestProgress === progress {
						self?.activeThumbnailRequestProgress = nil
					}
				})
			}
		}

		self.iconView.image = iconImage
		self.titleLabel.text = item.name

		self.iconView.alpha = item.isPlaceholder ? 0.5 : 1.0
		self.moreButton.isHidden = item.isPlaceholder ? true : false
	}

	// MARK: - Themeing
	override func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection) {
		let itemState = ThemeItemState(selected: self.isSelected)

		self.titleLabel.applyThemeCollection(collection, itemStyle: .title, itemState: itemState)
		self.detailLabel.applyThemeCollection(collection, itemStyle: .message, itemState: itemState)

		let moreTitle: NSMutableAttributedString = NSMutableAttributedString(attributedString: self.moreButton.attributedTitle(for: .normal)!)
		moreTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: collection.tableRowColors.labelColor, range: NSRange(location:0, length:moreTitle.length))
		self.moreButton.setAttributedTitle(moreTitle, for: .normal)
	}

	// MARK: - Actions
	@objc func moreButtonTapped() {
		self.delegate?.moreButtonTapped(cell: self)
	}
}
