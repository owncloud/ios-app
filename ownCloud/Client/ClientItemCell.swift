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
import QuickLookThumbnailing

protocol ClientItemCellDelegate: class {

	func moreButtonTapped(cell: ClientItemCell)

}

class ClientItemCell: ThemeTableViewCell {
	private let horizontalMargin : CGFloat = 15
	private let verticalLabelMargin : CGFloat = 15
	private let verticalIconMargin : CGFloat = 15
	private let horizontalSmallMargin : CGFloat = 10
	private let spacing : CGFloat = 15
	private let iconViewWidth : CGFloat = 60
	private let moreButtonWidth : CGFloat = 60
	private let verticalLabelMarginFromCenter : CGFloat = 2

	weak var delegate: ClientItemCellDelegate?

	var titleLabel : UILabel = UILabel()
	var detailLabel : UILabel = UILabel()
	var iconView : UIImageView = UIImageView()
	var cloudStatusIconView : UIImageView = UIImageView()
	var sharedStatusIconView : UIImageView = UIImageView()
	var publicLinkStatusIconView : UIImageView = UIImageView()
	var moreButton : UIButton = UIButton()
	var progressView : ProgressView?

	var moreButtonWidthConstraint : NSLayoutConstraint?
	var sharedStatusIconViewRightMarginConstraint : NSLayoutConstraint?
	var publicLinkStatusIconViewRightMarginConstraint : NSLayoutConstraint?

	var activeThumbnailRequestProgress : Progress?

	var isMoreButtonPermanentlyHidden = false {
		didSet {
			if isMoreButtonPermanentlyHidden {
				moreButtonWidthConstraint?.constant = 0
			} else {
				moreButtonWidthConstraint?.constant = moreButtonWidth
			}
		}
	}

	var isActive = true {
		didSet {
			let alpha : CGFloat = self.isActive ? 1.0 : 0.5
			titleLabel.alpha = alpha
			detailLabel.alpha = alpha
			iconView.alpha = alpha
			cloudStatusIconView.alpha = alpha
		}
	}

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

		sharedStatusIconView.translatesAutoresizingMaskIntoConstraints = false
		sharedStatusIconView.contentMode = .center

		publicLinkStatusIconView.translatesAutoresizingMaskIntoConstraints = false
		publicLinkStatusIconView.contentMode = .center

		titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
		titleLabel.adjustsFontForContentSizeCategory = true

		detailLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
		detailLabel.adjustsFontForContentSizeCategory = true

		self.contentView.addSubview(titleLabel)
		self.contentView.addSubview(detailLabel)
		self.contentView.addSubview(iconView)
		self.contentView.addSubview(sharedStatusIconView)
		self.contentView.addSubview(publicLinkStatusIconView)
		self.contentView.addSubview(cloudStatusIconView)
		self.contentView.addSubview(moreButton)

		moreButton.setImage(UIImage(named: "more-dots"), for: .normal)
		moreButton.contentMode = .center

