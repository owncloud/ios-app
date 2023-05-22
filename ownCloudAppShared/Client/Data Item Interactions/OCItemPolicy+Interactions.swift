//
//  OCItemPolicy+Interactions.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 15.12.22.
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

extension OCItemPolicy: DataItemSelectionInteraction {
	public func allowSelection(in viewController: UIViewController?, section: CollectionViewSection?, with context: ClientContext?) -> Bool {
		return false
	}

	public func revealItem(from viewController: UIViewController?, with context: ClientContext?, animated: Bool, pushViewController: Bool, completion: ((Bool) -> Void)?) -> UIViewController? {
		return location?.revealItem(from: viewController, with: context, animated: animated, pushViewController: pushViewController, completion: completion)
	}
}

extension OCItemPolicy: DataItemSwipeInteraction {
	func canDelete(in clientContext: ClientContext?) -> Bool {
		if clientContext != nil, clientContext?.core != nil {
			return true
		}

		return false
	}

	func delete(in clientContext: ClientContext?) {
		if let clientContext, let core = clientContext.core {
			core.removeAvailableOfflinePolicy(self, completionHandler: nil)
		}
	}

	public func provideTrailingSwipeActions(with context: ClientContext?) -> UISwipeActionsConfiguration? {
		guard canDelete(in: context) else {
			return nil
		}

		let deleteAction = UIContextualAction(style: .destructive, title: "Make unavailable offline".localized, handler: { [weak self] (_ action, _ view, _ uiCompletionHandler) in
			uiCompletionHandler(false)
			self?.delete(in: context)
		})
		deleteAction.image = UIImage(named: "cloud-unavailable-offline")

		return UISwipeActionsConfiguration(actions: [ deleteAction ])
	}
}

extension OCItemPolicy: DataItemContextMenuInteraction {
	public func composeContextMenuItems(in viewController: UIViewController?, location: OCExtensionLocationIdentifier, with context: ClientContext?) -> [UIMenuElement]? {
		guard canDelete(in: context) else {
			return nil
		}

		let deleteAction = UIAction(handler: { [weak self] action in
			self?.delete(in: context)
		})
		deleteAction.title = "Make unavailable offline".localized
		deleteAction.image = UIImage(named: "cloud-unavailable-offline")
		deleteAction.attributes = .destructive

		return [ deleteAction ]
	}
}
