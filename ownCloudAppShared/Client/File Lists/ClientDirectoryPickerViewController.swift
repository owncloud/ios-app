//
//  ClientDirectoryPickerViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 22/08/2018.
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

public typealias ClientDirectoryPickerPathFilter = (_ path: String) -> Bool
public typealias ClientDirectoryPickerChoiceHandler = (_ chosenItem: OCItem?, _ needsToDismissViewController: Bool) -> Void

extension NSErrorDomain {
	static let ClientDirectoryPickerErrorDomain = "ClientDirectoryPickerErrorDomain"
}

open class ClientDirectoryPickerViewController: ClientQueryViewController {

	private let SELECT_BUTTON_HEIGHT: CGFloat = 44.0

	// MARK: - Instance Properties
	open var selectButton: UIBarButtonItem?
	private var selectButtonTitle: String?
	private var cancelBarButton: UIBarButtonItem?

	open var directoryPath : String?

	open var choiceHandler: ClientDirectoryPickerChoiceHandler?
	open var allowedPathFilter : ClientDirectoryPickerPathFilter?
	open var navigationPathFilter : ClientDirectoryPickerPathFilter?
	open var hasFavorites: Bool = true

	// MARK: - Init & deinit
	convenience public init(core inCore: OCCore, path: String, selectButtonTitle: String, avoidConflictsWith items: [OCItem], choiceHandler: @escaping ClientDirectoryPickerChoiceHandler) {
		let folderItemPaths = items.filter({ (item) -> Bool in
			return item.type == .collection && item.path != nil && !item.isRoot
		}).map { (item) -> String in
			return item.path!
		}
		let itemParentPaths = items.filter({ (item) -> Bool in
			return item.path?.parentPath != nil
		}).map { (item) -> String in
			return item.path!.parentPath
		}

		var navigationPathFilter : ClientDirectoryPickerPathFilter?

		if folderItemPaths.count > 0 {
			navigationPathFilter = { (targetPath) in
				return !folderItemPaths.contains(targetPath)
			}
		}

		self.init(core: inCore, path: path, selectButtonTitle: selectButtonTitle, allowedPathFilter: { (targetPath) in
			// Disallow all paths as target that are parent of any of the items
			return !itemParentPaths.contains(targetPath)
		}, navigationPathFilter: navigationPathFilter, choiceHandler: choiceHandler)
	}

	public init(core inCore: OCCore, path: String, selectButtonTitle: String, allowedPathFilter: ClientDirectoryPickerPathFilter? = nil, navigationPathFilter: ClientDirectoryPickerPathFilter? = nil, choiceHandler: @escaping ClientDirectoryPickerChoiceHandler) {
		let targetDirectoryQuery = OCQuery(forPath: path)

		// Sort folders first
		targetDirectoryQuery.sortComparator = { (left, right) in
			guard let leftItem  = left as? OCItem, let rightItem = right as? OCItem else {
				return .orderedSame
			}
			if leftItem.type == OCItemType.collection && rightItem.type != OCItemType.collection {
				return .orderedAscending
			} else if leftItem.type != OCItemType.collection && rightItem.type == OCItemType.collection {
				return .orderedDescending
			} else if leftItem.name != nil && rightItem.name != nil {
				return leftItem.name!.caseInsensitiveCompare(rightItem.name!)
			}
			return .orderedSame
		}

		super.init(core: inCore, query: targetDirectoryQuery, rootViewController: nil)

		self.directoryPath = path

		self.choiceHandler = choiceHandler

		self.selectButtonTitle = selectButtonTitle
		self.allowedPathFilter = allowedPathFilter
		self.navigationPathFilter = navigationPathFilter

		// Force disable sorting options
		self.shallShowSortBar = true

		// Disable pull to refresh
		allowPullToRefresh = false
	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - ViewController lifecycle
	override open func viewDidLoad() {
		super.viewDidLoad()

		// Adapt to disabled pull-to-refresh
		self.tableView.alwaysBounceVertical = false

		// Select button creation
		selectButton = UIBarButtonItem(title: selectButtonTitle, style: .plain, target: self, action: #selector(selectButtonPressed))
		selectButton?.title = selectButtonTitle

		if let allowedPathFilter = allowedPathFilter, let directoryPath = directoryPath {
			selectButton?.isEnabled = allowedPathFilter(directoryPath)
		}

		// Cancel button creation
		cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelBarButtonPressed))

		sortBar?.showSelectButton = false
		tableView.dragInteractionEnabled = false
	}

	override open func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(true)

		if let cancelBarButton = cancelBarButton {
			navigationItem.rightBarButtonItems = [cancelBarButton]
		}

		if let navController = self.navigationController, let selectButton = selectButton {
			navController.isToolbarHidden = false
			navController.toolbar.isTranslucent = false
			let flexibleSpaceBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

			if let leftButtonImage = Theme.shared.image(for: "folder-create", size: CGSize(width: 30.0, height: 30.0))?.withRenderingMode(.alwaysTemplate) {
				let createFolderBarButton = UIBarButtonItem(image: leftButtonImage, style: .plain, target: self, action: #selector(createFolderButtonPressed))
				createFolderBarButton.accessibilityIdentifier = "client.folder-create"

				self.setToolbarItems([createFolderBarButton, flexibleSpaceBarButton, selectButton, flexibleSpaceBarButton], animated: false)
			} else {
				self.setToolbarItems([flexibleSpaceBarButton, selectButton, flexibleSpaceBarButton], animated: false)
			}
		}
	}

