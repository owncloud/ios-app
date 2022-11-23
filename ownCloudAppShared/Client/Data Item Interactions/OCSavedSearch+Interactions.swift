//
//  OCSavedSearch+Interactions.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 22.09.22.
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

extension OCSavedSearch {
	func canDelete(in context: ClientContext?) -> Bool {
		guard let context = context, let core = context.core, let savedSearches = core.vault.savedSearches else {
			return false
		}

		return savedSearches.contains(where: { (savedSearch) in
			return savedSearch.uuid == uuid
		})
	}

	func delete(in context: ClientContext?) {
		guard let context = context, let core = context.core else {
			return
		}

		core.vault.delete(self)
	}

	func condition() -> OCQueryCondition? {
		let searchTermCondition = OCQueryCondition.fromSearchTerm(searchTerm)
		var composedCondition = searchTermCondition

		if let location = location {
			var requirements: [OCQueryCondition] = []

			if let driveID = location.driveID {
				requirements.append(OCQueryCondition.where(.driveID, isEqualTo: driveID))
			}

			switch scope {
				case .folder, .container:
					if let path = location.path {
						requirements.append(OCQueryCondition.where(.path, startsWith: path))
					}

				default: break
			}

			if requirements.count > 0 {
				if let searchTermCondition = searchTermCondition {
					requirements.append(searchTermCondition)
				}
				composedCondition = .require(requirements)
			}
		}

		return composedCondition
	}
}

extension OCSavedSearch: DataItemSelectionInteraction {
	public func handleSelection(in viewController: UIViewController?, with context: ClientContext?, completion: ((Bool) -> Void)?) -> Bool {
		if isTemplate {
			if let host = viewController as? SearchViewControllerHost {
				host.searchViewController?.restore(savedTemplate: self)
				completion?(true)
				return true
			}
		} else {
			if let condition = condition(), let context = context {
				let query = OCQuery(condition: condition, inputFilter: nil)
				DisplaySettings.shared.updateQuery(withDisplaySettings: query)

				let resultsContext = ClientContext(with: context, modifier: { context in
					context.query = query
				})

				if context.pushViewControllerToNavigation(context: resultsContext, provider: { context in
					let viewController = ClientItemViewController(context: resultsContext, query: query, showRevealButtonForItems: true)
					viewController.navigationTitle = sideBarDisplayName + " (" + (isTemplate ? "Search template".localized : "Search view".localized) + ")"
					viewController.revoke(in: context, when: .connectionClosed)
					return viewController
				}, push: true, animated: true) != nil {
					completion?(true)
					return true
				}
			}
		}

		completion?(false)
		return false
	}
}

extension OCSavedSearch: DataItemSwipeInteraction {
	public func provideTrailingSwipeActions(with context: ClientContext?) -> UISwipeActionsConfiguration? {
		guard canDelete(in: context) else {
			return nil
		}

		let deleteAction = UIContextualAction(style: .destructive, title: "Delete".localized, handler: { [weak self] (_ action, _ view, _ uiCompletionHandler) in
			uiCompletionHandler(false)
			self?.delete(in: context)
		})
		deleteAction.image = OCSymbol.icon(forSymbolName: "trash")

		return UISwipeActionsConfiguration(actions: [ deleteAction ])
	}
}

extension OCSavedSearch: DataItemContextMenuInteraction {
	public func composeContextMenuItems(in viewController: UIViewController?, location: OCExtensionLocationIdentifier, with context: ClientContext?) -> [UIMenuElement]? {
		guard canDelete(in: context) else {
			return nil
		}

		let deleteAction = UIAction(handler: { [weak self] action in
			self?.delete(in: context)
		})
		deleteAction.title = "Delete".localized
		deleteAction.image = OCSymbol.icon(forSymbolName: "trash")
		deleteAction.attributes = .destructive

		return [ deleteAction ]
	}
}
