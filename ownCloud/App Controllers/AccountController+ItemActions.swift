//
//  AccountController+ItemActions.swift
//  ownCloud
//
//  Created by Felix Schwarz on 22.11.22.
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
import ownCloudApp
import ownCloudAppShared

extension AccountController {
	public var localizedDeleteTitle: String {
		return VendorServices.shared.isBranded ? OCLocalizedString("Log out", nil) : OCLocalizedString("Delete", nil)
	}

	public func editBookmark(on hostViewController: UIViewController, completion completionHandler: (() -> Void)? = nil) {
		if let bookmark = connection?.bookmark {
			self.disconnect { _ in
				BookmarkViewController.showBookmarkUI(on: hostViewController, edit: bookmark, removeAuthDataFromCopy: false)
				completionHandler?()
			}
		} else {
			completionHandler?()
		}
	}

	public func deleteBookmark(withAlertOn hostViewController: UIViewController, completion completionHandler: (() -> Void)? = nil) {
		if let bookmark = connection?.bookmark {
			self.disconnect { _ in
				OCBookmarkManager.shared.delete(withAlertOn: hostViewController, bookmark: bookmark, completion: {
					completionHandler?()
				})
			}
		} else {
			completionHandler?()
		}
	}

	public func manageBookmark(on hostViewController: UIViewController, completion completionHandler: (() -> Void)? = nil) {
		if let bookmark = connection?.bookmark {
			self.disconnect { _ in
				OCBookmarkManager.shared.manage(bookmark: bookmark, presentOn: hostViewController, completion: completionHandler)
			}
		} else {
			completionHandler?()
		}
	}
}

extension AccountController: ownCloudAppShared.DataItemSwipeInteraction {
	public func provideTrailingSwipeActions(with context: ClientContext?) -> UISwipeActionsConfiguration? {
		if let hostViewController = context?.originatingViewController ?? context?.rootViewController {
			let deleteRowAction = UIContextualAction(style: .destructive, title: localizedDeleteTitle, handler: { [weak self, weak hostViewController] (_, _, completionHandler) in
				guard let hostViewController = hostViewController else {
					completionHandler(false)
					return
				}

				self?.deleteBookmark(withAlertOn: hostViewController, completion: {
					completionHandler(true)
				})
			})

			return UISwipeActionsConfiguration(actions: [deleteRowAction])
		}

		return nil
	}
}

extension AccountController {
	func openInNewWindowUserActivity(with context: ClientContext) -> NSUserActivity? {
		if let bookmark {
			let activity = AppStateAction(with: [
				.connection(with: bookmark, children: [
					.goToPersonalFolder()
				])
			]).userActivity(with: clientContext)

			return activity
		}

		return nil
	}
}

extension AccountController: ownCloudAppShared.DataItemContextMenuInteraction {
	public func composeContextMenuItems(in viewController: UIViewController?, location: OCExtensionLocationIdentifier, with context: ClientContext?) -> [UIMenuElement]? {
		if let hostViewController = context?.originatingViewController ?? context?.rootViewController {
			var menuItems: [UIMenuElement] = []

			// Open in a new window
			if UIDevice.current.isIpad {
				let openWindow = UIAction(title: OCLocalizedString("Open in a new Window", nil), image: UIImage(systemName: "uiwindow.split.2x1")) { [weak self] _ in
					if let clientContext = self?.clientContext, let userActivity = self?.openInNewWindowUserActivity(with: clientContext) {
						UIApplication.shared.requestSceneSessionActivation(nil, userActivity: userActivity, options: nil)
					}
				}

				menuItems.append(openWindow)
			}

			// Edit
			if VendorServices.shared.canEditAccount {
				let editAction = UIAction(handler: { [weak self, weak hostViewController] action in
					guard let hostViewController = hostViewController else { return }

					self?.editBookmark(on: hostViewController)
				})
				editAction.title = OCLocalizedString("Edit", nil)
				editAction.image = OCSymbol.icon(forSymbolName: "pencil")

				menuItems.append(editAction)
			}

			// Manage
			let manageAction = UIAction(handler: { [weak self, weak hostViewController] action in
				guard let hostViewController = hostViewController else { return }

				self?.manageBookmark(on: hostViewController)
			})
			manageAction.title = OCLocalizedString("Manage", nil)
			manageAction.image = OCSymbol.icon(forSymbolName: "gearshape")

			menuItems.append(manageAction)

			// Disconnect
			if showDisconnectButton {
				let disconnectAction = UIAction(handler: { [weak self] _ in
					self?.disconnect(completion: nil)
				})
				disconnectAction.title = OCLocalizedString("Disconnect", nil)
				disconnectAction.image = OCSymbol.icon(forSymbolName: "eject.circle.fill")

				menuItems.append(disconnectAction)
			}

			// Delete
			let deleteAction = UIAction(handler: { [weak self, weak hostViewController] action in
				guard let hostViewController = hostViewController else { return }

				self?.deleteBookmark(withAlertOn: hostViewController)
			})
			deleteAction.title = localizedDeleteTitle
			deleteAction.image = OCSymbol.icon(forSymbolName: "trash")
			deleteAction.attributes = .destructive

			menuItems.append(deleteAction)

			return menuItems
		}

		return (nil)
	}
}

extension AccountController: ownCloudAppShared.DataItemDragInteraction {
	public func provideDragItems(with context: ClientContext?) -> [UIDragItem]? {
		if let bookmark, let userActivity = openInNewWindowUserActivity(with: clientContext) {
			let itemProvider = NSItemProvider(item: bookmark, typeIdentifier: "com.owncloud.ios-app.ocbookmark")
			itemProvider.registerObject(userActivity, visibility: .all)

			let dragItem = UIDragItem(itemProvider: itemProvider)
			dragItem.localObject = bookmark

			return [dragItem]
		}

		return nil
	}
}

extension AccountController: ownCloudAppShared.DataItemDropInteraction {
	public func allowDropOperation(for session: UIDropSession, with context: ClientContext?) -> UICollectionViewDropProposal? {
		if session.localDragSession == nil {
			return nil
		}

		return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
	}

	public func performDropOperation(of items: [UIDragItem], with context: ClientContext?, handlingCompletion: @escaping (Bool) -> Void) {
		handlingCompletion(false)
	}
}
