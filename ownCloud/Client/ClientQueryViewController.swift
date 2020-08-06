//
//  ClientQueryViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 05.04.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2018, ownCloud GmbH.
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
import CoreServices

typealias ClientActionVieDidAppearHandler = () -> Void
typealias ClientActionCompletionHandler = (_ actionPerformed: Bool) -> Void

extension OCQueryState {
	var isFinal: Bool {
		switch self {
		case .idle, .targetRemoved, .contentsFromCache, .stopped:
			return true
		default:
			return false
		}
	}
}

struct OCItemDraggingValue {
	var item : OCItem
	var bookmarkUUID : String
}

class ClientQueryViewController: QueryFileListTableViewController, UIDropInteractionDelegate, UIPopoverPresentationControllerDelegate {
	var folderActionBarButton: UIBarButtonItem?
	var plusBarButton: UIBarButtonItem?

	var quotaLabel = UILabel()
	var quotaObservation : NSKeyValueObservation?
	var titleButtonThemeApplierToken : ThemeApplierToken?

	weak var clientRootViewController : ClientRootViewController?

	private var _actionProgressHandler : ActionProgressHandler?

	// MARK: - Init & Deinit
	public override convenience init(core inCore: OCCore, query inQuery: OCQuery) {
		self.init(core: inCore, query: inQuery, rootViewController: nil)
	}

	public init(core inCore: OCCore, query inQuery: OCQuery, rootViewController: ClientRootViewController?) {
		clientRootViewController = rootViewController

		super.init(core: inCore, query: inQuery)

		let lastPathComponent = (query.queryPath as NSString?)!.lastPathComponent

		if lastPathComponent.isRootPath, let shortName = core?.bookmark.shortName {
			self.navigationItem.title = shortName
		} else {
			let titleButton = UIButton()
			titleButton.setTitle(lastPathComponent, for: .normal)
			titleButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
			titleButton.addTarget(self, action: #selector(showPathBreadCrumb(_:)), for: .touchUpInside)
			titleButton.sizeToFit()
			titleButton.accessibilityLabel = "Show parent paths".localized
			titleButton.accessibilityIdentifier = "show-paths-button"
			titleButton.semanticContentAttribute = (titleButton.effectiveUserInterfaceLayoutDirection == .leftToRight) ? .forceRightToLeft : .forceLeftToRight
			titleButton.setImage(UIImage(named: "chevron-small-light"), for: .normal)
			titleButtonThemeApplierToken = Theme.shared.add(applier: { (_, collection, _) in
				titleButton.setTitleColor(collection.navigationBarColors.labelColor, for: .normal)
				titleButton.tintColor = collection.navigationBarColors.labelColor
			})
			self.navigationItem.titleView = titleButton
		}

		if lastPathComponent.isRootPath {
			quotaObservation = core?.observe(\OCCore.rootQuotaBytesUsed, options: [.initial], changeHandler: { [weak self, core] (_, _) in
				let quotaUsed = core?.rootQuotaBytesUsed?.int64Value ?? 0

				OnMainThread {
					var footerText: String?

					if quotaUsed > 0 {

						let byteCounterFormatter = ByteCountFormatter()
						byteCounterFormatter.allowsNonnumericFormatting = false

						let quotaUsedFormatted = byteCounterFormatter.string(fromByteCount: quotaUsed)

						// A rootQuotaBytesRemaining value of nil indicates that no quota has been set
						if core?.rootQuotaBytesRemaining != nil, let quotaTotal = core?.rootQuotaBytesTotal?.int64Value {
							let quotaTotalFormatted = byteCounterFormatter.string(fromByteCount: quotaTotal )
							footerText = String(format: "%@ of %@ used".localized, quotaUsedFormatted, quotaTotalFormatted)
						} else {
							footerText = String(format: "Total: %@".localized, quotaUsedFormatted)
						}
					}

					self?.updateFooter(text: footerText)
				}
			})
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		queryStateObservation = nil
		quotaObservation = nil

		if titleButtonThemeApplierToken != nil {
			Theme.shared.remove(applierForToken: titleButtonThemeApplierToken)
			titleButtonThemeApplierToken = nil
		}
	}

	// MARK: - View controller events
	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.dragDelegate = self
		self.tableView.dropDelegate = self
		self.tableView.dragInteractionEnabled = true

		folderActionBarButton = UIBarButtonItem(image: UIImage(named: "more-dots"), style: .plain, target: self, action: #selector(moreBarButtonPressed))
		folderActionBarButton?.accessibilityIdentifier = "client.folder-action"
		plusBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(plusBarButtonPressed))
		plusBarButton?.accessibilityIdentifier = "client.file-add"

		self.navigationItem.rightBarButtonItems = [folderActionBarButton!, plusBarButton!]

		quotaLabel.textAlignment = .center
		quotaLabel.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
		quotaLabel.numberOfLines = 0
	}

	private var viewControllerVisible : Bool = false

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		leaveMultipleSelection()
	}

