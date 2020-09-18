//
//  QueryFileListTableViewController+Multiselect.swift
//  ownCloud
//
//  Created by Felix Schwarz on 17.07.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2020, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK
import ownCloudAppShared

extension QueryFileListTableViewController : MultiSelectSupport {

	public func setupMultiselection() {
		selectDeselectAllButtonItem = UIBarButtonItem(title: "Select All".localized, style: .done, target: self, action: #selector(selectAllItems))
		exitMultipleSelectionBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(exitMultiselection))

		// Create bar button items for the toolbar
		deleteMultipleBarButtonItem = UIBarButtonItem(image: UIImage(named:"trash"), target: self as AnyObject, action: #selector(actOnMultipleItems), dropTarget: self, actionIdentifier: DeleteAction.identifier!)
		deleteMultipleBarButtonItem?.accessibilityLabel = "Delete".localized
		deleteMultipleBarButtonItem?.isEnabled = false

		moveMultipleBarButtonItem = UIBarButtonItem(image: UIImage(named:"folder"), target: self as AnyObject, action: #selector(actOnMultipleItems), dropTarget: self, actionIdentifier: MoveAction.identifier!)
		moveMultipleBarButtonItem?.accessibilityLabel = "Move".localized
		moveMultipleBarButtonItem?.isEnabled = false

		duplicateMultipleBarButtonItem = UIBarButtonItem(image: UIImage(named: "duplicate-file"), target: self as AnyObject, action: #selector(actOnMultipleItems), dropTarget: self, actionIdentifier: DuplicateAction.identifier!)
		duplicateMultipleBarButtonItem?.accessibilityLabel = "Duplicate".localized
		duplicateMultipleBarButtonItem?.isEnabled = false

		copyMultipleBarButtonItem = UIBarButtonItem(image: UIImage(named: "copy-file"), target: self as AnyObject, action: #selector(actOnMultipleItems), dropTarget: self, actionIdentifier: CopyAction.identifier!)
		copyMultipleBarButtonItem?.accessibilityLabel = "Copy".localized
		copyMultipleBarButtonItem?.isEnabled = false

		openMultipleBarButtonItem = UIBarButtonItem(image: UIImage(named: "open-in"), target: self as AnyObject, action: #selector(actOnMultipleItems), dropTarget: self, actionIdentifier: OpenInAction.identifier!)
		openMultipleBarButtonItem?.accessibilityLabel = "Open in".localized
		openMultipleBarButtonItem?.isEnabled = false
	}

	// MARK: - Toolbar actions handling multiple selected items
	fileprivate func updateSelectDeselectAllButton() {
		var selectedCount = 0
		if let selectedIndexPaths = self.tableView.indexPathsForSelectedRows {
			selectedCount = selectedIndexPaths.count
		}

		if selectedCount == self.items.count {
			selectDeselectAllButtonItem?.title = "Deselect All".localized
			selectDeselectAllButtonItem?.target = self
			selectDeselectAllButtonItem?.action = #selector(deselectAllItems)
		} else {
			selectDeselectAllButtonItem?.title = "Select All".localized
			selectDeselectAllButtonItem?.target = self
			selectDeselectAllButtonItem?.action = #selector(selectAllItems)
		}
		self.navigationItem.titleView = nil
 		if selectedCount == 1 {
 			self.navigationItem.title = String(format: "%d Item".localized, selectedCount)
 		} else if selectedCount > 1 {
 			self.title = String(format: "%d Items".localized, selectedCount)
 		} else {
			self.navigationItem.title = UIDevice.current.isIpad ? "Select Items".localized : ""
 		}
	}

	fileprivate func updateActions() {
		guard let tabBarController = self.tabBarController as? ClientRootViewController else { return }

		guard let toolbarItems = tabBarController.toolbar?.items else { return }

		if selectedItemIds.count > 0 {
			if let context = self.actionContext {

				self.actions = Action.sortedApplicableActions(for: context)

				// Enable / disable tool-bar items depending on action availability
				for item in toolbarItems {
					if self.actions?.contains(where: {type(of:$0).identifier == item.actionIdentifier}) ?? false {
						item.isEnabled = true
					} else {
						item.isEnabled = false
					}
				}
			}

		} else {
			self.actions = nil
			for item in toolbarItems {
				item.isEnabled = false
			}
		}
	}

	@objc public func exitMultiselection() {
		if self.tableView.isEditing {
			self.tableView.setEditing(false, animated: true)

			selectedItemIds.removeAll()
			removeToolbar()
			sortBar?.showSelectButton = true

			if #available(iOS 13, *) {
				self.tableView.overrideUserInterfaceStyle = .unspecified
			}

			self.navigationItem.rightBarButtonItems = self.regularRightBarButtons
			self.navigationItem.leftBarButtonItems = self.regularLeftBarButtons

			self.regularRightBarButtons = nil
			self.regularLeftBarButtons = nil

			exitedMultiselection()
		}
	}

	@objc public func exitedMultiselection() {
		// may be overriden in subclasses
	}

	@objc public func updateMultiselection() {
		updateSelectDeselectAllButton()
		updateActions()
	}

	open func populateToolbar() {
		self.populateToolbar(with: [
			openMultipleBarButtonItem!,
			flexibleSpaceBarButton,
			moveMultipleBarButtonItem!,
			flexibleSpaceBarButton,
			copyMultipleBarButtonItem!,
			flexibleSpaceBarButton,
			duplicateMultipleBarButtonItem!,
			flexibleSpaceBarButton,
			deleteMultipleBarButtonItem!])
	}

	@objc func actOnMultipleItems(_ sender: UIButton) {
		// Find associated action
		if let action = self.actions?.first(where: {type(of:$0).identifier == sender.actionIdentifier}) {
			// Configure progress handler
			action.context.sender = self.tabBarController
			action.progressHandler = makeActionProgressHandler()

			action.completionHandler = { [weak self] (_, _) in
				OnMainThread {
					self?.exitMultiselection()
				}
			}

			// Execute the action
			action.perform()
		}
	}

	// MARK: Multiple Selection

	@objc public func enterMultiselection() {

		if #available(iOS 13, *) {
			self.tableView.overrideUserInterfaceStyle = Theme.shared.activeCollection.interfaceStyle.userInterfaceStyle
		}

		if !self.tableView.isEditing {
			self.regularLeftBarButtons = self.navigationItem.leftBarButtonItems
			self.regularRightBarButtons = self.navigationItem.rightBarButtonItems
		}

		updateMultiselection()

		self.tableView.setEditing(true, animated: true)
		sortBar?.showSelectButton = false

		populateToolbar()

		self.navigationItem.leftBarButtonItem = selectDeselectAllButtonItem!
		self.navigationItem.rightBarButtonItems = [exitMultipleSelectionBarButtonItem!]
	}

	@objc public func selectAllItems(_ sender: UIBarButtonItem) {
		(0..<self.items.count).map { (item) -> IndexPath in
			return IndexPath(item: item, section: 0)
			}.forEach { (indexPath) in
				self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
		}
		selectedItemIds = self.items.compactMap({$0.localID as OCLocalID?})
		self.actionContext?.replace(items: self.items)

		updateMultiselection()
	}

	@objc public func deselectAllItems(_ sender: UIBarButtonItem) {

		self.tableView.indexPathsForSelectedRows?.forEach({ (indexPath) in
			self.tableView.deselectRow(at: indexPath, animated: true)
		})
		selectedItemIds.removeAll()
		self.actionContext?.removeAllItems()

		updateMultiselection()
	}
}
