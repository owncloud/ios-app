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

class ClientItemCell: ThemeTableViewCell, UIPointerInteractionDelegate {
	private let horizontalMargin : CGFloat = 15
	private let verticalLabelMargin : CGFloat = 10
	private let verticalIconMargin : CGFloat = 10
	private let horizontalSmallMargin : CGFloat = 10
	private let spacing : CGFloat = 15
	private let smallSpacing : CGFloat = 2
	private let iconViewWidth : CGFloat = 40
	private let detailIconViewHeight : CGFloat = 15
	private let moreButtonWidth : CGFloat = 60
	private let verticalLabelMarginFromCenter : CGFloat = 2
	private let iconSize : CGSize = CGSize(width: 40, height: 40)
	private let thumbnailSize : CGSize = CGSize(width: 60, height: 60)

	weak var delegate: ClientItemCellDelegate?

	var titleLabel : UILabel = UILabel()
	var detailLabel : UILabel = UILabel()
	var iconView : UIImageView = UIImageView()
	var showingIcon : Bool = false
	var cloudStatusIconView : UIImageView = UIImageView()
	var sharedStatusIconView : UIImageView = UIImageView()
	var publicLinkStatusIconView : UIImageView = UIImageView()
	var moreButton : UIButton = UIButton()
	var progressView : ProgressView?

	var moreButtonWidthConstraint : NSLayoutConstraint?

	var sharedStatusIconViewZeroWidthConstraint : NSLayoutConstraint?
	var publicLinkStatusIconViewZeroWidthConstraint : NSLayoutConstraint?
	var cloudStatusIconViewZeroWidthConstraint : NSLayoutConstraint?