	private func updateFooter(text:String?) {
		let labelText = text ?? ""

		// Resize quota label
		self.quotaLabel.text = labelText
		self.quotaLabel.sizeToFit()
		var frame = self.quotaLabel.frame
		// Width is ignored and set by the UITableView when assigning to tableFooterView property
		frame.size.height = floor(self.quotaLabel.frame.size.height * 2.0)
		quotaLabel.frame = frame
		self.tableView.tableFooterView = quotaLabel
	}

	// MARK: - Theme support
	override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		super.applyThemeCollection(theme: theme, collection: collection, event: event)

		self.quotaLabel.textColor = collection.tableRowColors.secondaryLabelColor
	}

	// MARK: - Table view delegate

	override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
		return true
	}

	func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
		for item in session.items {
			if item.localObject == nil, item.itemProvider.hasItemConformingToTypeIdentifier("public.folder") {
				return false
			} else if let itemValues = item.localObject as? OCItemDraggingValue, let core = self.core, core.bookmark.uuid.uuidString != itemValues.bookmarkUUID, itemValues.item.type == .collection {
				return false
			}
		}
		return true
	}

	func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {

		if session.localDragSession != nil {
				if let indexPath = destinationIndexPath, items.count - 1 < indexPath.row {
					return UITableViewDropProposal(operation: .forbidden)
				}

				if let indexPath = destinationIndexPath, items[indexPath.row].type == .file {
					return UITableViewDropProposal(operation: .move)
				} else {
					return UITableViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
				}
		} else {
			return UITableViewDropProposal(operation: .copy)
		}
	}

	func updateToolbarItemsForDropping(_ draggingValues: [OCItemDraggingValue]) {
		guard let tabBarController = self.tabBarController as? ClientRootViewController else { return }
		guard let toolbarItems = tabBarController.toolbar?.items else { return }

		if let core = self.core {
			let items = draggingValues.map({(value: OCItemDraggingValue) -> OCItem in
				return value.item
			})
			// Remove duplicates
			let uniqueItems = Array(Set(items))
			// Get possible associated actions
			let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .toolbar)
			let actionContext = ActionContext(viewController: self, core: core, query: query, items: uniqueItems, location: actionsLocation)
			self.actions = Action.sortedApplicableActions(for: actionContext)

			// Enable / disable tool-bar items depending on action availability
			for item in toolbarItems {
				if self.actions?.contains(where: {type(of:$0).identifier == item.actionIdentifier}) ?? false {
					item.isEnabled = true
				} else {
					item.isEnabled = false
				}
			}
		}

	}

	func tableView(_: UITableView, dragSessionDidEnd: UIDragSession) {
		if !self.tableView.isEditing {
			removeToolbar()
		}
	}

	// MARK: - UIBarButtonItem Drop Delegate

	func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
		return true
	}

	func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
		return UIDropProposal(operation: .copy)
	}

	func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
		guard let button = interaction.view as? UIButton, let identifier = button.actionIdentifier  else { return }

		if let action = self.actions?.first(where: {type(of:$0).identifier == identifier}) {
			// Configure progress handler
			action.progressHandler = makeActionProgressHandler()

			action.completionHandler = { (_, _) in
			}

			// Execute the action
			action.perform()
		}
	}

	func dragInteraction(_ interaction: UIDragInteraction,
						 session: UIDragSession,
						 didEndWith operation: UIDropOperation) {
		removeToolbar()
	}

	// MARK: - Upload
	func upload(itemURL: URL, name: String, completionHandler: ClientActionCompletionHandler? = nil) {
		if let rootItem = query.rootItem,
		   let progress = core?.importItemNamed(name, at: rootItem, from: itemURL, isSecurityScoped: false, options: nil, placeholderCompletionHandler: nil, resultHandler: { (error, _ core, _ item, _) in
			if error != nil {
				Log.debug("Error uploading \(Log.mask(name)) file to \(Log.mask(rootItem.path))")
				completionHandler?(false)
			} else {
				Log.debug("Success uploading \(Log.mask(name)) file to \(Log.mask(rootItem.path))")
				completionHandler?(true)
			}
		}) {
			self.progressSummarizer?.startTracking(progress: progress)
		}
	}

	override func leaveMultipleSelection() {
		super.leaveMultipleSelection()
		self.navigationItem.rightBarButtonItems = [folderActionBarButton!, plusBarButton!]
	}

	// MARK: - Navigation Bar Actions

	@objc func plusBarButtonPressed(_ sender: UIBarButtonItem) {
		let controller = ThemedAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		// Actions for folderAction
		if let core = self.core, let rootItem = query.rootItem {
			let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .folderAction)
			let actionContext = ActionContext(viewController: self, core: core, items: [rootItem], location: actionsLocation, sender: sender)

			let actions = Action.sortedApplicableActions(for: actionContext)

			if actions.count == 0 {
				// Handle case of no actions
				let alert = ThemedAlertController(title: "No actions available".localized, message: "No actions are available for this folder, possibly because of missing permissions.".localized, preferredStyle: .alert)

				alert.addAction(UIAlertAction(title: "OK".localized, style: .default))

				self.present(alert, animated: true)

				return
			}

			for action in actions {
				action.progressHandler = makeActionProgressHandler()

				if let controllerAction = action.provideAlertAction() {
					controller.addAction(controllerAction)
				}
			}
		}

		// Cancel button
		let cancelAction = UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil)
		controller.addAction(cancelAction)

		if let popoverController = controller.popoverPresentationController {
			popoverController.barButtonItem = sender
		}

		self.present(controller, animated: true)
	}

	@objc func moreBarButtonPressed(_ sender: UIBarButtonItem) {
		guard let core = core, let rootItem = self.query.rootItem else {
			return
		}

		let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .moreFolder)
		let actionContext = ActionContext(viewController: self, core: core, query: query, items: [rootItem], location: actionsLocation, sender: sender)

		if let moreViewController = Action.cardViewController(for: rootItem, with: actionContext, progressHandler: makeActionProgressHandler()) {
			self.present(asCard: moreViewController, animated: true)
		}
	}

	// MARK: - Path Bread Crumb Action
	@objc func showPathBreadCrumb(_ sender: UIButton) {
		let tableViewController = BreadCrumbTableViewController()
		tableViewController.modalPresentationStyle = UIModalPresentationStyle.popover
		tableViewController.parentNavigationController = self.navigationController
		tableViewController.queryPath = (query.queryPath as NSString?)!
		if let shortName = core?.bookmark.shortName {
			tableViewController.bookmarkShortName = shortName
		}

		if #available(iOS 13, *) {
 			// On iOS 13.0/13.1, the table view's content needs to be inset by the height of the arrow
 			// (this can hopefully be removed again in the future, if/when Apple addresses the issue)
 			let popoverArrowHeight : CGFloat = 13

  			tableViewController.tableView.contentInsetAdjustmentBehavior = .never
 			tableViewController.tableView.contentInset = UIEdgeInsets(top: popoverArrowHeight, left: 0, bottom: 0, right: 0)
 			tableViewController.tableView.separatorInset = UIEdgeInsets()
 		}

		let popoverPresentationController = tableViewController.popoverPresentationController
		popoverPresentationController?.sourceView = sender
		popoverPresentationController?.delegate = self
		popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: sender.frame.size.width, height: sender.frame.size.height)

		present(tableViewController, animated: true, completion: nil)
	}

	// MARK: - ClientItemCell item resolution
	override func item(for cell: ClientItemCell) -> OCItem? {
		guard let indexPath = self.tableView.indexPath(for: cell) else {
			return nil
		}

		return self.itemAt(indexPath: indexPath)
	}

	override func hasMessage(for item: OCItem) -> Bool {
		guard let activeSyncRecordIDs = item.activeSyncRecordIDs, let syncRecordIDsWithMessages = clientRootViewController?.syncRecordIDsWithMessages else {
			return false
		}

		return syncRecordIDsWithMessages.contains { (syncRecordID) -> Bool in
			return activeSyncRecordIDs.contains(syncRecordID)
		}
	}

	override func messageButtonTapped(cell: ClientItemCell) {
		if let item = cell.item {
			self.showMessageFor(item: item)
		}
	}

	// MARK: - Show message for item
	func showMessageFor(item: OCItem) {
		if let messages = clientRootViewController?.messageSelector?.selection,
		   let firstMatchingMessage = messages.first(where: { (message) -> Bool in
			guard let syncRecordID = message.syncIssue?.syncRecordID, let containsSyncRecordID = item.activeSyncRecordIDs?.contains(syncRecordID) else {
				return false
			}

			return containsSyncRecordID
		}) {
			firstMatchingMessage.showInApp()
		}
	}

	// MARK: - Updates
	override func performUpdatesWithQueryChanges(query: OCQuery, changeSet: OCQueryChangeSet?) {
		if let rootItem = self.query.rootItem {
			if query.queryPath != "/" {
				let totalSize = String(format: "Total: %@".localized, rootItem.sizeLocalized)
				self.updateFooter(text: totalSize)
			}

			if #available(iOS 13.0, *) {
				if  let tabBarController = self.tabBarController as? ClientRootViewController {
					// Use parent folder for UI state restoration
					let activity = OpenItemUserActivity(detailItem: rootItem, detailBookmark: tabBarController.bookmark)
					view.window?.windowScene?.userActivity = activity.openItemUserActivity
				}
			}
		}
	}

	// MARK: - Reloads
	override func restoreSelectionAfterTableReload() {
		// Restore previously selected items
		guard tableView.isEditing else { return }

		guard selectedItemIds.count > 0 else { return }

		for row in 0..<self.items.count {
			if let itemLocalID = self.items[row].localID as OCLocalID? {
				if selectedItemIds.contains(itemLocalID) {
					self.tableView.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: .none)
				}
			}
		}
	}

	// MARK: - UIPopoverPresentationControllerDelegate
	func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
		return .none
	}

	func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
		popoverPresentationController.backgroundColor = Theme.shared.activeCollection.tableBackgroundColor
	}
}

