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

	func withCustomIcon(name: String) -> OCSavedSearch {
		customIconName = name
		return self
	}

	func useNameAsTitle(_ useIt: Bool) -> OCSavedSearch {
		useNameAsTitle = useIt
		return self
	}
}

extension OCSavedSearch: DataItemSelectionInteraction {
	func buildViewController(with context: ClientContext) -> ClientItemViewController? {
		if let condition = condition() {
			let query = OCQuery(condition: condition, inputFilter: nil)
			DisplaySettings.shared.updateQuery(withDisplaySettings: query)

			let resultsContext = ClientContext(with: context, modifier: { context in
				context.query = query
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
