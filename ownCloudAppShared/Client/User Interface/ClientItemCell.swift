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

public protocol ClientItemCellDelegate: class {

	func moreButtonTapped(cell: ClientItemCell)
	func messageButtonTapped(cell: ClientItemCell)

	func hasMessage(for item: OCItem) -> Bool
}

open class ClientItemCell: ThemeTableViewCell, ItemContainer {
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

	open weak var delegate: ClientItemCellDelegate?

	open var titleLabel : UILabel = UILabel()
	open var detailLabel : UILabel = UILabel()
	open var iconView : UIImageView = UIImageView()
	open var showingIcon : Bool = false
	open var cloudStatusIconView : UIImageView = UIImageView()
	open var sharedStatusIconView : UIImageView = UIImageView()
	open var publicLinkStatusIconView : UIImageView = UIImageView()
	open var moreButton : UIButton = UIButton()
	open var messageButton : UIButton = UIButton()
	open var progressView : ProgressView?

	open var moreButtonWidthConstraint : NSLayoutConstraint?

	open var sharedStatusIconViewZeroWidthConstraint : NSLayoutConstraint?
	open var publicLinkStatusIconViewZeroWidthConstraint : NSLayoutConstraint?
	open var cloudStatusIconViewZeroWidthConstraint : NSLayoutConstraint?

	open var sharedStatusIconViewRightMarginConstraint : NSLayoutConstraint?
	open var publicLinkStatusIconViewRightMarginConstraint : NSLayoutConstraint?
	open var cloudStatusIconViewRightMarginConstraint : NSLayoutConstraint?

	open var activeThumbnailRequestProgress : Progress?

	open var hasMessageForItem : Bool = false

	open var isMoreButtonPermanentlyHidden = false {
		didSet {
			if isMoreButtonPermanentlyHidden {
				moreButtonWidthConstraint?.constant = 0
			} else {
				moreButtonWidthConstraint?.constant = moreButtonWidth
			}
		}
	}

	open var isActive = true {
		didSet {
			let alpha : CGFloat = self.isActive ? 1.0 : 0.5
			titleLabel.alpha = alpha
			detailLabel.alpha = alpha
			iconView.alpha = alpha
			cloudStatusIconView.alpha = alpha
		}
	}

	open weak var core : OCCore?

	override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		prepareViewAndConstraints()
		self.multipleSelectionBackgroundView = {
			let blankView = UIView(frame: CGRect.zero)
			blankView.backgroundColor = UIColor.clear
			blankView.layer.masksToBounds = true
			return blankView
		}()

		NotificationCenter.default.addObserver(self, selector: #selector(updateAvailableOfflineStatus(_:)), name: .OCCoreItemPoliciesChanged, object: OCItemPolicyKind.availableOffline)

		NotificationCenter.default.addObserver(self, selector: #selector(updateHasMessage(_:)), name: .ClientSyncRecordIDsWithMessagesChanged, object: nil)

		if #available(iOS 13.4, *) {
			PointerEffect.install(on: self.contentView, effectStyle: .hover)
		}
	}

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	deinit {
		NotificationCenter.default.removeObserver(self, name: .OCCoreItemPoliciesChanged, object: OCItemPolicyKind.availableOffline)

		NotificationCenter.default.removeObserver(self, name: .ClientSyncRecordIDsWithMessagesChanged, object: nil)

		self.localID = nil
		self.core = nil
	}

	func prepareViewAndConstraints() {
		titleLabel.translatesAutoresizingMaskIntoConstraints = false

		detailLabel.translatesAutoresizingMaskIntoConstraints = false

		iconView.translatesAutoresizingMaskIntoConstraints = false
		iconView.contentMode = .scaleAspectFit

		moreButton.translatesAutoresizingMaskIntoConstraints = false

		messageButton.translatesAutoresizingMaskIntoConstraints = false

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
		self.contentView.addSubview(messageButton)

		moreButton.setImage(UIImage(named: "more-dots"), for: .normal)
		moreButton.contentMode = .center
		if #available(iOS 13.4, *) {
			moreButton.isPointerInteractionEnabled = true
		}

