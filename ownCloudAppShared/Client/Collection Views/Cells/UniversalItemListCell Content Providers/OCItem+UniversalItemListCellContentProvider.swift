//
//  OCItem+UniversalItemListCellContentProvider.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 05.01.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

class OCItemUniversalItemListCellHelper {
	weak var clientContext: ClientContext?

	typealias ContentRefresher = (_ helper: OCItemUniversalItemListCellHelper, _ fields: UniversalItemListCell.Content.Fields?) -> Bool

	var contentRefresher: ContentRefresher
	var hasMessageForItem: Bool
	var item: OCItem

	init(with item: OCItem, hasMessageForItem: Bool, context: ClientContext?, contentRefresher: @escaping ContentRefresher) {
		self.item = item
		self.clientContext = context
		self.hasMessageForItem = hasMessageForItem
		self.contentRefresher = contentRefresher

		addObservers()
	}

	deinit {
		removeObservers()
	}

	func addObservers() {
		localID = item.localID as NSString?

		NotificationCenter.default.addObserver(self, selector: #selector(updateAvailableOfflineStatus(_:)), name: .OCCoreItemPoliciesChanged, object: OCItemPolicyKind.availableOffline)
		NotificationCenter.default.addObserver(self, selector: #selector(updateHasMessage(_:)), name: .ClientSyncRecordIDsWithMessagesChanged, object: nil)
	}
	func removeObservers() {
		NotificationCenter.default.removeObserver(self, name: .OCCoreItemPoliciesChanged, object: OCItemPolicyKind.availableOffline)
		NotificationCenter.default.removeObserver(self, name: .ClientSyncRecordIDsWithMessagesChanged, object: nil)

		localID = nil
	}

	// MARK: - Progress
	var localID: OCLocalID? {
		willSet {
			if localID != nil {
				NotificationCenter.default.removeObserver(self, name: .OCCoreItemChangedProgress, object: localID)
			}
		}

		didSet {
			if localID != nil {
				NotificationCenter.default.addObserver(self, selector: #selector(progressChangedForItem(_:)), name: .OCCoreItemChangedProgress, object: localID)
			}
		}
	}

	@objc open func progressChangedForItem(_ notification : Notification) {
		self.refreshContent(fields: .progress)
	}

	// MARK: - Available offline tracking
	@objc open func updateAvailableOfflineStatus(_ notification: Notification) {
		// TODO: Improve change detection, trigger refresh only when changed
		self.refreshContent(fields: .details)
	}

	// MARK: - Has Message tracking
	@objc open func updateHasMessage(_ notification: Notification) {
		if let notificationCore = notification.object as? OCCore, let core = clientContext?.core, notificationCore === core {
			OnMainThread { [weak self] in
				guard let self else { return }

				let oldMessageForItem = self.hasMessageForItem
				let newMessageForItem = self.clientContext?.inlineMessageCenter?.hasInlineMessage(for: self.item)

				if let newMessageForItem, oldMessageForItem != newMessageForItem {
					self.hasMessageForItem = newMessageForItem

					self.refreshContent(fields: .accessories)
				} else {
					Log.debug("Skipped message center update")
				}
			}
		}
	}

	func refreshContent(fields: UniversalItemListCell.Content.Fields?) {
		OnMainThread { [weak self] in
			if let self {
				_ = self.contentRefresher(self, fields)
			}
		}
	}
}

extension OCItem: UniversalItemListCellContentProvider {
	func cloudStatus(in core: OCCore?) -> (icon: UIImage?, iconAlpha: CGFloat, accessibilityLabel: String?) {
		var cloudStatusIcon : UIImage?
		var cloudStatusIconAlpha : CGFloat = 1.0
		var accessibilityLabel: String?
		let availableOfflineCoverage : OCCoreAvailableOfflineCoverage = core?.availableOfflinePolicyCoverage(of: self) ?? .none

		switch availableOfflineCoverage {
			case .direct, .none: cloudStatusIconAlpha = 1.0
			case .indirect: cloudStatusIconAlpha = 0.5
		}

		if type == .file {
			switch cloudStatus {
				case .cloudOnly:
					cloudStatusIcon = OCItem.cloudOnlyStatusIcon
					cloudStatusIconAlpha = 1.0
					accessibilityLabel = OCLocalizedString("In the cloud", nil)

				case .localCopy:
					cloudStatusIcon = (downloadTriggerIdentifier == OCItemDownloadTriggerID.availableOffline) ? OCItem.cloudAvailableOfflineStatusIcon : nil
					accessibilityLabel = OCLocalizedString("Local copy", nil)

				case .locallyModified, .localOnly:
					cloudStatusIcon = OCItem.cloudLocalOnlyStatusIcon
					cloudStatusIconAlpha = 1.0
					accessibilityLabel = OCLocalizedString("Local version", nil)
			}
		} else {
			if availableOfflineCoverage == .none {
				cloudStatusIcon = nil
				accessibilityLabel = nil
			} else {
				cloudStatusIcon = OCItem.cloudAvailableOfflineStatusIcon
				accessibilityLabel = OCLocalizedString("Available offline", nil)
			}
		}

		return (cloudStatusIcon, cloudStatusIconAlpha, accessibilityLabel)
	}

	func content(for cell: UniversalItemListCell?, thumbnailSize: CGSize, context: ClientContext?, configuration: CollectionViewCellConfiguration?) -> (content: UniversalItemListCell.Content, hasMessageForItem: Bool) {
		let content = UniversalItemListCell.Content(with: self)
		let isFile = (type == .file)

		// Disabled
		content.disabled = (state == .serverSideProcessing)

		var itemAppearance: ClientItemAppearance = .regular
		if let context, let itemStyler = context.itemStyler {
			itemAppearance = itemStyler(context, nil, self)

			if itemAppearance == .disabled {
				content.disabled = true
			}
		}

		// Icon
		content.icon = .resource(request: OCResourceRequestItemThumbnail.request(for: self, maximumSize: thumbnailSize, scale: 0, waitForConnectivity: true, changeHandler: nil))
		content.iconDisabled = isPlaceholder

		// Title
		if let name {
			let isHeader = configuration?.style.type == .header
			if !isFile, isRoot, let driveID, let core = context?.core, let drive = core.drive(withIdentifier: driveID, attachedOnly: true), let driveName = drive.name {
				content.title = .drive(name: isHeader ? driveName.redacted() : driveName)
			} else {
				let displayName = isHeader ? name.redacted() : name
				content.title = isFile ? .file(name: displayName) : .folder(name: displayName)
			}
		}

		// Details
		var detailItems: [SegmentViewItem] = []

		if configuration?.style.showPathDetails == true {
			// - path breadcrumbs for style.showPathDetails == true
			if let context, let parentLocation = location?.parent {
				detailItems = OCLocation.composeSegments(breadcrumbs: parentLocation.breadcrumbs(in: context, includeServerName: false), in: context)
				detailItems.append(SegmentViewItem(with: nil, title: "|", style: .plain))
			}
		}

		// - Cloud status
		let (cloudStatusIcon, cloudStatusIconAlpha, accessibilityLabel) = cloudStatus(in: context?.core)

		if let cloudStatusIcon {
			let segmentItem = SegmentViewItem(with: cloudStatusIcon.scaledImageFitting(in: CGSize(width: 32, height: 16)), style: .plain, lines: [.singleLine, .primary], accessibilityLabel: accessibilityLabel)
			segmentItem.insets = .zero
			segmentItem.alpha = cloudStatusIconAlpha
			detailItems.append(segmentItem)
		}

		// - Sharing
		if isSharedWithUser || sharedByUserOrGroup {
			let segmentItem = SegmentViewItem(with: OCItem.groupIcon?.scaledImageFitting(in: CGSize(width: 32, height: 16)), style: .plain, lines: [.singleLine, .primary], accessibilityLabel: OCLocalizedString("Shared", nil))
			segmentItem.insets = .zero
			detailItems.append(segmentItem)
		}

		if sharedByPublicLink {
			let segmentItem = SegmentViewItem(with: OCItem.linkIcon?.scaledImageFitting(in: CGSize(width: 32, height: 16)), style: .plain, lines: [.singleLine, .primary], accessibilityLabel: OCLocalizedString("Shared by link", nil))
			segmentItem.insets = .zero
			detailItems.append(segmentItem)
		}

		// - Description
		var detailString: String = sizeLocalized

		if size < 0 {
			detailString = OCLocalizedString("Pending", nil)
		}
		if state == .serverSideProcessing {
			detailString = OCLocalizedString("Processing on server", nil)
		}

		let primaryLineSizeSegment = SegmentViewItem(with: nil, title: detailString, style: .plain, titleTextStyle: .footnote, lines: [.primary])
		primaryLineSizeSegment.insets = .zero
		detailItems.append(primaryLineSizeSegment)

		let secondaryLineDateSegment = SegmentViewItem(with: nil, title: lastModifiedLocalizedCompact, style: .plain, titleTextStyle: .footnote, lines: [.secondary], accessibilityLabel: lastModifiedLocalizedAccessible)
		secondaryLineDateSegment.insets = .zero
		detailItems.append(secondaryLineDateSegment)

		var detailStringAccessible = detailString

		detailString += " - " + lastModifiedLocalized
		detailStringAccessible += " " + lastModifiedLocalizedAccessible

		let detailSegment = SegmentViewItem(with: nil, title: detailString, style: .plain, titleTextStyle: .footnote, lines: [.singleLine], accessibilityLabel: detailStringAccessible)
		detailSegment.insets = .zero

		detailItems.append(detailSegment)

		// /Details
		content.details = detailItems

		// Message
		let hasMessageForItem = context?.inlineMessageCenter?.hasInlineMessage(for: self) ?? false

		// Progress
		var progress : Progress?

		if syncActivity.rawValue & (OCItemSyncActivity.downloading.rawValue | OCItemSyncActivity.uploading.rawValue) != 0, !hasMessageForItem {
			progress = context?.core?.progressForItem(withLocalID: self.localID, matching: .none)?.first

			if progress == nil {
				progress = Progress.indeterminate()
			}

			content.progress = progress
		}

		// Accessibility custom actions
		if #available(iOS 17, *) {
			if let context, let clientViewController = context.originatingViewController as? ClientItemViewController {
				content.accessibilityCustomActionsBlock = { [weak self] in
					var accessibilityActions : [UIAccessibilityCustomAction] = []

					if let core = context.core, let self {
						let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .accessibilityCustomAction)
						let actionContext = ActionContext(viewController: clientViewController, clientContext: context, core: core, items: [self], location: actionsLocation, sender: nil)
						let actions = Action.sortedApplicableActions(for: actionContext)
						for action in actions {
							action.progressHandler = context.actionProgressHandlerProvider?.makeActionProgressHandler()

							let customAction = action.provideAccessibilityCustomAction()
							accessibilityActions.append(customAction)
						}
					}

					return accessibilityActions
				}
			}
		}

		// Accessories
		var accessories: [UICellAccessory] = [
			.multiselect()
		]
		var includeMoreButton: Bool = false

		if !((context?.moreItemHandler as? MoreItemAction == nil) || context?.hasPermission(for: .moreOptions) == false) {
			includeMoreButton = configuration?.style.showMoreButton == true
		}

		if let cell {
			if hasMessageForItem {
				accessories.append(cell.messageButtonAccessory)
			} else if progress != nil {
				accessories.append(cell.progressAccessory)
			} else if includeMoreButton {
				accessories.append(cell.moreButtonAccessory)
			}

			if configuration?.style.showRevealButton == true {
				accessories.append(cell.revealButtonAccessory)
			}
		}

		content.accessories = accessories

		return (content, hasMessageForItem)
	}

	// MARK: - UniversalItemListCellContentProvider implementation
	public func provideContent(for cell: UniversalItemListCell, context: ClientContext?, configuration: CollectionViewCellConfiguration?, updateContent: @escaping UniversalItemListCell.ContentUpdater) {
		// Assemble content
		let (content, hasMessageForItem) = content(for: cell, thumbnailSize: cell.thumbnailSize, context: context, configuration: configuration)

		// Install helper object listening for changes that don't propagate through OCItem changes
		cell.contentProviderUserInfo = OCItemUniversalItemListCellHelper(with: self, hasMessageForItem: hasMessageForItem, context: context, contentRefresher: { [weak self, weak cell, weak context] (helper, fields) in
			if let cell, let (content, hasMessageForItem) = self?.content(for: cell, thumbnailSize: cell.thumbnailSize, context: context, configuration: configuration) {
				content.onlyFields = fields
				helper.hasMessageForItem = hasMessageForItem

				return updateContent(content) == true
			}

			return false
		})

		// Return composed content
		_ = updateContent(content)
	}
}

extension OCItem {
	static func registerUniversalCellProvider() {
		let cellRegistration = UICollectionView.CellRegistration<UniversalItemListCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let item = OCDataRenderer.default.renderItem(item, asType: .item, error: nil, withOptions: nil) as? OCItem {
					cell.fill(from: item, context: cellConfiguration.clientContext, configuration: cellConfiguration)
				}
			})
		}

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .item, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			switch cellConfiguration?.style.type {
				default:
					let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemRef)

					if cellConfiguration?.highlight == true {
						cell.revealHighlight = true
					}

					return cell
			}
		}))
	}
}

extension OCItem {
	static func loadIcon(named name: String) -> UIImage? {
		return UIImage(named: name, in: Bundle.sharedAppBundle, with: nil)
	}

	public static var linkIcon: UIImage? = { return loadIcon(named: "link") }()
	public static var groupIcon: UIImage? = { return loadIcon(named: "group") }()

	public static var cloudOnlyStatusIcon: UIImage? = { return loadIcon(named: "cloud-only") }()
	public static var cloudLocalOnlyStatusIcon: UIImage? = { return loadIcon(named: "cloud-local-only") }()
	public static var cloudAvailableOfflineStatusIcon: UIImage? = { return loadIcon(named: "cloud-available-offline") }()
	public static var cloudUnavailableOfflineStatusIcon: UIImage? = { return loadIcon(named: "cloud-unavailable-offline") }()
}
