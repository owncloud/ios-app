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

typealias ClientDirectoryPickerPathFilter = (_ path: String) -> Bool
typealias ClientDirectoryPickerChoiceHandler = (_ chosenItem: OCItem?) -> Void

class ClientDirectoryPickerViewController: ClientQueryViewController {

	private let SELECT_BUTTON_HEIGHT: CGFloat = 44.0

	// MARK: - Instance Properties
	private var selectButton: UIBarButtonItem?
	private var selectButtonTitle: String?
	private var cancelBarButton: UIBarButtonItem?

	var directoryPath : String?

	var choiceHandler: ClientDirectoryPickerChoiceHandler?
	var allowedPathFilter : ClientDirectoryPickerPathFilter?
	var navigationPathFilter : ClientDirectoryPickerPathFilter?

	// MARK: - Init & deinit
	convenience init(core inCore: OCCore, path: String, selectButtonTitle: String, avoidConflictsWith items: [OCItem], choiceHandler: @escaping ClientDirectoryPickerChoiceHandler) {
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

	init(core inCore: OCCore, path: String, selectButtonTitle: String, allowedPathFilter: ClientDirectoryPickerPathFilter? = nil, navigationPathFilter: ClientDirectoryPickerPathFilter? = nil, choiceHandler: @escaping ClientDirectoryPickerChoiceHandler) {
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

		super.init(core: inCore, query: targetDirectoryQuery)

		self.directoryPath = path

		self.choiceHandler = choiceHandler

		self.selectButtonTitle = selectButtonTitle
		self.allowedPathFilter = allowedPathFilter
		self.navigationPathFilter = navigationPathFilter

		// Force disable sorting options
		self.shallShowSortBar = false

		// Disable pull to refresh
		allowPullToRefresh = false
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - ViewController lifecycle
	override func viewDidLoad() {
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
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(true)

		if let cancelBarButton = cancelBarButton {
			navigationItem.rightBarButtonItems = [cancelBarButton]
		}

		if let navController = self.navigationController, let selectButton = selectButton {
			navController.isToolbarHidden = false
			navController.toolbar.isTranslucent = false
			let flexibleSpaceBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
			self.setToolbarItems([flexibleSpaceBarButton, selectButton, flexibleSpaceBarButton], animated: false)
		}
	}

	private func allowNavigationFor(item: OCItem?) -> Bool {
		guard let item = item else { return false }

		var allowNavigation = item.type == .collection

		if allowNavigation, let navigationPathFilter = navigationPathFilter, let itemPath = item.path {
			allowNavigation = navigationPathFilter(itemPath)
		}

		return allowNavigation
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = super.tableView(tableView, cellForRowAt: indexPath)

		if let clientItemCell = cell as? ClientItemCell {
			clientItemCell.isMoreButtonPermanentlyHidden = true
			clientItemCell.isActive = self.allowNavigationFor(item: clientItemCell.item)
		}

		return cell
	}

	override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
		if let item : OCItem = itemAt(indexPath: indexPath), allowNavigationFor(item: item) {
			return true
		}

		return false
	}

	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		if let item : OCItem = itemAt(indexPath: indexPath), allowNavigationFor(item: item) {
			return indexPath
		}

		return nil
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let item : OCItem = itemAt(indexPath: indexPath), item.type == OCItemType.collection, let core = self.core, let path = item.path, let selectButtonTitle = selectButtonTitle, let choiceHandler = choiceHandler else {
			return
		}

		self.navigationController?.pushViewController(ClientDirectoryPickerViewController(core: core, path: path, selectButtonTitle: selectButtonTitle, allowedPathFilter: allowedPathFilter, navigationPathFilter: navigationPathFilter, choiceHandler: choiceHandler), animated: true)
	}

	override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		return nil
	}

	override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		return .none
	}

	// MARK: - Actions
	func userChose(item: OCItem?) {
		self.choiceHandler?(item)
	}

	@objc private func cancelBarButtonPressed() {
		dismiss(animated: true, completion: {
			self.userChose(item: nil)
		})
	}

	@objc private func selectButtonPressed() {
		dismiss(animated: true, completion: {
			self.userChose(item: self.query.rootItem)
		})
	}
}