		moreButton.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)

		sharedStatusIconView.setContentHuggingPriority(.required, for: .vertical)
		sharedStatusIconView.setContentHuggingPriority(.required, for: .horizontal)
		sharedStatusIconView.setContentCompressionResistancePriority(.required, for: .vertical)
		sharedStatusIconView.setContentCompressionResistancePriority(.required, for: .horizontal)

		publicLinkStatusIconView.setContentHuggingPriority(.required, for: .vertical)
		publicLinkStatusIconView.setContentHuggingPriority(.required, for: .horizontal)
		publicLinkStatusIconView.setContentCompressionResistancePriority(.required, for: .vertical)
		publicLinkStatusIconView.setContentCompressionResistancePriority(.required, for: .horizontal)

		cloudStatusIconView.setContentHuggingPriority(.required, for: .vertical)
		cloudStatusIconView.setContentHuggingPriority(.required, for: .horizontal)
		cloudStatusIconView.setContentCompressionResistancePriority(.required, for: .vertical)
		cloudStatusIconView.setContentCompressionResistancePriority(.required, for: .horizontal)

		iconView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

		titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
		detailLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

		moreButtonWidthConstraint = moreButton.widthAnchor.constraint(equalToConstant: moreButtonWidth)
		sharedStatusIconViewRightMarginConstraint = sharedStatusIconView.rightAnchor.constraint(equalTo: publicLinkStatusIconView.leftAnchor, constant: 0)
		publicLinkStatusIconViewRightMarginConstraint = publicLinkStatusIconView.rightAnchor.constraint(equalTo: cloudStatusIconView.leftAnchor, constant: 0)

		NSLayoutConstraint.activate([
			iconView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: horizontalMargin),
			iconView.rightAnchor.constraint(equalTo: titleLabel.leftAnchor, constant: -spacing),
			iconView.rightAnchor.constraint(equalTo: detailLabel.leftAnchor, constant: -spacing),
			iconView.widthAnchor.constraint(equalToConstant: iconViewWidth),
			iconView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: verticalIconMargin),
			iconView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -verticalIconMargin),

			titleLabel.rightAnchor.constraint(equalTo: sharedStatusIconView.leftAnchor, constant: -horizontalSmallMargin),
			sharedStatusIconViewRightMarginConstraint!,
			publicLinkStatusIconViewRightMarginConstraint!,
			detailLabel.rightAnchor.constraint(equalTo: moreButton.leftAnchor, constant: -horizontalMargin),

			titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: verticalLabelMargin),
			titleLabel.bottomAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: -verticalLabelMarginFromCenter),
			detailLabel.topAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: verticalLabelMarginFromCenter),
			detailLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -verticalLabelMargin),

			moreButton.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
			moreButton.topAnchor.constraint(equalTo: self.contentView.topAnchor),
			moreButton.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
			moreButtonWidthConstraint!,
			moreButton.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),

			sharedStatusIconView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

			publicLinkStatusIconView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

			cloudStatusIconView.rightAnchor.constraint(lessThanOrEqualTo: moreButton.leftAnchor, constant: -horizontalSmallMargin),
			cloudStatusIconView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor)
			])
	}

	// MARK: - Present item
	var item : OCItem? {
		didSet {
			localID = item?.localID as NSString?

			if let newItem = item {
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

		var size: String = item.sizeLocalized

		if item.size < 0 {
			size = "Pending".localized
		}

		self.detailLabel.text = size + " - " + item.lastModifiedLocalized

		self.accessoryType = .none

		if let core = core {
			activeThumbnailRequestProgress = self.iconView.setThumbnailImage(using: core, from: item, with: thumbnailSize, progressHandler: { [weak self] (progress) in
				if self?.activeThumbnailRequestProgress === progress {
					self?.activeThumbnailRequestProgress = nil
				}
			})
		}

		if item.isSharedWithUser || item.sharedByUserOrGroup {
			sharedStatusIconView.image = UIImage(named: "group")
			sharedStatusIconViewRightMarginConstraint?.constant = -horizontalSmallMargin
		} else {
			sharedStatusIconView.image = nil
			sharedStatusIconViewRightMarginConstraint?.constant = 0
		}
		if item.sharedByPublicLink {
			publicLinkStatusIconView.image = UIImage(named: "link")
			publicLinkStatusIconViewRightMarginConstraint?.constant = -horizontalSmallMargin
		} else {
			publicLinkStatusIconView.image = nil
			publicLinkStatusIconViewRightMarginConstraint?.constant = 0
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

		self.moreButton.accessibilityLabel = (item.name != nil) ? (item.name! + " " + "Actions".localized) : "Actions".localized

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

		if let item = item, (item.syncActivity.rawValue & (OCItemSyncActivity.downloading.rawValue | OCItemSyncActivity.uploading.rawValue) != 0) {
			progress = self.core?.progress(for: item, matching: .none)?.first

			if progress == nil {
				progress = Progress.indeterminate()
			}
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

		sharedStatusIconView.tintColor = collection.tableRowColors.secondaryLabelColor
		publicLinkStatusIconView.tintColor = collection.tableRowColors.secondaryLabelColor
		cloudStatusIconView.tintColor = collection.tableRowColors.secondaryLabelColor
		detailLabel.textColor = collection.tableRowColors.secondaryLabelColor

		moreButton.tintColor = collection.tableRowColors.labelColor
	}

	// MARK: - Editing mode
	func setMoreButton(hidden:Bool, animated: Bool = false) {
		if hidden || isMoreButtonPermanentlyHidden {
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
