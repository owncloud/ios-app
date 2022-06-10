//
//  OCItem+Interactions.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 30.05.22.
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

// MARK: - Selection > Open
extension OCItem : DataItemSelectionInteraction {
	public func openItem(in viewController: UIViewController?, with context: ClientContext?, animated: Bool, pushViewController: Bool, completion: ((Bool) -> Void)?) -> UIViewController? {
		if let context = context, let core = context.core {
			let item = self

			let activity = OpenItemUserActivity(detailItem: item, detailBookmark: core.bookmark)
			viewController?.view.window?.windowScene?.userActivity = activity.openItemUserActivity

			switch item.type {
				case .collection:
					if let location = item.location {
						let query = OCQuery(for: location)
						DisplaySettings.shared.updateQuery(withDisplaySettings: query)

						let queryViewController = ClientItemViewController(context: context, query: query)
						if pushViewController {
							context.navigationController?.pushViewController(queryViewController, animated: animated)
						}

						completion?(true)

						return queryViewController
					}

				case .file:
					if let viewController = context.viewItemHandler?.provideViewer(for: self, context: context) {
						if pushViewController {
							context.navigationController?.pushViewController(viewController, animated: animated)
						}

						completion?(true)

						return viewController
					}
			}
		}

		completion?(false)

		return nil
	}
}

// MARK: - Swipe
extension OCItem : DataItemSwipeInteraction {
	public func provideTrailingSwipeActions(with context: ClientContext?) -> UISwipeActionsConfiguration? {
		guard let context = context, let core = context.core, let originatingViewController = context.originatingViewController else {
			return nil
		}

		let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .tableRow)
		let actionContext = ActionContext(viewController: originatingViewController, core: core, items: [self], location: actionsLocation, sender: nil)
		let actions = Action.sortedApplicableActions(for: actionContext)

		let contextualActions = actions.compactMap({ action in
			return action.provideContextualAction()
		})
		let configuration = UISwipeActionsConfiguration(actions: contextualActions)
		return configuration
	}
}

// MARK: - Context Menu
extension OCItem : DataItemContextMenuInteraction {
	public func composeContextMenuItems(in viewController: UIViewController?, location: OCExtensionLocationIdentifier, with context: ClientContext?) -> [UIMenuElement]? {
		guard let core = context?.core, let viewController = viewController else {
			return nil
		}
		let item = self
		let actionsLocation = OCExtensionLocation(ofType: .action, identifier: location) // .contextMenuItem)
		let actionContext = ActionContext(viewController: viewController, core: core, items: [item], location: actionsLocation, sender: nil)
		let actions = Action.sortedApplicableActions(for: actionContext)
		var actionMenuActions : [UIAction] = []
		for action in actions {
			action.progressHandler = context?.actionProgressHandlerProvider?.makeActionProgressHandler()

			if let menuAction = action.provideUIMenuAction() {
				actionMenuActions.append(menuAction)
			}
		}

		if core.connectionStatus == .online, core.connection.capabilities?.sharingAPIEnabled == 1, location == .contextMenuItem {
			// Actions menu
			let actionsMenu = UIMenu(title: "", identifier: UIMenu.Identifier("context"), options: .displayInline, children: actionMenuActions)

			// Share Items
			let sharingActionsLocation = OCExtensionLocation(ofType: .action, identifier: .contextMenuSharingItem)
			let sharingActionContext = ActionContext(viewController: viewController, core: core, items: [item], location: sharingActionsLocation, sender: nil)
			let sharingActions = Action.sortedApplicableActions(for: sharingActionContext)
			for action in sharingActions {
				action.progressHandler = context?.actionProgressHandlerProvider?.makeActionProgressHandler()
			}

			let sharingItems = sharingActions.compactMap({ action in action.provideUIMenuAction() })
			let shareMenu = UIMenu(title: "", identifier: UIMenu.Identifier("sharing"), options: .displayInline, children: sharingItems)

			return [shareMenu, actionsMenu]
		}

		return actionMenuActions
	}
}
