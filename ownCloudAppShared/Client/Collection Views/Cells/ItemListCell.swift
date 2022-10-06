//
//  ItemListCell.swift
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
import ownCloudSDK
import ownCloudApp

open class ItemListCell: ThemeableCollectionViewListCell {
	private let horizontalMargin : CGFloat = 15
	private let verticalLabelMargin : CGFloat = 10
	private let verticalIconMargin : CGFloat = 10
	private let horizontalSmallMargin : CGFloat = 10
	private let spacing : CGFloat = 15
	private let smallSpacing : CGFloat = 2
	private let iconViewWidth : CGFloat = 40
	private let detailIconViewHeight : CGFloat = 15
	private let accessoryButtonWidth : CGFloat = 35
	private let verticalLabelMarginFromCenter : CGFloat = 2
	private let iconSize : CGSize = CGSize(width: 40, height: 40)
	private let thumbnailSize : CGSize = CGSize(width: 60, height: 60) // when changing size, also update .iconView/fallbackSize

	open weak var clientContext: ClientContext? {
		didSet {
			isMoreButtonPermanentlyHidden = (clientContext?.moreItemHandler as? MoreItemAction == nil)
		}
	}

	open var titleLabel : UILabel = UILabel()
	open var detailLabel : UILabel = UILabel()
	open var iconView : ResourceViewHost = ResourceViewHost(fallbackSize: CGSize(width: 60, height: 60)) // when changing size, also update .thumbnailSize
	open var cloudStatusIconView : UIImageView = UIImageView()
	open var sharedStatusIconView : UIImageView = UIImageView()
	open var publicLinkStatusIconView : UIImageView = UIImageView()

	open var actionViewContainer : UIView = UIView()
	open var actionAccessory: UICellAccessory?
	open var moreButton : UIButton = UIButton()
	open var messageButton : UIButton = UIButton()
	open var progressView : ProgressView?

	open var revealButtonContainer: UIView = UIView()
	open var revealButton : UIButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
	open var revealButtonAccessory: UICellAccessory?

	open var sharedStatusIconViewZeroWidthConstraint : NSLayoutConstraint?
	open var publicLinkStatusIconViewZeroWidthConstraint : NSLayoutConstraint?
	open var cloudStatusIconViewZeroWidthConstraint : NSLayoutConstraint?

	open var sharedStatusIconViewRightMarginConstraint : NSLayoutConstraint?
	open var publicLinkStatusIconViewRightMarginConstraint : NSLayoutConstraint?
	open var cloudStatusIconViewRightMarginConstraint : NSLayoutConstraint?

	open var activeThumbnailRequest : OCResourceRequestItemThumbnail?

	open var hasMessageForItem : Bool = false

