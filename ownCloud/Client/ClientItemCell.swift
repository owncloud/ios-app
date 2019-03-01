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
	private let horizontalMargin : CGFloat = 20.0
	private let horizontalSmallMargin : CGFloat = 10.0
	private let spacing : CGFloat = 15.0
	private let moreButtonWidth : CGFloat = 60.0

	weak var delegate: ClientItemCellDelegate?

	var titleLabel : UILabel = UILabel()
	var detailLabel : UILabel = UILabel()
	var iconView : UIImageView = UIImageView()
	var cloudStatusIconView : UIImageView = UIImageView()
	var moreButton : UIButton = UIButton()
	var progressView : ProgressView?

	var moreButtonWidthConstraint : NSLayoutConstraint?

	var activeThumbnailRequestProgress : Progress?

	weak var core : OCCore?

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		prepareViewAndConstraints()
		self.multipleSelectionBackgroundView = {
			let blankView = UIView(frame: CGRect.zero)
			blankView.backgroundColor = UIColor.clear
			blankView.layer.masksToBounds = true
			return blankView
		}()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	deinit {
		self.localID = nil
	}

	func prepareViewAndConstraints() {
		titleLabel.translatesAutoresizingMaskIntoConstraints = false

		detailLabel.translatesAutoresizingMaskIntoConstraints = false

		iconView.translatesAutoresizingMaskIntoConstraints = false
		iconView.contentMode = .scaleAspectFit

		moreButton.translatesAutoresizingMaskIntoConstraints = false

		cloudStatusIconView.translatesAutoresizingMaskIntoConstraints = false
		cloudStatusIconView.contentMode = .center

		titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
		titleLabel.adjustsFontForContentSizeCategory = true

		detailLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
		detailLabel.adjustsFontForContentSizeCategory = true

		self.contentView.addSubview(titleLabel)
		self.contentView.addSubview(detailLabel)
		self.contentView.addSubview(iconView)
		self.contentView.addSubview(cloudStatusIconView)
		self.contentView.addSubview(moreButton)

		moreButton.setAttributedTitle(NSAttributedString(string: "● ● ●", attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)]), for: .normal)
		moreButton.titleLabel?.adjustsFontForContentSizeCategory = true
		moreButton.contentMode = .scaleToFill

		moreButton.contentEdgeInsets.left = -horizontalMargin
		moreButton.titleEdgeInsets.right = horizontalSmallMargin
		moreButton.titleEdgeInsets.left = spacing
		moreButton.contentEdgeInsets.right = -spacing

		moreButton.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)

		cloudStatusIconView.setContentHuggingPriority(.required, for: .vertical)
		cloudStatusIconView.setContentHuggingPriority(.required, for: .horizontal)
		cloudStatusIconView.setContentCompressionResistancePriority(.required, for: .vertical)
		cloudStatusIconView.setContentCompressionResistancePriority(.required, for: .horizontal)

		iconView.setContentHuggingPriority(.required, for: .vertical)
		titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
		detailLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
		moreButton.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)

		moreButtonWidthConstraint = moreButton.widthAnchor.constraint(equalToConstant: moreButtonWidth)

		NSLayoutConstraint.activate([
			iconView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: horizontalMargin),
			iconView.rightAnchor.constraint(equalTo: titleLabel.leftAnchor, constant: -spacing),
			iconView.rightAnchor.constraint(equalTo: detailLabel.leftAnchor, constant: -spacing),

			moreButton.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
			moreButton.topAnchor.constraint(equalTo: self.contentView.topAnchor),
			moreButton.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
			moreButtonWidthConstraint!,
			moreButton.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),

			cloudStatusIconView.rightAnchor.constraint(lessThanOrEqualTo: moreButton.leftAnchor, constant: -horizontalSmallMargin),
			cloudStatusIconView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor, constant: 0),

			titleLabel.rightAnchor.constraint(equalTo: cloudStatusIconView.leftAnchor, constant: -horizontalSmallMargin),
			detailLabel.rightAnchor.constraint(equalTo: moreButton.leftAnchor, constant: -horizontalMargin),

			iconView.widthAnchor.constraint(equalToConstant: 60),
			iconView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
			iconView.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor, constant: 10),
			iconView.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -10),

			titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: horizontalMargin),
			titleLabel.bottomAnchor.constraint(equalTo: detailLabel.topAnchor, constant: -5),
			detailLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -horizontalMargin)
		])
	}

	// MARK: - Present item
	var item : OCItem? {
		didSet {
			if let newItem = item {
				updateWith(newItem)
			}

			localID = item?.localID as NSString?
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

		var size: String = item.sizeLocalized

		if item.size < 0 {
			size = "Pending".localized
		}

		self.detailLabel.text = size + " - " + item.lastModifiedLocalized

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

		if item.type == .file {
			switch item.cloudStatus {
				case .cloudOnly:
					cloudStatusIconView.image = UIImage(named: "cloud-only")

				case .localCopy:
					cloudStatusIconView.image = nil

				case .locallyModified, .localOnly:
					cloudStatusIconView.image = UIImage(named: "cloud-local-only")
			}
		} else {
			cloudStatusIconView.image = nil
		}

		self.iconView.image = iconImage
		self.titleLabel.text = item.name

		self.iconView.alpha = item.isPlaceholder ? 0.5 : 1.0
		self.moreButton.isHidden = (item.isPlaceholder || (progressView != nil)) ? true : false

		self.moreButton.accessibilityLabel = item.name! + " " + "Actions".localized

		self.updateProgress()
	}

	// MARK: - Progress
	var localID : OCLocalID? {
		willSet {
			if localID != nil {
				NotificationCenter.default.removeObserver(self, name: .OCCoreItemChangedProgress, object: nil)
			}
		}

		didSet {
			if localID != nil {
			        NotificationCenter.default.addObserver(self, selector: #selector(progressChangedForItem(_:)), name: .OCCoreItemChangedProgress, object: nil)
			}
		}
	}

	@objc func progressChangedForItem(_ notification : Notification) {
		if notification.object as? NSString == localID {
			OnMainThread {
				self.updateProgress()
			}
		}
	}

	func updateProgress() {
		var progress : Progress?

		if let item = item {
			progress = self.core?.progress(for: item, matching: .none)?.first
		}

		if progress == nil, let item = item, (item.syncActivity.rawValue & (OCItemSyncActivity.downloading.rawValue | OCItemSyncActivity.uploading.rawValue) != 0) {
			progress = Progress.indeterminate()
		}

		if progress != nil {
			if progressView == nil {
				let progressView = ProgressView()
				progressView.translatesAutoresizingMaskIntoConstraints = false

				self.contentView.addSubview(progressView)

				NSLayoutConstraint.activate([
					progressView.leftAnchor.constraint(equalTo: moreButton.leftAnchor),
					progressView.rightAnchor.constraint(equalTo: moreButton.rightAnchor),
					progressView.topAnchor.constraint(equalTo: moreButton.topAnchor),
					progressView.bottomAnchor.constraint(equalTo: moreButton.bottomAnchor)
				])

				self.progressView = progressView
			}

			self.progressView?.progress = progress

			moreButton.isHidden = true
		} else {
			moreButton.isHidden = false
			progressView?.removeFromSuperview()
			progressView = nil
		}
	}

	// MARK: - Themeing
	override func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection) {
		let itemState = ThemeItemState(selected: self.isSelected)

		titleLabel.applyThemeCollection(collection, itemStyle: .title, itemState: itemState)
		detailLabel.applyThemeCollection(collection, itemStyle: .message, itemState: itemState)

		cloudStatusIconView.tintColor = collection.tableRowColors.secondaryLabelColor
		detailLabel.textColor = collection.tableRowColors.secondaryLabelColor

		let moreTitle: NSMutableAttributedString = NSMutableAttributedString(attributedString: self.moreButton.attributedTitle(for: .normal)!)
		moreTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: collection.tableRowColors.labelColor, range: NSRange(location:0, length:moreTitle.length))
		self.moreButton.setAttributedTitle(moreTitle, for: .normal)
	}

	// MARK: - Editing mode
	func setMoreButton(hidden:Bool, animated: Bool = false) {
		if hidden {
			moreButtonWidthConstraint?.constant = 0
		} else {
			moreButtonWidthConstraint?.constant = moreButtonWidth
		}
		moreButton.isHidden = ((item?.isPlaceholder == true) || (progressView != nil)) ? true : hidden
		if animated {
			UIView.animate(withDuration: 0.25) {
				self.contentView.layoutIfNeeded()
			}
		} else {
			self.contentView.layoutIfNeeded()
		}
	}

	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)

		setMoreButton(hidden: editing, animated: animated)
	}

	// MARK: - Actions
	@objc func moreButtonTapped() {
		self.delegate?.moreButtonTapped(cell: self)
	}
}