extension OCBookmarkManager {
	public func bookmark(for uuidString: String) -> OCBookmark? {
		return OCBookmarkManager.shared.bookmarks.filter({ $0.uuid.uuidString == uuidString}).first
	}
}

// MARK: - Drag & Drop delegates
extension ClientQueryViewController: UITableViewDropDelegate {
	func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
		guard let core = self.core else { return }

		for item in coordinator.items {
			if item.dragItem.localObject != nil {

				var destinationItem: OCItem

				guard let itemValues = item.dragItem.localObject as? OCItemDraggingValue, let itemName = itemValues.item.name, let sourceBookmark = OCBookmarkManager.shared.bookmark(for: itemValues.bookmarkUUID) else {
					return
				}
				let item = itemValues.item

				if coordinator.proposal.intent == .insertIntoDestinationIndexPath {

					guard let destinationIndexPath = coordinator.destinationIndexPath else {
						return
					}

					guard items.count >= destinationIndexPath.row else {
						return
					}

					let rootItem = items[destinationIndexPath.row]

					guard rootItem.type == .collection else {
						return
					}

					destinationItem = rootItem

				} else {

					guard let rootItem = self.query.rootItem, item.parentFileID != rootItem.fileID else {
						return
					}

					destinationItem =  rootItem

				}

				// Move Items in the same Account
				if core.bookmark.uuid.uuidString == itemValues.bookmarkUUID {
					if let progress = core.move(item, to: destinationItem, withName: itemName, options: nil, resultHandler: { (error, _, _, _) in
						if error != nil {
							Log.log("Error \(String(describing: error)) moving \(String(describing: item.path))")
						}
					}) {
						self.progressSummarizer?.startTracking(progress: progress)
					}
				// Copy Items between Accounts
				} else {
					OCCoreManager.shared.requestCore(for: sourceBookmark, setup: nil) { (srcCore, error) in
						if error == nil {
							srcCore?.downloadItem(item, options: nil, resultHandler: { (error, _, srcItem, _) in
								if error == nil, let srcItem = srcItem, let localURL = srcCore?.localCopy(of: srcItem) {
									core.importItemNamed(srcItem.name, at: destinationItem, from: localURL, isSecurityScoped: false, options: nil, placeholderCompletionHandler: nil) { (error, _, _, _) in
										if error == nil {

										}
									}
								}
							})
						}
					}
				}
			// Import Items from outside
			} else {
				guard let UTI = item.dragItem.itemProvider.registeredTypeIdentifiers.last else { return }
				item.dragItem.itemProvider.loadFileRepresentation(forTypeIdentifier: UTI) { (url, _ error) in
					guard let url = url else { return }
					self.upload(itemURL: url, name: url.lastPathComponent)
				}
			}
		}
	}
}

