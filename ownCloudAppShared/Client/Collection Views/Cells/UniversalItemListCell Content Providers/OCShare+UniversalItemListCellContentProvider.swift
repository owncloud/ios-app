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
		var isFile = (itemType == .file)
		let showManagementView = (configuration?.style.options[.showManagementView] as? Bool) ?? false
		let withoutDisclosure = (configuration?.style.options[.withoutDisclosure] as? Bool) ?? false
		// let sharedItemProvider = (configuration?.style.options[.sharedItemProvider] as? ItemProvider)
		// let sharedItem = sharedItemProvider?()

		// Title
		if !showManagementView {
			if itemLocation.isDriveRoot, let driveID = itemLocation.driveID, let drive = context?.core?.drive(withIdentifier: driveID), let driveName = drive.name {
				content.title = .drive(name: driveName)
			} else if let name = itemLocation.lastPathComponent {
				content.title = isFile ? .file(name: name) : .folder(name: name)
			} else if type == .remote, let name = (name as? NSString)?.lastPathComponent {
				// For federated shares
				isFile = name.contains(".") // No other hint (folders also don't have a trailing "/" in their name), so taking best shot based on existance of a .
				content.title = isFile ? .file(name: name) : .folder(name: name)
			}
		}

		// Icon
		if let mimeType = itemMIMEType, isFile {
			content.icon = .mime(type: mimeType)
		} else {
			content.icon = isFile ? .file : (itemLocation.isDriveRoot ? .drive : .folder)
		}

		// Details
		var detailText: String?
		var detailExtraItems: [SegmentViewItem]?

		switch category {
			case .withMe:
				let ownerName = owner?.displayName ?? owner?.userName ?? ""
				detailText = "Shared by {{owner}}".localized([ "owner" : ownerName ])

			case .byMe:
				if showManagementView {
					// Management view
					var roleDescription: String?
					var matchingRole: OCShareRole?

					if let core = context?.core {
						matchingRole = core.matchingShareRole(for: self)

						if let matchingRole {
							// Name and description for determined role
							roleDescription = "\(matchingRole.localizedName) (\(matchingRole.localizedDescription))"
						}
					}

					if type != .link {
						// Group + User shares
						if let user = recipient?.user {
							if let displayName = user.displayName {
	 							content.title = .text(displayName)
							}
							detailText = user.userName
						} else if let displayName = recipient?.displayName {
							content.title = .text(displayName)
						}

						if let roleDescription {
							detailText = roleDescription
						}
					} else {
						// Link shares
						content.title = .text(name ?? "Link".localized)

						if let urlString = url?.absoluteString, urlString.count > 0 {
							if let roleName = matchingRole?.localizedName {
								detailText = "\(roleName) | \(urlString)"
							} else {
								detailText = urlString
							}
						}
					}
				} else {
					// Overview
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
				}

				if let expirationDate {
					let prettyExpirationDate = OCItem.compactDateFormatter.string(from: expirationDate)

					let expirationDateIconSegment = SegmentViewItem(with: OCSymbol.icon(forSymbolName: "calendar"))
					expirationDateIconSegment.insets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0)

					let expirationDateSegment = SegmentViewItem(with: nil, title: "Expires {{expirationDate}}".localized(["expirationDate" : prettyExpirationDate]), style: .plain, titleTextStyle: .footnote)
					expirationDateSegment.insets = .zero

					detailExtraItems = [
						expirationDateIconSegment,
						expirationDateSegment
					]
				}

			default: break
		}

		if let detailText {
			var detailSegments: [SegmentViewItem] = [
				.detailText(detailText)
			]

			if let detailExtraItems {
				detailSegments.append(contentsOf: detailExtraItems)
			}

			content.details = detailSegments
		} else {
			content.details = detailExtraItems
		}

		if showManagementView {
			// Management view
			switch type {
				case .userShare:
					if let recipientUser = recipient?.user {
						let avatarRequest = OCResourceRequestAvatar(for: recipientUser, maximumSize: OCAvatar.defaultSize, scale: 0, waitForConnectivity: false)
						content.icon = .resource(request: avatarRequest)
					}

				case .groupShare:
					if recipient?.group != nil, let groupIcon = OCSymbol.icon(forSymbolName: "person.3.fill") {
						content.icon = .icon(image: groupIcon)
					}

				case .link:
					if let linkIcon = OCSymbol.icon(forSymbolName: "link") {
						content.icon = .icon(image: linkIcon)
					}

				default: break
			}
		} else {
			// Retrieve icon
			if ((category == .withMe) && (effectiveState == .accepted)) ||
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

				var accessories = [ copyToClipboardAccessory ]

				if showManagementView {
					if !withoutDisclosure {
						accessories.append(.disclosureIndicator())
					}
				} else {
					accessories.append(cell.revealButtonAccessory)
				}

				content.accessories = accessories
			} else {
				if showManagementView {
					if !withoutDisclosure {
						content.accessories = [
							.disclosureIndicator()
						]
					}
				} else {
					content.accessories = [
						cell.revealButtonAccessory
					]
				}
			}
		}

		if category == .withMe, let effectiveState {
			var accessories: [UICellAccessory] = []
			let omitLongActions = (effectiveState == .pending) && (UITraitCollection.current.horizontalSizeClass == .compact)

			if (effectiveState == .pending || effectiveState == .declined) && !omitLongActions {
				let (_, accessory) = cell.makeAccessoryButton(image: OCSymbol.icon(forSymbolName: "checkmark.circle"), title: "Accept".localized, accessibilityLabel: "Accept share".localized, cssSelectors: [.accessory, .accept], action: UIAction(handler: { [weak self, weak context] action in
					if let self, let context, let core = context.core {
						core.makeDecision(on: self, accept: true, completionHandler: { error in
						})
					}
				}))

				accessories.append(accessory)
			}

			if (effectiveState == .pending || effectiveState == .accepted) && !omitLongActions {
				let (_, accessory) = cell.makeAccessoryButton(image: OCSymbol.icon(forSymbolName: "minus.circle"), title: "Decline".localized, accessibilityLabel: "Decline share".localized, cssSelectors: [.accessory, .decline], action: UIAction(handler: { [weak self, weak context] action in
					if let self, let context, let core = context.core {
						core.makeDecision(on: self, accept: false, completionHandler: { error in
						})
					}
				}))

				accessories.append(accessory)
			}

			if omitLongActions, let menuItems = composeContextMenuItems(in: nil, location: .contextMenuItem, with: context) {
				let menu = UIMenu(children: menuItems)
				let (_, accessory) = UICellAccessory.borderedButton(image: OCSymbol.icon(forSymbolName: "ellipsis.circle"), accessibilityLabel: "Accept or decline".localized, cssSelectors: [.accessory, .action], menu: menu)
				accessories.append(accessory)
			}

			if effectiveState == .accepted {
				accessories.append(cell.revealButtonAccessory)
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
			return collectionView.dequeueConfiguredReusableCell(using: shareCellRegistration, for: indexPath, item: itemRef)
		}))
	}
}

extension ThemeCSSSelector {
	static let copyToClipboard = ThemeCSSSelector(rawValue: "copyToClipboard")
	static let accept = ThemeCSSSelector(rawValue: "accept")
	static let decline = ThemeCSSSelector(rawValue: "decline")
}
