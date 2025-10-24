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
			let completionHandler: (Error?) -> Void = { error in
				if let error {
					OnMainThread {
						let alertController = ThemedAlertController(with: (accept ? OCLocalizedString("Accept Share failed", nil) : OCLocalizedString("Decline Share failed", nil)), message: error.localizedDescription, okLabel: OCLocalizedString("OK", nil), action: nil)
						context.present(alertController, animated: true)
					}
				}
			}

			if category == .byMe {
				core.delete(self, completionHandler: completionHandler)
			} else {
				core.makeDecision(on: self, accept: accept, completionHandler: completionHandler)
			}
		}
	}

	func accept(in context: ClientContext) {
		makeDecision(accept: true, context: context)
	}

	func decline(in context: ClientContext) {
		makeDecision(accept: false, context: context)
	}

	var offerAcceptAction: Bool {
		return ((self.effectiveState == .pending || self.effectiveState == .declined) && (self.category == .withMe))
	}

	var offerDeclineAction: Bool {
		return (((self.effectiveState == .pending || self.effectiveState == .accepted) && (self.category == .withMe)) || self.category == .byMe)
	}
}

extension OCShare: DataItemSwipeInteraction {
	public func provideTrailingSwipeActions(with context: ClientContext?) -> UISwipeActionsConfiguration? {
		guard let context else {
			return nil
		}

		var actions: [UIContextualAction] = []

		if offerDeclineAction {
			// Decline / Unshare
			let title = label(for: .decline, in: context)
			let action = UIContextualAction(style: .destructive, title: title, handler: { [weak self] (_ action, _ view, _ uiCompletionHandler) in
				uiCompletionHandler(false)
				self?.decline(in: context)
			})
			action.image = OCSymbol.icon(forSymbolName: iconName(for: .decline, in: context))

			actions.append(action)
		}

		if offerAcceptAction {
			// Accept
			let action = UIContextualAction(style: .normal, title: label(for: .accept, in: context), handler: { [weak self] (_ action, _ view, _ uiCompletionHandler) in
				uiCompletionHandler(false)
				self?.accept(in: context)
			})
			action.image = OCSymbol.icon(forSymbolName: iconName(for: .accept, in: context))

			actions.append(action)
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

		if offerAcceptAction {
			// Accept
			let action = UIAction(handler: { [weak self] action in
				self?.accept(in: context)
			})
			action.title = label(for: .accept, in: context)
			action.image = OCSymbol.icon(forSymbolName: iconName(for: .accept, in: context))

			elements.append(action)
		}

		if offerDeclineAction {
			// Decline / Unshare
			let action = UIAction(handler: { [weak self] action in
				self?.decline(in: context)
			})
			let title = label(for: .decline, in: context)
			action.title = title
			action.image = OCSymbol.icon(forSymbolName: iconName(for: .decline, in: context))
			action.attributes = .destructive

			elements.append(action)
		}

		return elements
	}
}

extension OCShare: DataItemSelectionInteraction {
	public func handleSelection(in viewController: UIViewController?, with context: ClientContext?, completion: ((Bool, Bool) -> Void)?) -> Bool {
		if let context {
			if category == .withMe {
				if effectiveState == .accepted {
					_ = revealItem(from: viewController, with: context, animated: true, pushViewController: true, completion: { success in
						completion?(success, false)
					})
					return true
				}
			} else {
				var editViewController: UIViewController?

				if let otherItemShares, otherItemShares.count > 0, (viewController as? SharingViewController) == nil {
					// Grouped share
					if let item = try? context.core?.cachedItem(at: itemLocation) {
						editViewController = SharingViewController(clientContext: context, item: item)
					}
				} else {
					// Single share
					editViewController = ShareViewController(mode: .edit, share: self, clientContext: context, completion: { _ in })
				}

				if let editViewController {
					let navigationController = ThemeNavigationController(rootViewController: editViewController)
					context.present(navigationController, animated: true)
				}
			}
		}

		completion?(true, false)
		return true
	}

	public func revealItem(from viewController: UIViewController?, with context: ClientContext?, animated: Bool, pushViewController: Bool, completion: ((Bool) -> Void)?) -> UIViewController? {
		if let item = try? context?.core?.cachedItem(at: itemLocation) {
			return item.revealItem(from: viewController, with: context, animated: animated, pushViewController: pushViewController, completion: completion)
		}

		completion?(false)
		return nil
	}
}

// Extension to provide context-dependant labels and icons for shares (adapted to OC10/oCIS + type)
extension OCShare {
	enum Label {
		case pending
		case accepted
		case declined
	}

	enum Element {
		case accept
		case decline
	}

	func iconName(for element: Element, in clientContext: ClientContext?) -> String {
		switch element {
			case .accept:
				return "checkmark.circle"

			case .decline:
				return "minus.circle"
		}
	}

	func label(for element: Element, in clientContext: ClientContext?) -> String {
		let isOcis = clientContext?.core?.useDrives == true

		switch element {
			case .accept:
				return isOcis ? OCLocalizedString("Enable", nil) : OCLocalizedString("Accept", nil)

			case .decline:
				return (category == .byMe) ? OCLocalizedString("Unshare", nil) : (isOcis ? OCLocalizedString("Disable", nil) : OCLocalizedString("Decline", nil))
		}
	}

	static func label(for label: Label, in clientContext: ClientContext?) -> String {
		let isOcis = clientContext?.core?.useDrives == true

		switch label {
			case .pending:
				return OCLocalizedString("Pending", nil)

			case .accepted:
				return isOcis ? OCLocalizedString("Sync enabled", nil) : OCLocalizedString("Accepted", nil)

			case .declined:
				return isOcis ? OCLocalizedString("Sync disabled", nil) : OCLocalizedString("Declined", nil)
		}
	}
}
