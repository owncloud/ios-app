//
//  OCShare+UniversalItemListCellContentProvider.swift
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

extension OCShare: UniversalItemListCellContentProvider {
	public func provideContent(for cell: UniversalItemListCell, context: ClientContext?, configuration: CollectionViewCellConfiguration?, updateContent: @escaping UniversalItemListCell.ContentUpdater) {
		let content = UniversalItemListCell.Content(with: self)
		let isFile = (itemType == .file)

		// Icon
		if let mimeType = itemMIMEType, isFile {
			content.icon = .mime(type: mimeType)
		} else {
			content.icon = isFile ? .file : .folder
		}

		// Title
		if let name = itemLocation.lastPathComponent {
			content.title = isFile ? .file(name: name) : .folder(name: name)
		}

		// Details
		var detailText: String?

		switch category {
			case .withMe:
				let ownerName = owner?.displayName ?? owner?.userName ?? ""
				detailText = "Shared by {{owner}}".localized([ "owner" : ownerName ])

			case .byMe:
				if type != .link {
					let recipientName = recipient?.displayName ?? ""
					var recipients: String
					if let otherItemShares, otherItemShares.count > 0 {
						var recipientNames : [String] = [ recipientName ]
						for otherItemShare in otherItemShares {
							if let otherRecipientName = otherItemShare.recipient?.displayName {
								recipientNames.append(otherRecipientName)
							}
						}
						recipients = "Shared with {{recipients}}".localized([ "recipients" : recipientNames.joined(separator: ", ") ])
					} else {
						recipients = "Shared with {{recipient}}".localized([ "recipient" : recipientName ])
					}
					detailText = recipients
				} else {
					if let urlString = url?.absoluteString, urlString.count > 0 {
						if let name, name.count > 0 {
							detailText = "\(name) | \(urlString)"
						} else {
							detailText = urlString
						}
					}
				}

			default: break
		}

		if let detailText {
			let detailTextSegment = SegmentViewItem(with: nil, title: detailText, style: .plain, titleTextStyle: .footnote)
			detailTextSegment.insets = .zero

			content.details = [
				detailTextSegment
			]
		}

		if ((category == .withMe) && (state == .accepted)) ||
		   ((category == .byMe) && isFile) {
		   	let tokenArray: NSMutableArray = NSMutableArray()

			if let trackItemToken = context?.core?.trackItem(at: itemLocation, trackingHandler: { [weak cell] error, item, isInitial in
				if let item, let cell {
					let updatedContent = UniversalItemListCell.Content(with: content)

					OnMainThread {
						updatedContent.icon = .resource(request: OCResourceRequestItemThumbnail.request(for: item, maximumSize: cell.thumbnailSize, scale: 0, waitForConnectivity: true, changeHandler: nil))
						updatedContent.onlyFields = .icon

						if !updateContent(updatedContent) {
							tokenArray.removeAllObjects() // Drop token, end tracking
						}
					}
				}
			}) {
				tokenArray.add(trackItemToken)
			}

			cell.contentProviderUserInfo = tokenArray
		}

		if category == .byMe {
			if type == .link {
				let (_, copyToClipboardAccessory) = cell.makeAccessoryButton(image: OCSymbol.icon(forSymbolName: "list.clipboard"), title: "Copy".localized, accessibilityLabel: "Copy to clipboard".localized, cssSelectors: [.accessory, .copyToClipboard], action: UIAction(handler: { [weak self, weak context] action in
					if let self {
						if self.copyToClipboard(), let presentationViewController = context?.presentationViewController {
							_ = NotificationHUDViewController(on: presentationViewController, title: self.name ?? "Public Link".localized, subtitle: "URL was copied to the clipboard".localized)
						}
					}
				}))

				content.accessories = [
					copyToClipboardAccessory,
					cell.revealButtonAccessory
				]
			} else {
				content.accessories = [
					cell.revealButtonAccessory
				]
			}
		}

		if category == .withMe, let state, state != .accepted {
			var accessories: [UICellAccessory] = []

			if state == .pending || state == .declined {
				let (_, accessory) = cell.makeAccessoryButton(image: OCSymbol.icon(forSymbolName: "checkmark.circle"), title: "Accept".localized, accessibilityLabel: "Accept share".localized, cssSelectors: [.accessory, .accept], action: UIAction(handler: { [weak self, weak context] action in
					if let self, let context, let core = context.core {
						core.makeDecision(on: self, accept: true, completionHandler: { error in
						})
					}
				}))

				accessories.append(accessory)
			}

			if state == .pending {
				let (_, accessory) = cell.makeAccessoryButton(image: OCSymbol.icon(forSymbolName: "minus.circle"), title: "Decline".localized, accessibilityLabel: "Decline share".localized, cssSelectors: [.accessory, .decline], action: UIAction(handler: { [weak self, weak context] action in
					if let self, let context, let core = context.core {
						core.makeDecision(on: self, accept: false, completionHandler: { error in
						})
					}
				}))

				accessories.append(accessory)
			}

			content.accessories = accessories
		}

		_ = updateContent(content)
	}
}

extension OCShare {
	static func registerUniversalCellProvider() {
		let shareCellRegistration = UICollectionView.CellRegistration<UniversalItemListCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let share = OCDataRenderer.default.renderItem(item, asType: .share, error: nil, withOptions: nil) as? OCShare {
					cell.fill(from: share, context: cellConfiguration.clientContext, configuration: cellConfiguration)
				}
			})
		}

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .share, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			switch cellConfiguration?.style.type {
//				case .sideBar:
//					return collectionView.dequeueConfiguredReusableCell(using: savedSearchSidebarCellRegistration, for: indexPath, item: itemRef)
//
				default:
					return collectionView.dequeueConfiguredReusableCell(using: shareCellRegistration, for: indexPath, item: itemRef)
			}
		}))
	}
}

extension ThemeCSSSelector {
	static let copyToClipboard = ThemeCSSSelector(rawValue: "copyToClipboard")
	static let accept = ThemeCSSSelector(rawValue: "accept")
	static let decline = ThemeCSSSelector(rawValue: "decline")
}