	open var isMoreButtonPermanentlyHidden = false {
		didSet {
			updateAccessories()
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

	override init(frame: CGRect) {
		super.init(frame: frame)
		prepareViewAndConstraints()

		NotificationCenter.default.addObserver(self, selector: #selector(updateAvailableOfflineStatus(_:)), name: .OCCoreItemPoliciesChanged, object: OCItemPolicyKind.availableOffline)

		NotificationCenter.default.addObserver(self, selector: #selector(updateHasMessage(_:)), name: .ClientSyncRecordIDsWithMessagesChanged, object: nil)

		PointerEffect.install(on: self.contentView, effectStyle: .hover)
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
		// cell.content setup
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		detailLabel.translatesAutoresizingMaskIntoConstraints = false

		iconView.translatesAutoresizingMaskIntoConstraints = false
		iconView.contentMode = .scaleAspectFit

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

		cloudStatusIconViewZeroWidthConstraint = cloudStatusIconView.widthAnchor.constraint(equalToConstant: 0)
		sharedStatusIconViewZeroWidthConstraint = sharedStatusIconView.widthAnchor.constraint(equalToConstant: 0)
		publicLinkStatusIconViewZeroWidthConstraint = publicLinkStatusIconView.widthAnchor.constraint(equalToConstant: 0)

		cloudStatusIconViewRightMarginConstraint = sharedStatusIconView.leadingAnchor.constraint(equalTo: cloudStatusIconView.trailingAnchor)
		sharedStatusIconViewRightMarginConstraint = publicLinkStatusIconView.leadingAnchor.constraint(equalTo: sharedStatusIconView.trailingAnchor)
		publicLinkStatusIconViewRightMarginConstraint = detailLabel.leadingAnchor.constraint(equalTo: publicLinkStatusIconView.trailingAnchor)

		NSLayoutConstraint.activate([
			iconView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: horizontalMargin),
			iconView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -spacing),
			iconView.widthAnchor.constraint(equalToConstant: iconViewWidth),
			iconView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: verticalIconMargin),
			iconView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -verticalIconMargin),

			titleLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: 0),
			detailLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: 0),

			cloudStatusIconViewZeroWidthConstraint!,
			sharedStatusIconViewZeroWidthConstraint!,
			publicLinkStatusIconViewZeroWidthConstraint!,

			cloudStatusIconView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: spacing),
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
			publicLinkStatusIconView.heightAnchor.constraint(equalToConstant: detailIconViewHeight)
		])

		// actionViewContainer setup
		moreButton.translatesAutoresizingMaskIntoConstraints = false
		revealButton.translatesAutoresizingMaskIntoConstraints = false
		messageButton.translatesAutoresizingMaskIntoConstraints = false

		actionViewContainer.addSubview(moreButton)
		actionViewContainer.addSubview(messageButton)

		revealButtonContainer.addSubview(revealButton)

		moreButton.setImage(UIImage(named: "more-dots"), for: .normal)
		moreButton.contentMode = .center
		moreButton.isPointerInteractionEnabled = true

		revealButton.setImage(UIImage(systemName: "arrow.right.circle.fill"), for: .normal)
		revealButton.isPointerInteractionEnabled = true
		revealButton.contentMode = .center
		revealButton.accessibilityLabel = "Reveal in folder".localized

		messageButton.setTitle("⚠️", for: .normal)
		messageButton.contentMode = .center
		messageButton.isPointerInteractionEnabled = true
		messageButton.isHidden = true

		moreButton.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)
		revealButton.addTarget(self, action: #selector(revealButtonTapped), for: .touchUpInside)
		messageButton.addTarget(self, action: #selector(messageButtonTapped), for: .touchUpInside)

		NSLayoutConstraint.activate([
			revealButton.topAnchor.constraint(equalTo: revealButtonContainer.topAnchor),
			revealButton.bottomAnchor.constraint(equalTo: revealButtonContainer.bottomAnchor),
			revealButton.leadingAnchor.constraint(equalTo: revealButtonContainer.leadingAnchor),
			revealButton.trailingAnchor.constraint(equalTo: revealButtonContainer.trailingAnchor),

			revealButton.widthAnchor.constraint(equalToConstant: accessoryButtonWidth),

			moreButton.topAnchor.constraint(equalTo: actionViewContainer.topAnchor),
			moreButton.bottomAnchor.constraint(equalTo: actionViewContainer.bottomAnchor),
			moreButton.leadingAnchor.constraint(equalTo: actionViewContainer.leadingAnchor),
			moreButton.trailingAnchor.constraint(equalTo: actionViewContainer.trailingAnchor),

			moreButton.widthAnchor.constraint(equalToConstant: accessoryButtonWidth),

			messageButton.topAnchor.constraint(equalTo: moreButton.topAnchor),
			messageButton.bottomAnchor.constraint(equalTo: moreButton.bottomAnchor),
			messageButton.leadingAnchor.constraint(equalTo: moreButton.leadingAnchor),
			messageButton.trailingAnchor.constraint(equalTo: moreButton.trailingAnchor)
		])

		let backgroundConfig = UIBackgroundConfiguration.listPlainCell()
		backgroundConfiguration = backgroundConfig

		self.accessibilityElements = [titleLabel, detailLabel, moreButton, revealButton, messageButton]

		actionAccessory = .customView(configuration: UICellAccessory.CustomViewConfiguration(customView: actionViewContainer, placement: .trailing(displayed: .whenNotEditing)))

		revealButtonAccessory = .customView(configuration: UICellAccessory.CustomViewConfiguration(customView: revealButtonContainer, placement: .trailing(displayed: .whenNotEditing)))

		updateAccessories()
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

	open func titleLabelString(for item: OCItem?) -> NSAttributedString {
		guard let item = item else { return NSAttributedString(string: "") }

		if item.type == .file, let itemName = item.baseName, let itemExtension = item.fileExtension {
			return NSMutableAttributedString()
				.appendBold(itemName)
				.appendNormal(".")
				.appendNormal(itemExtension)
		} else if item.type == .collection, let itemName = item.name {
			return NSMutableAttributedString()
				.appendBold(itemName)
		}

		return NSAttributedString(string: "")
	}

	open func detailLabelString(for item: OCItem?) -> String {
		if let item = item {
			var size: String = item.sizeLocalized

			if item.size < 0 {
				size = "Pending".localized
			}

			if item.state == .serverSideProcessing {
				size = "Processing on server".localized
			}

			return size + " - " + item.lastModifiedLocalized
		}

		return ""
	}

	open func updateWith(_ item: OCItem) {
		// Cancel any already active request
		if let activeThumbnailRequest = activeThumbnailRequest {
			core?.vault.resourceManager?.stop(activeThumbnailRequest)
			self.activeThumbnailRequest = nil
		}

		// Set has message
		self.hasMessageForItem = clientContext?.inlineMessageCenter?.hasInlineMessage(for: item) ?? false

		// Set the icon and initiate thumbnail generation
		let thumbnailRequest = OCResourceRequestItemThumbnail.request(for: item, maximumSize: self.thumbnailSize, scale: 0, waitForConnectivity: true, changeHandler: nil)

		iconView.request = thumbnailRequest

		// Start new thumbnail request
		core?.vault.resourceManager?.start(thumbnailRequest)

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

		if item.state == .serverSideProcessing {
			self.contentView.alpha = 0.5
		} else {
			self.contentView.alpha = 1.0
		}

		self.iconView.alpha = item.isPlaceholder ? 0.5 : 1.0
		self.moreButton.isHidden = (item.isPlaceholder || (progressView != nil)) ? true : !showMoreButton

		self.moreButton.accessibilityLabel = "Actions".localized
		self.moreButton.accessibilityIdentifier = (item.name != nil) ? (item.name! + " " + "Actions".localized) : "Actions".localized

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
		self.titleLabel.attributedText = titleLabelString(for: item)
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

				if let item = self?.item, let hasMessage = self?.clientContext?.inlineMessageCenter?.hasInlineMessage(for: item) {
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
				progressView.contentMode = .center
				progressView.translatesAutoresizingMaskIntoConstraints = false

				actionViewContainer.addSubview(progressView)

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
			moreButton.isHidden = hasMessageForItem || !showMoreButton
			messageButton.isHidden = !hasMessageForItem

			progressView?.removeFromSuperview()
			progressView = nil
		}
	}

	// MARK: - Themeing
	open var revealHighlight : Bool = false {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}

	open override func updateConfiguration(using state: UICellConfigurationState) {
		let collection = Theme.shared.activeCollection
		var backgroundConfig = backgroundConfiguration?.updated(for: state)

		if state.isHighlighted || state.isSelected || (state.cellDropState == .targeted) || revealHighlight {
			backgroundConfig?.backgroundColor = collection.tableRowHighlightColors.backgroundColor?.withAlphaComponent(0.5)
		} else {
			backgroundConfig?.backgroundColor = collection.tableBackgroundColor
		}

		backgroundConfiguration = backgroundConfig
	}

	open override func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection, state: ThemeItemState) {
		titleLabel.applyThemeCollection(collection, itemStyle: .title, itemState: state)
		detailLabel.applyThemeCollection(collection, itemStyle: .message, itemState: state)

		sharedStatusIconView.tintColor = collection.tableRowColors.secondaryLabelColor
		publicLinkStatusIconView.tintColor = collection.tableRowColors.secondaryLabelColor
		cloudStatusIconView.tintColor = collection.tableRowColors.secondaryLabelColor
		detailLabel.textColor = collection.tableRowColors.secondaryLabelColor

		moreButton.tintColor = collection.tableRowColors.secondaryLabelColor

		setNeedsUpdateConfiguration()
	}

	// MARK: - Editing mode
	var showMoreButton: Bool = true {
		didSet {
			updateAccessories()
		}
	}

	var showRevealButton: Bool = false {
		didSet {
			updateAccessories()
		}
	}

	func updateAccessories() {
		var updatedAccessories : [UICellAccessory] = [
			.multiselect()
		]

		if (showMoreButton || (item?.isPlaceholder == true) || (progressView != nil)) && !isMoreButtonPermanentlyHidden, let actionAccessory = actionAccessory {
			updatedAccessories.append(actionAccessory)
		}

		if showRevealButton, let revealButtonAccessory = revealButtonAccessory {
			updatedAccessories.append(revealButtonAccessory)
		}

		accessories = updatedAccessories
	}

	// MARK: - Actions
	@objc open func moreButtonTapped() {
		guard let item = item, let clientContext = clientContext else {
			return
		}

		if let moreItemHandling = clientContext.moreItemHandler {
			moreItemHandling.moreOptions(for: item, at: .moreItem, context: clientContext, sender: self)
		}
	}

	@objc open func messageButtonTapped() {
		guard let item = item, let clientContext = clientContext else {
			return
		}

		clientContext.inlineMessageCenter?.showInlineMessageFor(item: item)
	}

	@objc open func revealButtonTapped() {
		guard let item = item, let clientContext = clientContext else {
			return
		}

		clientContext.revealItemHandler?.reveal(item: item, context: clientContext, sender: self)
	}
}

