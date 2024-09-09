//
//  OCSidebarItem+Interactions.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 28.02.24.
//  Copyright © 2024 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2024, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudApp

extension OCSidebarItem {
	func delete(in context: ClientContext?) {
		guard let context = context, let core = context.core else {
			return
		}

		core.vault.delete(self)
	}
}

// MARK: - Selection > Open
extension OCSidebarItem : DataItemSelectionInteraction {
	public func openItem(from viewController: UIViewController?, with context: ClientContext?, animated: Bool, pushViewController: Bool, completion: ((Bool) -> Void)?) -> UIViewController? {
		var viewController: UIViewController?

		if let location {
			viewController = location.customizedOpenItem(from: viewController, with: context, animated: animated, pushViewController: pushViewController, customizeViewController: { itemViewController in
				itemViewController.navigationBookmark = BrowserNavigationBookmark.from(dataItem: self, clientContext: context, restoreAction: .open)
			}, completion: completion)
		}

		return viewController
	}
}

// MARK: - Swipe Interaction
extension OCSidebarItem: DataItemSwipeInteraction {
	public func provideTrailingSwipeActions(with context: ClientContext?) -> UISwipeActionsConfiguration? {
		let deleteAction = UIContextualAction(style: .destructive, title: OCLocalizedString("Remove", nil), handler: { [weak self] (_ action, _ view, _ uiCompletionHandler) in
			uiCompletionHandler(false)
			self?.delete(in: context)
		})
		deleteAction.image = OCSymbol.icon(forSymbolName: "trash")

		return UISwipeActionsConfiguration(actions: [ deleteAction ])
	}
}

// MARK: - Context Menu Interaction
extension OCSidebarItem: DataItemContextMenuInteraction {
	public func composeContextMenuItems(in viewController: UIViewController?, location: OCExtensionLocationIdentifier, with context: ClientContext?) -> [UIMenuElement]? {
		let deleteAction = UIAction(handler: { [weak self] action in
			self?.delete(in: context)
		})
		deleteAction.title = OCLocalizedString("Remove", nil)
		deleteAction.image = OCSymbol.icon(forSymbolName: "trash")
		deleteAction.attributes = .destructive

		return [ deleteAction ]
	}
}

// MARK: - Drop
extension OCSidebarItem : DataItemDropInteraction {
	public func allowDropOperation(for session: UIDropSession, with context: ClientContext?) -> UICollectionViewDropProposal? {
		if session.localDragSession != nil {
			// Prevent drop of items onto themselves - or in their existing location
			if let dragItems = session.localDragSession?.items, let bookmarkUUID = context?.core?.bookmark.uuid {
				for dragItem in dragItems {
					if let localDataItem = dragItem.localObject as? LocalDataItem {
						if let item = localDataItem.dataItem as? OCItem, localDataItem.bookmarkUUID == bookmarkUUID, item.driveID == location?.driveID, let itemLocation = item.location {
							if (item.path == location?.path) || (itemLocation.parent?.path == location?.path) {
								return UICollectionViewDropProposal(operation: .cancel, intent: .unspecified)
							}
						}
					}
				}
			}

			// Return drop proposal based on item type
			switch location?.type {
				case .folder?, .drive?, .account?:
					return UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)

				default:
					return UICollectionViewDropProposal(operation: .move)
			}
		} else {
			// External items from other apps can only be copied into the app
			return UICollectionViewDropProposal(operation: .copy)
		}
	}

	public func performDropOperation(of droppedItems: [UIDragItem], with context: ClientContext?, handlingCompletion: @escaping (_ didSucceed: Bool) -> Void) {
		if let location {
			context?.core?.cachedItem(at: location, resultHandler: { error, item in
				OnMainThread {
					if let item {
						item.performDropOperation(of: droppedItems, with: context, handlingCompletion: handlingCompletion)
						handlingCompletion(true)
					} else {
						handlingCompletion(false)
					}
				}
			})
		} else {
			handlingCompletion(false)
		}
	}
}

// MARK: - BrowserNavigationBookmark (re)store
extension OCSidebarItem: DataItemBrowserNavigationBookmarkReStore {
	public func store(in bookmarkUUID: UUID?, context: ClientContext?, restoreAction: BrowserNavigationBookmark.BookmarkRestoreAction) -> BrowserNavigationBookmark? {
		let navigationBookmark = BrowserNavigationBookmark(for: self, in: bookmarkUUID, restoreAction: restoreAction)

		navigationBookmark?.sidebarItem = self
		navigationBookmark?.location = self.location

		return navigationBookmark
	}

	public static func restore(navigationBookmark: BrowserNavigationBookmark, in viewController: UIViewController?, with context: ClientContext?, completion: ((Error?, UIViewController?) -> Void)) {
		if let sidebarItem = navigationBookmark.sidebarItem {
			let viewController = sidebarItem.openItem(from: viewController, with: context, animated: false, pushViewController: false, completion: nil)
			completion(nil, viewController)
		} else {
			completion(NSError(ocError: .insufficientParameters), nil)
		}
	}
}