	var sharedStatusIconViewRightMarginConstraint : NSLayoutConstraint?
	var publicLinkStatusIconViewRightMarginConstraint : NSLayoutConstraint?
	var cloudStatusIconViewRightMarginConstraint : NSLayoutConstraint?

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
		if #available(iOS 13.4, *) {
			_ = UIPointerInteraction(delegate: self)
			customPointerInteraction(on: moreButton, pointerInteractionDelegate: self)
		}

		NotificationCenter.default.addObserver(self, selector: #selector(updateAvailableOfflineStatus(_:)), name: .OCCoreItemPoliciesChanged, object: OCItemPolicyKind.availableOffline)
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	deinit {
		NotificationCenter.default.removeObserver(self, name: .OCCoreItemPoliciesChanged, object: OCItemPolicyKind.availableOffline)
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
		cloudStatusIconView.contentMode = .scaleAspectFit

		sharedStatusIconView.translatesAutoresizingMaskIntoConstraints = false
		sharedStatusIconView.contentMode = .center
		sharedStatusIconView.contentMode = .scaleAspectFit

		publicLinkStatusIconView.translatesAutoresizingMaskIntoConstraints = false
		publicLinkStatusIconView.contentMode = .center
		publicLinkStatusIconView.contentMode = .scaleAspectFit

		titleLabel.font = UIFont.preferredFont(forTextStyle: .callout)
		titleLabel.adjustsFontForContentSizeCategory = true
		titleLabel.lineBreakMode = .byTruncatingMiddle

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

		cloudStatusIconViewZeroWidthConstraint = cloudStatusIconView.widthAnchor.constraint(equalToConstant: 0)
		sharedStatusIconViewZeroWidthConstraint = sharedStatusIconView.widthAnchor.constraint(equalToConstant: 0)
		publicLinkStatusIconViewZeroWidthConstraint = publicLinkStatusIconView.widthAnchor.constraint(equalToConstant: 0)

		cloudStatusIconViewRightMarginConstraint = sharedStatusIconView.leftAnchor.constraint(equalTo: cloudStatusIconView.rightAnchor)
		sharedStatusIconViewRightMarginConstraint = publicLinkStatusIconView.leftAnchor.constraint(equalTo: sharedStatusIconView.rightAnchor)
		publicLinkStatusIconViewRightMarginConstraint = detailLabel.leftAnchor.constraint(equalTo: publicLinkStatusIconView.rightAnchor)

		NSLayoutConstraint.activate([
			iconView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: horizontalMargin),
			iconView.rightAnchor.constraint(equalTo: titleLabel.leftAnchor, constant: -spacing),
			iconView.widthAnchor.constraint(equalToConstant: iconViewWidth),
			iconView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: verticalIconMargin),
			iconView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -verticalIconMargin),

			titleLabel.rightAnchor.constraint(equalTo: moreButton.leftAnchor, constant: 0),
			detailLabel.rightAnchor.constraint(equalTo: moreButton.leftAnchor, constant: 0),

			cloudStatusIconViewZeroWidthConstraint!,
			sharedStatusIconViewZeroWidthConstraint!,
			publicLinkStatusIconViewZeroWidthConstraint!,

			cloudStatusIconView.leftAnchor.constraint(equalTo: iconView.rightAnchor, constant: spacing),
			cloudStatusIconViewRightMarginConstraint!,
			sharedStatusIconViewRightMarginConstraint!,
			publicLinkStatusIconViewRightMarginConstraint!,

			titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: verticalLabelMargin),
			titleLabel.bottomAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: -verticalLabelMarginFromCenter),
			detailLabel.topAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: verticalLabelMarginFromCenter),
			detailLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -verticalLabelMargin),

			cloudStatusIconView.centerYAnchor.constraint(equalTo: detailLabel.centerYAnchor),
			sharedStatusIconView.centerYAnchor.constraint(equalTo: detailLabel.centerYAnchor),
			publicLinkStatusIconView.centerYAnchor.constraint(equalTo: detailLabel.centerYAnchor),

			cloudStatusIconView.heightAnchor.constraint(equalToConstant: detailIconViewHeight),
			sharedStatusIconView.heightAnchor.constraint(equalToConstant: detailIconViewHeight),
			publicLinkStatusIconView.heightAnchor.constraint(equalToConstant: detailIconViewHeight),

			moreButton.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
			moreButton.topAnchor.constraint(equalTo: self.contentView.topAnchor),
			moreButton.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
			moreButtonWidthConstraint!,
			moreButton.rightAnchor.constraint(equalTo: self.contentView.rightAnchor)
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

	func titleLabelString(for item: OCItem?) -> String {
		if let item = item, let itemName = item.name {
			return itemName
		}

		return ""
	}

	func detailLabelString(for item: OCItem?) -> String {
		if let item = item {
			var size: String = item.sizeLocalized

			if item.size < 0 {
				size = "Pending".localized
			}

			return size + " - " + item.lastModifiedLocalized
		}

		return ""
	}

	func updateWith(_ item: OCItem) {
		var iconImage : UIImage?

		// Cancel any already active request
		if activeThumbnailRequestProgress != nil {
			activeThumbnailRequestProgress?.cancel()
		}

		// Set the icon and initiate thumbnail generation
		iconImage = item.icon(fitInSize: iconSize)
		self.iconView.image = iconImage

  		if let core = core {
 			activeThumbnailRequestProgress = self.iconView.setThumbnailImage(using: core, from: item, with: thumbnailSize, progressHandler: { [weak self] (progress) in
 				if self?.activeThumbnailRequestProgress === progress {
 					self?.activeThumbnailRequestProgress = nil
 				}
 			})
 		}

		self.accessoryType = .none

		if item.isSharedWithUser || item.sharedByUserOrGroup {
			sharedStatusIconView.image = UIImage(named: "group")
			sharedStatusIconViewRightMarginConstraint?.constant = smallSpacing
			sharedStatusIconViewZeroWidthConstraint?.isActive = false
		} else {
			sharedStatusIconView.image = nil
			sharedStatusIconViewRightMarginConstraint?.constant = 0
			sharedStatusIconViewZeroWidthConstraint?.isActive = true
		}
		sharedStatusIconView.invalidateIntrinsicContentSize()

		if item.sharedByPublicLink {
			publicLinkStatusIconView.image = UIImage(named: "link")
			publicLinkStatusIconViewRightMarginConstraint?.constant = smallSpacing
			publicLinkStatusIconViewZeroWidthConstraint?.isActive = false
		} else {
			publicLinkStatusIconView.image = nil
			publicLinkStatusIconViewRightMarginConstraint?.constant = 0
			publicLinkStatusIconViewZeroWidthConstraint?.isActive = true
		}
		publicLinkStatusIconView.invalidateIntrinsicContentSize()

		self.updateCloudStatusIcon(with: item)

		self.updateLabels(with: item)

		self.iconView.alpha = item.isPlaceholder ? 0.5 : 1.0
		self.moreButton.isHidden = (item.isPlaceholder || (progressView != nil)) ? true : false

		self.moreButton.accessibilityLabel = (item.name != nil) ? (item.name! + " " + "Actions".localized) : "Actions".localized

		self.updateProgress()
	}

	func updateCloudStatusIcon(with item: OCItem?) {
		var cloudStatusIcon : UIImage?
		var cloudStatusIconAlpha : CGFloat = 1.0

		if let item = item {
			let availableOfflineCoverage : OCCoreAvailableOfflineCoverage = core?.availableOfflinePolicyCoverage(of: item) ?? .none

			switch availableOfflineCoverage {
				case .direct, .none: cloudStatusIconAlpha = 1.0
				case .indirect: cloudStatusIconAlpha = 0.5
			}

			if item.type == .file {
				switch item.cloudStatus {
				case .cloudOnly:
					cloudStatusIcon = UIImage(named: "cloud-only")
					cloudStatusIconAlpha = 1.0

				case .localCopy:
					cloudStatusIcon = (item.downloadTriggerIdentifier == OCItemDownloadTriggerID.availableOffline) ? UIImage(named: "cloud-available-offline") : nil

				case .locallyModified, .localOnly:
					cloudStatusIcon = UIImage(named: "cloud-local-only")
					cloudStatusIconAlpha = 1.0
				}
			} else {
				if availableOfflineCoverage == .none {
					cloudStatusIcon = nil
				} else {
					cloudStatusIcon = UIImage(named: "cloud-available-offline")
				}
			}
		}

		cloudStatusIconView.image = cloudStatusIcon
		cloudStatusIconView.alpha = cloudStatusIconAlpha

		cloudStatusIconViewZeroWidthConstraint?.isActive = (cloudStatusIcon == nil)
		cloudStatusIconViewRightMarginConstraint?.constant = (cloudStatusIcon == nil) ? 0 : smallSpacing

		cloudStatusIconView.invalidateIntrinsicContentSize()
	}

	func updateLabels(with item: OCItem?) {
		self.titleLabel.text = titleLabelString(for: item)
		self.detailLabel.text = detailLabelString(for: item)
	}

	// MARK: - Available offline tracking
	@objc func updateAvailableOfflineStatus(_ notification: Notification) {
		OnMainThread { [weak self] in
			self?.updateCloudStatusIcon(with: self?.item)
		}
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

		moreButton.tintColor = collection.tableRowColors.secondaryLabelColor

		if showingIcon, let item = item {
			iconView.image = item.icon(fitInSize: iconSize)
		}
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

	// MARK: - UIPointerInteractionDelegate
	@available(iOS 13.4, *)
	func customPointerInteraction(on view: UIView, pointerInteractionDelegate: UIPointerInteractionDelegate) {
		let pointerInteraction = UIPointerInteraction(delegate: pointerInteractionDelegate)
		view.addInteraction(pointerInteraction)
	}

	@available(iOS 13.4, *)
	func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        var pointerStyle: UIPointerStyle?

        if let interactionView = interaction.view {
            let targetedPreview = UITargetedPreview(view: interactionView)
            pointerStyle = UIPointerStyle(effect: UIPointerEffect.highlight(targetedPreview))
        }
        return pointerStyle
    }
}