extension ClientQueryViewController: UITableViewDragDelegate {

	func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {

		if DisplaySettings.shared.preventDraggingFiles {
			return [UIDragItem]()
		}

		if !self.tableView.isEditing {
			self.populateToolbar()
		}

		var selectedItems = [OCItemDraggingValue]()
		// Add Items from Multiselection too
		if let selectedIndexPaths = self.tableView.indexPathsForSelectedRows {
			if selectedIndexPaths.count > 0 {
				for indexPath in selectedIndexPaths {
					if let selectedItem : OCItem = itemAt(indexPath: indexPath), let uuid = core?.bookmark.uuid.uuidString {
						let draggingValue = OCItemDraggingValue(item: selectedItem, bookmarkUUID: uuid)
						selectedItems.append(draggingValue)
					}
				}
			}
		}
		for dragItem in session.items {
			guard let item = dragItem.localObject as? OCItem, let uuid = core?.bookmark.uuid.uuidString else { continue }
			let draggingValue = OCItemDraggingValue(item: item, bookmarkUUID: uuid)
			selectedItems.append(draggingValue)
		}

		if let item: OCItem = itemAt(indexPath: indexPath), let uuid = core?.bookmark.uuid.uuidString {
			let draggingValue = OCItemDraggingValue(item: item, bookmarkUUID: uuid)
			selectedItems.append(draggingValue)

			updateToolbarItemsForDropping(selectedItems)

			guard let dragItem = itemForDragging(draggingValue: draggingValue) else { return [] }
			return [dragItem]
		}

		return []
	}