	override open func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		sortBar?.showSelectButton = false
	}

	private func allowNavigationFor(item: OCItem?) -> Bool {
		guard let item = item else { return false }

		var allowNavigation = item.type == .collection

		if allowNavigation, let navigationPathFilter = navigationPathFilter, let itemPath = item.path {
			allowNavigation = navigationPathFilter(itemPath)
		}

		return allowNavigation
	}

	// MARK: - Table view data source

	override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if hasFavorites, indexPath.section == 0 {
			return estimatedTableRowHeight
		}

		return UITableView.automaticDimension
	}

	override open func numberOfSections(in tableView: UITableView) -> Int {
		if hasFavorites {
			return 2
		}
		return 1
	}

	override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if hasFavorites, section == 0 {
			return 1
		}

		return self.items.count
	}

	override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if hasFavorites, indexPath.section == 0 {
			let cellStyle = UITableViewCell.CellStyle.default
			let cell = ThemeTableViewCell(withLabelColorUpdates: true, style: cellStyle, reuseIdentifier: nil)
			cell.textLabel?.text = "Favorites".localized
			cell.imageView?.image = UIImage(named: "star")!.paddedTo(width: 40)
			cell.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)

			return cell
		}

		let cell = super.tableView(tableView, cellForRowAt: indexPath)

		if let clientItemCell = cell as? ClientItemCell {
			clientItemCell.isMoreButtonPermanentlyHidden = true
			clientItemCell.isActive = self.allowNavigationFor(item: clientItemCell.item)
		}

		return cell
	}

	override open func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
		if hasFavorites, indexPath.section == 0 {
			return true
		} else if let item : OCItem = itemAt(indexPath: indexPath), allowNavigationFor(item: item) {
			return true
		}

		return false
	}

	override open func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		if hasFavorites, indexPath.section == 0 {
			return indexPath
		} else if let item : OCItem = itemAt(indexPath: indexPath), allowNavigationFor(item: item) {
			return indexPath
		}

		return nil
	}

	override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if hasFavorites, indexPath.section == 0 {
			selectFavoriteItem()
		} else {

			guard let item : OCItem = itemAt(indexPath: indexPath), item.type == OCItemType.collection, let core = self.core, let path = item.path, let selectButtonTitle = selectButtonTitle, let choiceHandler = choiceHandler else {
				return
			}

			let pickerController = ClientDirectoryPickerViewController(core: core, path: path, selectButtonTitle: selectButtonTitle, allowedPathFilter: allowedPathFilter, navigationPathFilter: navigationPathFilter, choiceHandler: choiceHandler)
			pickerController.hasFavorites = false
			pickerController.cancelAction = cancelAction

			self.navigationController?.pushViewController(pickerController, animated: true)
		}
	}

	override open func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		return nil
	}

	override open func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		return .none
	}

	@available(iOS 13.0, *)
	open override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		return nil
	}

	// MARK: - Actions
	open func userChose(item: OCItem?, needsToDismissViewController: Bool) {
		self.choiceHandler?(item, needsToDismissViewController)
	}

	private func dismissWithChoice(item: OCItem?) {
		if self.presentingViewController != nil {
			dismiss(animated: true, completion: {
				self.userChose(item: item, needsToDismissViewController: false)
			})
		} else {
			self.userChose(item: item, needsToDismissViewController: true)
		}
	}

	open var cancelAction : (() -> Void)?

	@objc private func cancelBarButtonPressed() {
		if cancelAction != nil {
			cancelAction?()
 		} else {
			dismissWithChoice(item: nil)
		}
	}

	@objc private func selectButtonPressed() {
		dismissWithChoice(item: self.query.rootItem)
	}

	@objc open func createFolderButtonPressed(_ sender: UIBarButtonItem) {
		// Actions for Create Folder
		if let core = self.core, let rootItem = query.rootItem {
			let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .folderAction)
			let actionContext = ActionContext(viewController: self, core: core, items: [rootItem], location: actionsLocation, sender: sender)

			let actions = Action.sortedApplicableActions(for: actionContext).filter { (action) -> Bool in
				if action.actionExtension.identifier == OCExtensionIdentifier("com.owncloud.action.createFolder") {
					return true
				}

				return false
			}

			let createFolderAction = actions.first
			createFolderAction?.progressHandler = makeActionProgressHandler()
			createFolderAction?.run()
		}
	}

	func selectFavoriteItem() {
		guard let core = self.core else {
			return
		}

		let favoriteQuery = OCQuery(condition: .require([
			.where(.isFavorite, isEqualTo: true),
			.where(.type, isEqualTo: OCItemType.collection.rawValue)
		]), inputFilter:nil)

		let customFileListController = QueryFileListTableViewController(core: core, query: favoriteQuery)
		customFileListController.title = "Favorites".localized
		customFileListController.isMoreButtonPermanentlyHidden = true
		customFileListController.pullToRefreshAction = { [weak self] (completion) in
			self?.core?.refreshFavorites(completionHandler: { (_, _) in
				completion()
			})
		}

		customFileListController.didSelectCellAction = { [weak self, customFileListController] (completion) in
			guard let favoriteIndexPath = customFileListController.tableView?.indexPathForSelectedRow, let item : OCItem = customFileListController.itemAt(indexPath: favoriteIndexPath), item.type == OCItemType.collection, let core = self?.core, let path = item.path, let selectButtonTitle = self?.selectButtonTitle, let choiceHandler = self?.choiceHandler else {
				return
			}

			let pickerController = ClientDirectoryPickerViewController(core: core, path: path, selectButtonTitle: selectButtonTitle, allowedPathFilter: self?.allowedPathFilter, navigationPathFilter: self?.navigationPathFilter, choiceHandler: choiceHandler)
			pickerController.hasFavorites = false
			pickerController.cancelAction = self?.cancelAction

			self?.navigationController?.pushViewController(pickerController, animated: true)
		}

		self.navigationController?.pushViewController(customFileListController, animated: true)
	}
}