public extension CollectionViewCellStyle.StyleOptionKey {
	static let showRevealButton = CollectionViewCellStyle.StyleOptionKey(rawValue: "showRevealButton")
	static let showMoreButton = CollectionViewCellStyle.StyleOptionKey(rawValue: "showMoreButton")
}

public extension CollectionViewCellStyle {
	var showRevealButton : Bool {
		get {
			return options[.showRevealButton] as? Bool ?? false
		}

		set {
			options[.showRevealButton] = newValue
		}
	}

	var showMoreButton : Bool {
		get {
			return options[.showMoreButton] as? Bool ?? true
		}

		set {
			options[.showMoreButton] = newValue
		}
	}
}

extension ItemListCell {
	static func registerCellProvider() {
		let itemListCellRegistration = UICollectionView.CellRegistration<ItemListCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				cell.clientContext = cellConfiguration.clientContext
				cell.core = cellConfiguration.core

				if let ocItem = item as? OCItem {
					cell.item = ocItem
				}

				cell.showRevealButton = cellConfiguration.style.showRevealButton
				cell.showMoreButton = cellConfiguration.style.showMoreButton
			})
		}

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .item, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			let cell = collectionView.dequeueConfiguredReusableCell(using: itemListCellRegistration, for: indexPath, item: itemRef)

			if cellConfiguration?.highlight == true {
				cell.revealHighlight = true
			}

			return cell
		}))
	}
}