	func tableView(_ tableView: UITableView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
		var selectedItems = [OCItemDraggingValue]()
		for dragItem in session.items {
			guard let item = dragItem.localObject as? OCItem, let uuid = core?.bookmark.uuid.uuidString else { continue }
			let draggingValue = OCItemDraggingValue(item: item, bookmarkUUID: uuid)
			selectedItems.append(draggingValue)
		}

		if let item: OCItem = itemAt(indexPath: indexPath), let uuid = core?.bookmark.uuid.uuidString {
			let draggingValue = OCItemDraggingValue(item: item, bookmarkUUID: uuid)
			selectedItems.append(draggingValue)

			updateToolbarItemsForDropping(selectedItems)

			guard let dragItem = itemForDragging(draggingValue: draggingValue) else { return [] }
			return [dragItem]
		}

		return []
	}

	func itemForDragging(draggingValue : OCItemDraggingValue) -> UIDragItem? {
		let item = draggingValue.item
		if let core = self.core {
			switch item.type {
			case .collection:
				guard let data = item.serializedData() else { return nil }
				let itemProvider = NSItemProvider(item: data as NSData, typeIdentifier: kUTTypeData as String)
				let dragItem = UIDragItem(itemProvider: itemProvider)
				dragItem.localObject = draggingValue
				return dragItem
			case .file:
				guard let itemMimeType = item.mimeType else { return nil }
				let mimeTypeCF = itemMimeType as CFString

				guard let rawUti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeTypeCF, nil)?.takeRetainedValue() else { return nil }

				if let fileData = NSData(contentsOf: core.localURL(for: item)) {
					let rawUtiString = rawUti as String
					let itemProvider = NSItemProvider(item: fileData, typeIdentifier: rawUtiString)
					itemProvider.suggestedName = item.name
					let dragItem = UIDragItem(itemProvider: itemProvider)
					dragItem.localObject = draggingValue
					return dragItem
				} else {
					guard let data = item.serializedData() else { return nil }
					let itemProvider = NSItemProvider(item: data as NSData, typeIdentifier: kUTTypeData as String)
					let dragItem = UIDragItem(itemProvider: itemProvider)
					dragItem.localObject = draggingValue
					return dragItem
				}
			}
		}

		return nil
	}
}

// MARK: - UINavigationControllerDelegate
extension ClientQueryViewController: UINavigationControllerDelegate {}
