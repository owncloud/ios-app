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

extension OCSavedSearchUserInfoKey {
	static let customIconName = OCSavedSearchUserInfoKey(rawValue: "customIconName")
	static let useNameAsTitle = OCSavedSearchUserInfoKey(rawValue: "useNameAsTitle")
	static let useSortDescriptor = OCSavedSearchUserInfoKey(rawValue: "useSortDescriptor")
	static let isQuickAccess = OCSavedSearchUserInfoKey(rawValue: "isQuickAccess")
}

extension OCSavedSearch {
	func canDelete(in context: ClientContext?) -> Bool {
		guard let context = context, let core = context.core, let savedSearches = core.vault.savedSearches else {
			return false
		}

		return savedSearches.contains(where: { (savedSearch) in
			return savedSearch.uuid == uuid
		})
	}

	func canRename(in context: ClientContext?) -> Bool {
		return canDelete(in: context) && (isQuickAccess != true)
	}

	func delete(in context: ClientContext?) {
		guard let context = context, let core = context.core else {
			return
		}

		core.vault.delete(self)
	}

	func rename(in context: ClientContext?) {
		guard let context = context, context.core != nil else {
			return
		}

		let namePrompt = UIAlertController(title: "Name of saved search".localized, message: nil, preferredStyle: .alert)

		namePrompt.addTextField(configurationHandler: { textField in
			textField.placeholder = "Saved search".localized
			textField.text = self.isNameUserDefined ? self.name : ""
		})

		namePrompt.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
		namePrompt.addAction(UIAlertAction(title: "Save".localized, style: .default, handler: { [weak self, weak namePrompt] action in
			guard let self else {
				return
			}
			self.name = namePrompt?.textFields?.first?.text ?? ""

			context.core?.vault.update(self)
		}))

		context.present(namePrompt, animated: true)
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
				case .folder:
					if let path = location.path {
						requirements.append(OCQueryCondition.where(.parentPath, isEqualTo: path))
					}

				case .container:
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

	var customIconName: String? {
		set {
			if userInfo == nil, let newValue {
				userInfo = [.customIconName : newValue]
			} else {
				userInfo?[.customIconName] = newValue
			}
		}

		get {
			return userInfo?[.customIconName] as? String
		}
	}

	var useNameAsTitle: Bool? {
		set {
			if userInfo == nil, let newValue {
				userInfo = [.useNameAsTitle : newValue]
			} else {
				userInfo?[.useNameAsTitle] = newValue
			}
		}

		get {
			return userInfo?[.useNameAsTitle] as? Bool
		}
	}

	var useSortDescriptor: SortDescriptor? {
		set {
			if userInfo == nil, let newValue {
				userInfo = [.useSortDescriptor : newValue]
			} else {
				userInfo?[.useSortDescriptor] = newValue
			}
		}

		get {
			return userInfo?[.useSortDescriptor] as? SortDescriptor
		}
	}

	var isQuickAccess: Bool? {
		set {
			if userInfo == nil, let newValue {
				userInfo = [.isQuickAccess : newValue]
			} else {
				userInfo?[.isQuickAccess] = newValue
			}
		}

		get {
			return userInfo?[.isQuickAccess] as? Bool
		}
	}

	func withCustomIcon(name: String) -> OCSavedSearch {
		customIconName = name
		return self
	}

	func useNameAsTitle(_ useIt: Bool) -> OCSavedSearch {
		useNameAsTitle = useIt
		return self
	}

	func useSortDescriptor(_ sortDescriptor: SortDescriptor) -> OCSavedSearch {
		useSortDescriptor = sortDescriptor
		return self
	}

	func isQuickAccess(_ isQuickAccess: Bool) -> OCSavedSearch {
		self.isQuickAccess = isQuickAccess
		return self
	}
}

extension OCSavedSearch: DataItemSelectionInteraction {
	func buildViewController(with context: ClientContext) -> ClientItemViewController? {
		if let condition = condition() {
			let query = OCQuery(condition: condition, inputFilter: nil)
			let useSortDescriptor = useSortDescriptor
			DisplaySettings.shared.updateQuery(withDisplaySettings: query)

			let resultsContext = ClientContext(with: context, modifier: { context in
				context.query = query
				if let useSortDescriptor {
					context.sortDescriptor = useSortDescriptor
				}
			})

			let viewController = ClientItemViewController(context: resultsContext, query: query, showRevealButtonForItems: true, emptyItemListIcon: OCSymbol.icon(forSymbolName: "magnifyingglass"), emptyItemListTitleLocalized: "No matches".localized, emptyItemListMessageLocalized: "No items found matching the search criteria.".localized)
			if self.useNameAsTitle == true {
				viewController.navigationTitle = sideBarDisplayName
			} else {
				viewController.navigationTitle = sideBarDisplayName + " (" + (isTemplate ? "Search template".localized : "Saved search".localized) + ")"
			}
			viewController.revoke(in: context, when: .connectionClosed)
			viewController.navigationBookmark = BrowserNavigationBookmark.from(dataItem: self, clientContext: context, restoreAction: .handleSelection)
			return viewController
		}

		return nil
	}

	public func handleSelection(in viewController: UIViewController?, with context: ClientContext?, completion: ((Bool, Bool) -> Void)?) -> Bool {
		if isTemplate {
			if let host = viewController as? SearchViewControllerHost {
				host.searchViewController?.restore(savedTemplate: self)
				completion?(true, false)
				return true
			}
		} else {
			if let context = context, let viewController = buildViewController(with: context) {
				let resultsContext = viewController.clientContext

				if context.pushViewControllerToNavigation(context: resultsContext, provider: { context in
					return viewController
				}, push: true, animated: true) != nil {
					completion?(true, false)
					return true
				}
			}
		}

		completion?(false, false)
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
		let canDelete = canDelete(in: context), canRename = canRename(in: context)
		var actions: [UIMenuElement] = []

		guard canDelete || canRename else {
			return nil
		}

		if canRename {
			let renameAction = UIAction(handler: { [weak self] action in
				self?.rename(in: context)
			})
			renameAction.title = "Rename".localized
			renameAction.image = OCSymbol.icon(forSymbolName: "pencil")

			actions.append(renameAction)
		}

		if canDelete {
			let deleteAction = UIAction(handler: { [weak self] action in
				self?.delete(in: context)
			})
			deleteAction.title = "Delete".localized
			deleteAction.image = OCSymbol.icon(forSymbolName: "trash")
			deleteAction.attributes = .destructive

			actions.append(deleteAction)
		}

		return actions
	}
}

// MARK: - BrowserNavigationBookmark (re)store
extension OCSavedSearch: DataItemBrowserNavigationBookmarkReStore {
	public func store(in bookmarkUUID: UUID?, context: ClientContext?, restoreAction: BrowserNavigationBookmark.BookmarkRestoreAction) -> BrowserNavigationBookmark? {
		let navigationBookmark = BrowserNavigationBookmark(for: self, in: bookmarkUUID, restoreAction: restoreAction)

		navigationBookmark?.savedSearch = self

		return navigationBookmark
	}

	public static func restore(navigationBookmark: BrowserNavigationBookmark, in viewController: UIViewController?, with context: ClientContext?, completion: ((Error?, UIViewController?) -> Void)) {
		if let savedSearch = navigationBookmark.savedSearch, let context {
			let viewController = savedSearch.buildViewController(with: context)
			completion(nil, viewController)
		} else {
			completion(NSError(ocError: .insufficientParameters), nil)
		}
	}
}
