//
//  OCShare+Interactions.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 04.01.23.
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
import ownCloudApp

extension OCShare {
	func makeDecision(accept: Bool, context: ClientContext) {
		if let core = context.core {
			core.makeDecision(on: self, accept: accept, completionHandler: { error in
				if let error {
					OnMainThread {
						let alertController = ThemedAlertController(with: (accept ? "Accept Share failed".localized : "Decline Share failed".localized), message: error.localizedDescription, okLabel: "OK".localized, action: nil)
						context.present(alertController, animated: true)
					}
				}
			})
		}
	}

	func accept(in context: ClientContext) {
		makeDecision(accept: true, context: context)
	}

	func decline(in context: ClientContext) {
		makeDecision(accept: false, context: context)
	}
}

extension OCShare: DataItemSwipeInteraction {
	public func provideTrailingSwipeActions(with context: ClientContext?) -> UISwipeActionsConfiguration? {
		guard let context else {
			return nil
		}

		var actions: [UIContextualAction] = []

		if self.state == .pending || self.state == .accepted {
			// Decline
			let declineAction = UIContextualAction(style: .destructive, title: "Decline".localized, handler: { [weak self] (_ action, _ view, _ uiCompletionHandler) in
				uiCompletionHandler(false)
				self?.decline(in: context)
			})
			declineAction.image = OCSymbol.icon(forSymbolName: "minus.circle")

			actions.append(declineAction)
		}

		if self.state == .pending || self.state == .declined {
			// Accept
			let acceptAction = UIContextualAction(style: .normal, title: "Accept".localized, handler: { [weak self] (_ action, _ view, _ uiCompletionHandler) in
				uiCompletionHandler(false)
				self?.accept(in: context)
			})
			acceptAction.image = OCSymbol.icon(forSymbolName: "checkmark")

			actions.append(acceptAction)
		}

		return UISwipeActionsConfiguration(actions: actions)
	}
}

extension OCShare: DataItemContextMenuInteraction {
	public func composeContextMenuItems(in viewController: UIViewController?, location: OCExtensionLocationIdentifier, with context: ClientContext?) -> [UIMenuElement]? {
		guard let context else {
			return nil
		}

		var elements: [UIMenuElement] = []

		if self.state == .pending || self.state == .declined {
			// Accept
			let acceptAction = UIAction(handler: { [weak self] action in
				self?.accept(in: context)
			})
			acceptAction.title = "Accept".localized
			acceptAction.image = OCSymbol.icon(forSymbolName: "checkmark")

			elements.append(acceptAction)
		}

		if self.state == .pending || self.state == .accepted {
			// Decline
			let declineAction = UIAction(handler: { [weak self] action in
				self?.decline(in: context)
			})
			declineAction.title = "Decline".localized
			declineAction.image = OCSymbol.icon(forSymbolName: "minus.circle")
			declineAction.attributes = .destructive

			elements.append(declineAction)
		}

		return elements
	}
}