		messageButton.setTitle("⚠️", for: .normal)
		messageButton.contentMode = .center
		if #available(iOS 13.4, *) {
			messageButton.isPointerInteractionEnabled = true
		}
		messageButton.isHidden = true

		moreButton.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)
		messageButton.addTarget(self, action: #selector(messageButtonTapped), for: .touchUpInside)

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
			moreButton.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),

			messageButton.leftAnchor.constraint(equalTo: moreButton.leftAnchor),
			messageButton.rightAnchor.constraint(equalTo: moreButton.rightAnchor),
			messageButton.topAnchor.constraint(equalTo: moreButton.topAnchor),
			messageButton.bottomAnchor.constraint(equalTo: moreButton.bottomAnchor)
		])
	}

	// MARK: - Present item
	open var item : OCItem? {
		didSet {
			localID = item?.localID as NSString?

			if let newItem = item {
				updateWith(newItem)
			}
		}
	}

	open func titleLabelString(for item: OCItem?) -> String {
		if let item = item, let itemName = item.name {
			return itemName
		}

		return ""
	}

	open func detailLabelString(for item: OCItem?) -> String {
		if let item = item {
			var size: String = item.sizeLocalized

			if item.size < 0 {
				size = "Pending".localized
			}

			return size + " - " + item.lastModifiedLocalized
		}

		return ""
	}

	open func updateWith(_ item: OCItem) {
		var iconImage : UIImage?

		// Cancel any already active request
		if activeThumbnailRequestProgress != nil {
			activeThumbnailRequestProgress?.cancel()
		}

		// Set has message
		self.hasMessageForItem = delegate?.hasMessage(for: item) ?? false

		// Set the icon and initiate thumbnail generation
		iconImage = item.icon(fitInSize: iconSize)
		self.iconView.image = iconImage

  		if let core = core {
 			activeThumbnailRequestProgress = self.iconView.setThumbnailImage(using: core, from: item, with: thumbnailSize, itemContainer: self, progressHandler: { [weak self] (progress) in
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

		self.updateStatus()
	}

	open func updateCloudStatusIcon(with item: OCItem?) {
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

	open func updateLabels(with item: OCItem?) {
		self.titleLabel.text = titleLabelString(for: item)
		self.detailLabel.text = detailLabelString(for: item)
	}

	// MARK: - Available offline tracking
	@objc open func updateAvailableOfflineStatus(_ notification: Notification) {
		OnMainThread { [weak self] in
			self?.updateCloudStatusIcon(with: self?.item)
		}
	}

	// MARK: - Has Message tracking
	@objc open func updateHasMessage(_ notification: Notification) {
		if let notificationCore = notification.object as? OCCore, let core = self.core, notificationCore === core {
			OnMainThread { [weak self] in
				let oldMessageForItem = self?.hasMessageForItem ?? false

				if let item = self?.item, let hasMessage = self?.delegate?.hasMessage(for: item) {
					self?.hasMessageForItem = hasMessage
				} else {
					self?.hasMessageForItem = false
				}

				if oldMessageForItem != self?.hasMessageForItem {
					self?.updateStatus()
				}
			}
		}
	}

	// MARK: - Progress
	open var localID : OCLocalID? {
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

	@objc open func progressChangedForItem(_ notification : Notification) {
		if notification.object as? NSString == localID {
			OnMainThread {
				self.updateStatus()
			}
		}
	}

	open func updateStatus() {
		var progress : Progress?

		if let item = item, (item.syncActivity.rawValue & (OCItemSyncActivity.downloading.rawValue | OCItemSyncActivity.uploading.rawValue) != 0), !hasMessageForItem {
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
			messageButton.isHidden = true
		} else {
			moreButton.isHidden = hasMessageForItem
			messageButton.isHidden = !hasMessageForItem

			progressView?.removeFromSuperview()
			progressView = nil
		}
	}

	// MARK: - Themeing
	override open func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection) {
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
	open func setMoreButton(hidden:Bool, animated: Bool = false) {
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

	override open func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)

		setMoreButton(hidden: editing, animated: animated)
	}

	// MARK: - Actions
	@objc open func moreButtonTapped() {
		self.delegate?.moreButtonTapped(cell: self)
	}
	@objc open func messageButtonTapped() {
		self.delegate?.messageButtonTapped(cell: self)
	}
}

public extension NSNotification.Name {
	static let ClientSyncRecordIDsWithMessagesChanged = NSNotification.Name(rawValue: "client-sync-record-ids-with-messages-changed")
}
