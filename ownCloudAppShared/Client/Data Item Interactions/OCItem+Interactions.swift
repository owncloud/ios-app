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
import UniformTypeIdentifiers

// MARK: - Selection > Open
extension OCItem : DataItemSelectionInteraction {
	public func openItem(from viewController: UIViewController?, with context: ClientContext?, animated: Bool, pushViewController: Bool, completion: ((Bool) -> Void)?) -> UIViewController? {
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

	public func revealItem(from viewController: UIViewController?, with context: ClientContext?, animated: Bool, pushViewController: Bool, completion: ((_ success: Bool) -> Void)?) -> UIViewController? {
		if let context = context, let core = context.core {
			let activity = OpenItemUserActivity(detailItem: self, detailBookmark: core.bookmark)
			viewController?.view.window?.windowScene?.userActivity = activity.openItemUserActivity

			if let parentLocation = location?.parent {
				let query = OCQuery(for: parentLocation)
				DisplaySettings.shared.updateQuery(withDisplaySettings: query)

				let queryViewController = ClientItemViewController(context: context, query: query, highlightItemReference: self.dataItemReference)

				if pushViewController {
					context.navigationController?.pushViewController(queryViewController, animated: animated)
				}

				completion?(true)

				return queryViewController
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
		let actionContext = ActionContext(viewController: originatingViewController, clientContext: context, core: core, items: [self], location: actionsLocation, sender: nil)
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
		let actionContext = ActionContext(viewController: viewController, clientContext: context, core: core, items: [item], location: actionsLocation, sender: nil)
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
			let sharingActionContext = ActionContext(viewController: viewController, clientContext: context, core: core, items: [item], location: sharingActionsLocation, sender: nil)
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

// MARK: - Drag
extension OCItem : DataItemDragInteraction {
	public func provideDragItems(with context: ClientContext?) -> [UIDragItem]? {
		guard !DisplaySettings.shared.preventDraggingFiles, let context = context, let core = context.core, let itemLocation = location else {
			return nil
		}
		let bookmark: OCBookmark = core.bookmark
		let item: OCItem = self
		let localObject: LocalDataItem = LocalDataItem(bookmarkUUID: bookmark.uuid, dataItem: item)

		let itemProvider = NSItemProvider()

		// Add suggested name
		itemProvider.suggestedName = item.name

		// All items: register data representation to provide OCLocationData
		itemProvider.registerDataRepresentation(forTypeIdentifier: OCLocationDataTypeIdentifier, visibility: .ownProcess) { (completionHandler) -> Progress? in
			guard let data = itemLocation.data else { return nil }

			completionHandler(data, nil)

			return nil
		}

		// For files: register file representation to provide actual file
		if item.type == .file {
			guard let itemMimeType = item.mimeType else { return nil }
			guard let itemUTI = UTType(mimeType: itemMimeType)?.identifier else { return nil }

			itemProvider.suggestedName = item.name

			itemProvider.registerFileRepresentation(forTypeIdentifier: itemUTI, fileOptions: [], visibility: .all, loadHandler: { [weak core] (completionHandler) -> Progress? in
				var progress : Progress?

				guard let core = core else {
					completionHandler(nil, false, NSError(domain: OCErrorDomain, code: Int(OCError.internal.rawValue), userInfo: nil))
					return nil
				}

				if let localFileURL = core.localCopy(of: item) {
					// Provide local copies directly
					completionHandler(localFileURL, true, nil)
				} else {
					// Otherwise download the file and provide it when done
					progress = core.downloadItem(item, options: [
						.returnImmediatelyIfOfflineOrUnavailable : true,
						.addTemporaryClaimForPurpose : OCCoreClaimPurpose.view.rawValue
					], resultHandler: { (error, core, item, file) in
						guard error == nil, let fileURL = file?.url else {
							completionHandler(nil, false, error)
							return
						}

						completionHandler(fileURL, true, nil)

						if let claim = file?.claim, let item = item {
							core.remove(claim, on: item, afterDeallocationOf: [fileURL])
						}
					})
				}

				return progress
			})
		}

		// Create dragItem from itemProvider and localObject
		let dragItem = UIDragItem(itemProvider: itemProvider)
		dragItem.localObject = localObject

		return [dragItem]
	}
}

// MARK: - Drop
extension OCItem : DataItemDropInteraction {
	public func allowDropOperation(for session: UIDropSession, with context: ClientContext?) -> UICollectionViewDropProposal? {
		if session.localDragSession != nil {
			// Prevent drop of items onto themselves - or in their existing location
			if let dragItems = session.localDragSession?.items, let bookmarkUUID = context?.core?.bookmark.uuid {
				for dragItem in dragItems {
					if let localDataItem = dragItem.localObject as? LocalDataItem {
						if let item = localDataItem.dataItem as? OCItem, localDataItem.bookmarkUUID == bookmarkUUID, item.driveID == driveID, let itemLocation = item.location {
							if (item.path == path) || (itemLocation.parent.path == path) {
								return UICollectionViewDropProposal(operation: .cancel, intent: .unspecified)
							}
						}
					}
				}
			}

			// Return drop proposal based on item type
			if type == .collection {
				return UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
			} else {
				return UICollectionViewDropProposal(operation: .move)
			}
		} else {
			// External items from other apps can only be copied into the app
			return UICollectionViewDropProposal(operation: .copy)
		}
	}

	public func performDropOperation(of droppedItems: [UIDragItem], with context: ClientContext?, handlingCompletion: @escaping (_ didSucceed: Bool) -> Void) {
		guard let core = context?.core, type == .collection else {
			handlingCompletion(false)
			return
		}
		let targetItem = self
		var allSuccessful : Bool = true

		for droppedItem in droppedItems {
			if let localDataItem = droppedItem.localObject as? LocalDataItem, let item = localDataItem.dataItem as? OCItem {
				if localDataItem.bookmarkUUID == context?.core?.bookmark.uuid {
					// Move item within same account
					if let itemName = item.name,
					   let progress = core.move(item, to: targetItem, withName: itemName, options: nil, resultHandler: { (error, _, _, _) in
						if error != nil {
							Log.log("Error \(String(describing: error)) moving \(String(describing: item.path))")
						}
					}) {
						context?.progressSummarizer?.startTracking(progress: progress)
					} else {
						allSuccessful = false
					}
				} else {
					// Copy item from other account
					if let sourceBookmark = OCBookmarkManager.shared.bookmark(for: localDataItem.bookmarkUUID) {
						OCCoreManager.shared.requestCore(for: sourceBookmark, setup: nil) { [weak core] (srcCore, error) in
							if error == nil {
								srcCore?.downloadItem(item, options: nil, resultHandler: { (error, _, srcItem, _) in
									if error == nil, let srcItem = srcItem, let localURL = srcCore?.localCopy(of: srcItem) {
										core?.importItemNamed(srcItem.name, at: targetItem, from: localURL, isSecurityScoped: false, options: nil, placeholderCompletionHandler: nil) { (_, _, _, _) in
										}
									}
								})
							}
						}
					} else {
						allSuccessful = false
					}
				}
			} else {
				// Import item from other sources
				let typeIdentifiers = droppedItem.itemProvider.registeredTypeIdentifiers
				let preferredUTIs : [UTType] = [
					.image,
					.movie,
					.pdf,
					.text,
					.rtf,
					.html,
					.plainText
				]
				var useUTI : String?
				var useIndex : Int = Int.max

				for typeIdentifier in typeIdentifiers {
					if typeIdentifier != OCLocationDataTypeIdentifier, !typeIdentifier.hasPrefix("dyn."), let typeIdentifierUTI = UTType(typeIdentifier) {
						for preferredUTI in preferredUTIs {
							let conforms = typeIdentifierUTI.conforms(to: preferredUTI)

							// Log.log("\(preferredUTI) vs \(typeIdentifier) -> \(conforms)")

							if conforms {
								if let utiIndex = preferredUTIs.firstIndex(of: preferredUTI), utiIndex < useIndex {
									useUTI = typeIdentifier
									useIndex = utiIndex
								}
							}
						}
					}
				}

				if useUTI == nil, typeIdentifiers.count == 1 {
					useUTI = typeIdentifiers.first
				}

				if useUTI == nil {
					useUTI = UTType.data.identifier
				}

				var fileName: String?

				droppedItem.itemProvider.loadFileRepresentation(forTypeIdentifier: useUTI!) { (itemURL, _ error) in
					guard let url = itemURL else { return }

					let fileNameMaxLength = 16

					if useUTI == UTType.utf8PlainText.identifier {
						fileName = try? String(String(contentsOf: url, encoding: .utf8).prefix(fileNameMaxLength) + ".txt")
					}

					if useUTI == UTType.rtf.identifier {
						let options = [NSAttributedString.DocumentReadingOptionKey.documentType : NSAttributedString.DocumentType.rtf]
						fileName = try? String(NSAttributedString(url: url, options: options, documentAttributes: nil).string.prefix(fileNameMaxLength) + ".rtf")
					}

					fileName = fileName?
						.trimmingCharacters(in: .illegalCharacters)
						.trimmingCharacters(in: .whitespaces)
						.trimmingCharacters(in: .newlines)
						.filter({ $0.isASCII })

					if fileName == nil {
						fileName = url.lastPathComponent
					}

					guard let name = fileName else { return }

					if let progress = core.importItemNamed(name, at: targetItem, from: url, isSecurityScoped: false, options: nil, placeholderCompletionHandler: nil, resultHandler: { (error, _ core, _ item, _) in
						if error != nil {
							Log.debug("Error uploading \(Log.mask(name)) file to \(Log.mask(targetItem.path))")
						} else {
							Log.debug("Success uploading \(Log.mask(name)) file to \(Log.mask(targetItem.path))")
						}
					   }) {
						context?.progressSummarizer?.startTracking(progress: progress)
					}
				}
			}
		}

		handlingCompletion(allSuccessful)
	}
}
