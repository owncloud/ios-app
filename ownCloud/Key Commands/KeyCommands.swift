//
//  KeyCommands.swift
//  ownCloud
//
//  Created by Matthias Hühne on 27.08.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2019, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit
import ownCloudSDK

extension ServerListTableViewController {
	override var keyCommands: [UIKeyCommand]? {
		let nextObjectCommand = UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: "Next Item".localized)
		let previousObjectCommand = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrev), discoverabilityTitle: "Previous Item".localized)
		let selectObjectCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: "Select Item".localized)
		let addAccountCommand = UIKeyCommand(input: "A", modifierFlags: [.command], action: #selector(addBookmark), discoverabilityTitle: "Add account".localized.localized)
		let openSettingsCommand = UIKeyCommand(input: ",", modifierFlags: [.command], action: #selector(settings), discoverabilityTitle: "Settings".localized.localized)

		var shortcuts = [UIKeyCommand]()
		if let selectedRow = self.tableView?.indexPathForSelectedRow?.row {
			if selectedRow < OCBookmarkManager.shared.bookmarks.count - 1 {
				shortcuts.append(nextObjectCommand)
			}
			if selectedRow > 0 {
				shortcuts.append(previousObjectCommand)
			}
			shortcuts.append(selectObjectCommand)
		} else {
			shortcuts.append(nextObjectCommand)
		}

		for (index, bookmark) in OCBookmarkManager.shared.bookmarks.enumerated() {
			let accountIndex = String(index + 1)
			let selectAccountCommand = UIKeyCommand(input: accountIndex, modifierFlags: [.command, .shift], action: #selector(selectBookmark), discoverabilityTitle: bookmark.shortName)
			shortcuts.append(selectAccountCommand)
		}

		shortcuts.append(addAccountCommand)
		shortcuts.append(openSettingsCommand)

		return shortcuts
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}

	@objc func selectBookmark(_ command : UIKeyCommand) {
		for bookmark in OCBookmarkManager.shared.bookmarks {
			if bookmark.shortName == command.discoverabilityTitle {
				self.connect(to: bookmark)
			}
		}
	}

}

extension BookmarkViewController {
	override var keyCommands: [UIKeyCommand]? {
		return [
			UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismiss), discoverabilityTitle: "Cancel".localized)
		]
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}
}

extension ThemeNavigationController {
	override var keyCommands: [UIKeyCommand]? {

		var shortcuts = [UIKeyCommand]()

		if self.viewControllers.count > 1 {
			let backCommand = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [.command], action: #selector(popViewControllerAnimated), discoverabilityTitle: "Back".localized)
			shortcuts.append(backCommand)
		}

		return shortcuts
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}

	@objc func popViewControllerAnimated() {
		_ = popViewController(animated: true)
	}
}

extension NamingViewController {
	override var keyCommands: [UIKeyCommand]? {

		var shortcuts = [UIKeyCommand]()
		if let leftItem = self.navigationItem.leftBarButtonItem, let action = leftItem.action {
			let dismissCommand = UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: action, discoverabilityTitle: "Cancel".localized)
			shortcuts.append(dismissCommand)
		}
		if let rightItem = self.navigationItem.rightBarButtonItem, let action = rightItem.action {
			let doneCommand = UIKeyCommand(input: "D", modifierFlags: [.command], action: action, discoverabilityTitle: "Done".localized)
			shortcuts.append(doneCommand)
		}

		return shortcuts
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}
}

extension ClientRootViewController {
	override var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()

		let keyCommands = self.tabBar.items?.enumerated().map { (index, item) -> UIKeyCommand in
			let tabIndex = String(index + 1)
			return UIKeyCommand(input: tabIndex, modifierFlags: .command, action:#selector(selectTab), discoverabilityTitle: item.title ?? String(format: "Tab %@".localized, tabIndex))
		}
		if let keyCommands = keyCommands {
			shortcuts.append(contentsOf: keyCommands)
		}

		return shortcuts
	}

	@objc func selectTab(sender: UIKeyCommand) {
		if let newIndex = Int(sender.input!), newIndex >= 1 && newIndex <= (self.tabBar.items?.count ?? 0) {
			self.selectedIndex = newIndex - 1
		}
	}
}

extension UITableViewController {

	@objc func selectNext(sender: UIKeyCommand) {
		if let selectedIP = self.tableView?.indexPathForSelectedRow {
			self.tableView.selectRow(at: NSIndexPath(row: selectedIP.row + 1, section: selectedIP.section) as IndexPath, animated: true, scrollPosition: .middle)
		} else {
			self.tableView.selectRow(at: NSIndexPath(row: 0, section: 0) as IndexPath, animated: true, scrollPosition: .top)
		}
	}

	@objc func selectPrev(sender: UIKeyCommand) {
		if let selectedIP = self.tableView?.indexPathForSelectedRow {
			self.tableView.selectRow(at: NSIndexPath(row: selectedIP.row - 1, section: selectedIP.section) as IndexPath, animated: true, scrollPosition: .middle)
		}
	}

	@objc func selectCurrent(sender: UIKeyCommand) {
		if let delegate = tableView.delegate, let tableView = tableView, let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: indexPath, animated: true)
			delegate.tableView!(tableView, didSelectRowAt: indexPath)
		}
	}
}

extension GroupSharingTableViewController {
	override var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()
		if let superKeyCommands = super.keyCommands {
			shortcuts.append(contentsOf: superKeyCommands)
		}
		let searchCommand = UIKeyCommand(input: "F", modifierFlags: [.command], action: #selector(enableSearch), discoverabilityTitle: "Search".localized)
		let doneCommand = UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismiss), discoverabilityTitle: "Done".localized)
		shortcuts.append(searchCommand)
		shortcuts.append(doneCommand)

		return shortcuts
	}

	@objc func enableSearch() {
		self.searchController?.isActive = true
		self.searchController?.searchBar.becomeFirstResponder()
	}
}

extension GroupSharingEditTableViewController {
	override var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()
		if let superKeyCommands = super.keyCommands {
			shortcuts.append(contentsOf: superKeyCommands)
		}
		let dismissCommand = UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismiss), discoverabilityTitle: "Cancel".localized)
		let createCommand = UIKeyCommand(input: "S", modifierFlags: [.command], action: #selector(createShareAndDismiss), discoverabilityTitle: "Save".localized)
		shortcuts.append(dismissCommand)
		shortcuts.append(createCommand)

		return shortcuts
	}
}

extension PublicLinkTableViewController {
	override var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()
		if let superKeyCommands = super.keyCommands {
			shortcuts.append(contentsOf: superKeyCommands)
		}
		let doneCommand = UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismiss), discoverabilityTitle: "Done".localized)
		shortcuts.append(doneCommand)

		return shortcuts
	}
}

extension PublicLinkEditTableViewController {
	override var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()
		if let superKeyCommands = super.keyCommands {
			shortcuts.append(contentsOf: superKeyCommands)
		}
		let dismissCommand = UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismiss), discoverabilityTitle: "Cancel".localized)
		let createCommand = UIKeyCommand(input: "S", modifierFlags: [.command], action: #selector(createPublicLink), discoverabilityTitle: "Create".localized)
		shortcuts.append(dismissCommand)
		shortcuts.append(createCommand)

		return shortcuts
	}
}

extension StaticTableViewController {

	override var keyCommands: [UIKeyCommand]? {
		let nextObjectCommand = UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: "Next Item".localized)
		let previousObjectCommand = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrev), discoverabilityTitle: "Previous Item".localized)
		let selectObjectCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: "Select Item".localized)

		var shortcuts = [UIKeyCommand]()
		if let selectedRow = self.tableView?.indexPathForSelectedRow?.row, let selectedSection = self.tableView?.indexPathForSelectedRow?.section {
			if selectedRow < sections[selectedSection].rows.count - 1 || sections.count > selectedSection {
				shortcuts.append(nextObjectCommand)
			}
			if selectedRow > 0 || selectedSection > 0 {
				shortcuts.append(previousObjectCommand)
			}
			shortcuts.append(selectObjectCommand)
		} else {
			shortcuts.append(nextObjectCommand)
		}

		return shortcuts
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}

	@objc override func selectNext(sender: UIKeyCommand) {
		if let indexPath = self.tableView?.indexPathForSelectedRow {
			let staticRow = staticRowForIndexPath(indexPath)
			self.tableView.endEditing(true)
			if staticRow.type == .switchButton, let switchButon = staticRow.cell?.accessoryView as? UISwitch {
				switchButon.tintColor = .white
				staticRow.cell?.textLabel?.textColor = Theme.shared.activeCollection.tableRowColors.labelColor
			} else if staticRow.type == .text || staticRow.type == .secureText, let textField = staticRow.textField {
				textField.textColor = Theme.shared.activeCollection.tableRowColors.labelColor
			}

			if (indexPath.row + 1) < sections[indexPath.section].rows.count {
				self.tableView.selectRow(at: NSIndexPath(row: indexPath.row + 1, section: indexPath.section) as IndexPath, animated: true, scrollPosition: .middle)
			} else if (indexPath.section + 1) < sections.count {
				// New Section
				self.tableView.selectRow(at: NSIndexPath(row: 0, section: (indexPath.section + 1)) as IndexPath, animated: true, scrollPosition: .middle)
			}
		} else {
			self.tableView.selectRow(at: NSIndexPath(row: 0, section: 0) as IndexPath, animated: true, scrollPosition: .top)
		}

		if let indexPath = self.tableView?.indexPathForSelectedRow {
			let staticRow = staticRowForIndexPath(indexPath)
			if staticRow.type == .switchButton, let switchButon = staticRow.cell?.accessoryView as? UISwitch {
				switchButon.tintColor = Theme.shared.activeCollection.tableRowHighlightColors.backgroundColor
				staticRow.cell?.textLabel?.textColor = Theme.shared.activeCollection.tableRowHighlightColors.backgroundColor
			} else if staticRow.type == .text || staticRow.type == .secureText, let textField = staticRow.textField {
				textField.textColor = Theme.shared.activeCollection.tableRowHighlightColors.backgroundColor
			}
		}
	}

	@objc override func selectPrev(sender: UIKeyCommand) {
		if let indexPath = self.tableView?.indexPathForSelectedRow {
			let staticRow = staticRowForIndexPath(indexPath)
			self.tableView.endEditing(true)
			if staticRow.type == .switchButton, let switchButon = staticRow.cell?.accessoryView as? UISwitch {
				switchButon.tintColor = .white
				staticRow.cell?.textLabel?.textColor = Theme.shared.activeCollection.tableRowColors.labelColor
			} else if staticRow.type == .text || staticRow.type == .secureText, let textField = staticRow.textField {
				textField.textColor = Theme.shared.activeCollection.tableRowHighlightColors.backgroundColor
			}

			if indexPath.row == 0, indexPath.section > 0 {
				let sectionRows = sections[indexPath.section - 1]
				self.tableView.selectRow(at: NSIndexPath(row: sectionRows.rows.count - 1, section: indexPath.section - 1) as IndexPath, animated: true, scrollPosition: .middle)
			} else {
				self.tableView.selectRow(at: NSIndexPath(row: indexPath.row - 1, section: indexPath.section) as IndexPath, animated: true, scrollPosition: .middle)
			}

			if let indexPath = self.tableView?.indexPathForSelectedRow {
				let staticRow = staticRowForIndexPath(indexPath)
				if staticRow.type == .switchButton, let switchButon = staticRow.cell?.accessoryView as? UISwitch {
					switchButon.tintColor = Theme.shared.activeCollection.tableRowHighlightColors.backgroundColor
					staticRow.cell?.textLabel?.textColor = Theme.shared.activeCollection.tableRowHighlightColors.backgroundColor
				} else if staticRow.type == .text || staticRow.type == .secureText, let textField = staticRow.textField {
					textField.textColor = Theme.shared.activeCollection.tableRowHighlightColors.backgroundColor
				}
			}
		}
	}

	@objc override func selectCurrent(sender: UIKeyCommand) {
		if let indexPath = self.tableView?.indexPathForSelectedRow {
			let staticRow = staticRowForIndexPath(indexPath)
			if staticRow.type == .switchButton, let switchButton = staticRow.cell?.accessoryView as? UISwitch {
				if switchButton.isOn {
					switchButton.setOn(false, animated: true)
					staticRow.value = false
				} else {
					switchButton.setOn(true, animated: true)
					staticRow.value = true
				}

				if let action = staticRow.action {
					action(staticRow, switchButton)
				}
			} else if staticRow.type == .text || staticRow.type == .secureText, let textField = staticRow.textField {
				textField.becomeFirstResponder()
			} else if let delegate = tableView.delegate, let tableView = tableView {
				tableView.deselectRow(at: indexPath, animated: true)
				delegate.tableView!(tableView, didSelectRowAt: indexPath)
			}
		}
	}
}

extension ClientQueryViewController {

	override var canBecomeFirstResponder: Bool {
		return true
	}

	override var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()
		if let superKeyCommands = super.keyCommands {
			shortcuts.append(contentsOf: superKeyCommands)
		}

		let nextObjectCommand = UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: "Next Item".localized)
		let previousObjectCommand = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrev), discoverabilityTitle: "Previous Item".localized)
		let selectObjectCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: "Select Item".localized)

		if let selectedRow = self.tableView?.indexPathForSelectedRow?.row {
			if selectedRow < self.items.count - 1 {
				shortcuts.append(nextObjectCommand)
			}
			if selectedRow > 0 {
				shortcuts.append(previousObjectCommand)
			}
			shortcuts.append(selectObjectCommand)
		} else {
			shortcuts.append(nextObjectCommand)
		}

		if let core = core, let rootItem = query.rootItem {
			let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .folderAction)
			let actionContext = ActionContext(viewController: self, core: core, items: [rootItem], location: actionsLocation)
			let actions = Action.sortedApplicableActions(for: actionContext)

			actions.forEach({
				if let keyCommand = $0.actionExtension.keyCommand {
					let actionCommand = UIKeyCommand(input: keyCommand, modifierFlags: [.command], action: #selector(performFolderAction), discoverabilityTitle: $0.actionExtension.name)
					shortcuts.append(actionCommand)
				}
			})
		}

		return shortcuts
	}

	@objc func performFolderAction(_ command : UIKeyCommand) {
		if let core = core, let rootItem = query.rootItem {
			let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .folderAction)
			let actionContext = ActionContext(viewController: self, core: core, items: [rootItem], location: actionsLocation)
			let actions = Action.sortedApplicableActions(for: actionContext)
			actions.forEach({
				if command.discoverabilityTitle == $0.actionExtension.name {
					$0.perform()
				}
			})
		}
	}
}

extension LibrarySharesTableViewController {

	override var canBecomeFirstResponder: Bool {
		return true
	}

	override var keyCommands: [UIKeyCommand]? {

		var shortcuts = [UIKeyCommand]()

		let nextObjectCommand = UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: "Next Item".localized)
		let previousObjectCommand = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrev), discoverabilityTitle: "Previous Item".localized)
		let selectObjectCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: "Select Item".localized)

		if let selectedRow = self.tableView?.indexPathForSelectedRow?.row {
			if selectedRow < self.shares.count - 1 {
				shortcuts.append(nextObjectCommand)
			}
			if selectedRow > 0 {
				shortcuts.append(previousObjectCommand)
			}
			shortcuts.append(selectObjectCommand)
		} else {
			shortcuts.append(nextObjectCommand)
		}

		return shortcuts
	}
}

extension QueryFileListTableViewController {

	override var canBecomeFirstResponder: Bool {
		return true
	}

	override var keyCommands: [UIKeyCommand]? {

		var shortcuts = [UIKeyCommand]()

		let nextObjectCommand = UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: "Next Item".localized)
		let previousObjectCommand = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrev), discoverabilityTitle: "Previous Item".localized)
		let selectObjectCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: "Select Item".localized)
		let toggleSortCommand = UIKeyCommand(input: "S", modifierFlags: [.command, .shift], action: #selector(toggleSortOrder), discoverabilityTitle: "Change Sort Order".localized)
		let searchCommand = UIKeyCommand(input: "F", modifierFlags: [.command], action: #selector(enableSearch), discoverabilityTitle: "Search".localized)

		if let core = core, let indexPath = self.tableView?.indexPathForSelectedRow, let item = itemAt(indexPath: indexPath) {
			let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .moreItem)
			let actionContext = ActionContext(viewController: self, core: core, items: [item], location: actionsLocation)
			let actions = Action.sortedApplicableActions(for: actionContext)

			actions.forEach({
				if let keyCommand = $0.actionExtension.keyCommand {
					let actionCommand = UIKeyCommand(input: keyCommand, modifierFlags: [.command], action: #selector(performMoreItemAction), discoverabilityTitle: $0.actionExtension.name)
					shortcuts.append(actionCommand)
				}
			})

			let actionsLocationCollaborate = OCExtensionLocation(ofType: .action, identifier: .collaborateItem)
			let actionContextCollaborate = ActionContext(viewController: self, core: core, items: [item], location: actionsLocationCollaborate)
			let actionsCollaborate = Action.sortedApplicableActions(for: actionContextCollaborate)

			actionsCollaborate.forEach({
				if let keyCommand = $0.actionExtension.keyCommand {
					let actionCommand = UIKeyCommand(input: keyCommand, modifierFlags: [.command], action: #selector(performCollaborteItemAction), discoverabilityTitle: $0.actionExtension.name)
					shortcuts.append(actionCommand)
				}
			})
		}

		shortcuts.append(searchCommand)
		if let selectedRow = self.tableView?.indexPathForSelectedRow?.row {
			if selectedRow < self.items.count - 1 {
				shortcuts.append(nextObjectCommand)
			}
			if selectedRow > 0 {
				shortcuts.append(previousObjectCommand)
			}
			shortcuts.append(selectObjectCommand)
		} else {
			shortcuts.append(nextObjectCommand)
		}
		shortcuts.append(toggleSortCommand)

		for (index, method) in SortMethod.all.enumerated() {
			let sortTitle = String(format: "Sort by %@".localized, method.localizedName())
			let sortCommand = UIKeyCommand(input: String(index + 1), modifierFlags: [.command, .shift], action: #selector(changeSortMethod), discoverabilityTitle: sortTitle)
			shortcuts.append(sortCommand)
		}

		return shortcuts
	}

	@objc func performMoreItemAction(_ command : UIKeyCommand) {
		if let core = core, let indexPath = self.tableView?.indexPathForSelectedRow, let item = itemAt(indexPath: indexPath) {
			let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .moreItem)
			let actionContext = ActionContext(viewController: self, core: core, items: [item], location: actionsLocation)
			let actions = Action.sortedApplicableActions(for: actionContext)
			actions.forEach({
				if command.discoverabilityTitle == $0.actionExtension.name {
					$0.perform()
				}
			})
		}
	}

	@objc func performCollaborteItemAction(_ command : UIKeyCommand) {
		if let core = core, let indexPath = self.tableView?.indexPathForSelectedRow, let item = itemAt(indexPath: indexPath) {
			let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .collaborateItem)
			let actionContext = ActionContext(viewController: self, core: core, items: [item], location: actionsLocation)
			let actions = Action.sortedApplicableActions(for: actionContext)
			actions.forEach({
				if command.discoverabilityTitle == $0.actionExtension.name {
					$0.perform()
				}
			})
		}
	}

	@objc func enableSearch() {
		self.searchController?.isActive = true
		self.searchController?.searchBar.becomeFirstResponder()
	}

	@objc func toggleSortOrder() {
		self.sortBar?.sortMethod = self.sortMethod
	}

	@objc func changeSortMethod(_ command : UIKeyCommand) {
		for (_, method) in SortMethod.all.enumerated() {
			let sortTitle = String(format: "Sort by %@".localized, method.localizedName())
			if command.discoverabilityTitle == sortTitle {
				self.sortBar?.sortMethod = method
				break
			}
		}
	}
}

extension ClientDirectoryPickerViewController {
	override var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()
		if let superKeyCommands = super.keyCommands {
			shortcuts.append(contentsOf: superKeyCommands)
		}
		if let selectButtonTitle = selectButton?.title, let selector = selectButton?.action {
			let doCommand = UIKeyCommand(input: "\r", modifierFlags: [.command], action: selector, discoverabilityTitle: selectButtonTitle)
			shortcuts.append(doCommand)
		}

		let createFolder = UIKeyCommand(input: "N", modifierFlags: [.command], action: #selector(createFolderButtonPressed), discoverabilityTitle: "Create Folder".localized)
		shortcuts.append(createFolder)
		let dismissCommand = UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismiss), discoverabilityTitle: "Cancel".localized)
		shortcuts.append(dismissCommand)

		return shortcuts
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}
}

extension PhotoAlbumTableViewController {
	override var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()
		if let superKeyCommands = super.keyCommands {
			shortcuts.append(contentsOf: superKeyCommands)
		}

		let nextObjectCommand = UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: "Next Item".localized)
		let previousObjectCommand = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrev), discoverabilityTitle: "Previous Item".localized)
		let selectObjectCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: "Select Item".localized)

		if let selectedRow = self.tableView?.indexPathForSelectedRow?.row {
			if selectedRow < self.albums.count - 1 {
				shortcuts.append(nextObjectCommand)
			}
			if selectedRow > 0 {
				shortcuts.append(previousObjectCommand)
			}
			shortcuts.append(selectObjectCommand)
		} else {
			shortcuts.append(nextObjectCommand)
		}

		let dismissCommand = UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismiss), discoverabilityTitle: "Cancel".localized)
		shortcuts.append(dismissCommand)

		return shortcuts
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}
}

extension PhotoSelectionViewController {

	override var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()
		if let superKeyCommands = super.keyCommands {
			shortcuts.append(contentsOf: superKeyCommands)
		}

		let nextObjectCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: "Next Item".localized)
		let previousObjectCommand = UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(selectPrev), discoverabilityTitle: "Previous Item".localized)
		let selectObjectCommand = UIKeyCommand(input: " ", modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: "Select Item".localized)
		let selectAllCommand = UIKeyCommand(input: "A", modifierFlags: [.command], action: #selector(selectAllItems), discoverabilityTitle: "Select All".localized)
		let deselectAllCommand = UIKeyCommand(input: "D", modifierFlags: [.command], action: #selector(deselectAllItems), discoverabilityTitle: "Deselect All".localized)
		let uploadCommand = UIKeyCommand(input: "U", modifierFlags: [.command], action: #selector(upload), discoverabilityTitle: "Upload".localized)
		let dismissCommand = UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismiss), discoverabilityTitle: "Cancel".localized)

		shortcuts.append(nextObjectCommand)
		shortcuts.append(previousObjectCommand)
		shortcuts.append(selectObjectCommand)
		shortcuts.append(selectAllCommand)
		if collectionView?.indexPathsForSelectedItems?.count ?? 0 > 0 {
			shortcuts.append(deselectAllCommand)
			shortcuts.append(uploadCommand)
		}
		shortcuts.append(dismissCommand)

		return shortcuts
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}

    @objc func selectCurrent() {
        guard let focussedIndexPath = focussedIndexPath else { return }
		if let isSelected = collectionView?.indexPathsForSelectedItems?.contains(focussedIndexPath), isSelected {
			collectionView.deselectItem(at: focussedIndexPath, animated: true)
		} else {
			collectionView.selectItem(at: focussedIndexPath, animated: true, scrollPosition: .top)
		}
        collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: focussedIndexPath)
    }

    @objc func selectNext() {
        guard let focussedIndexPath = focussedIndexPath else {
            self.focussedIndexPath = firstIndexPath
            return
        }

        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        let focussedItem = focussedIndexPath.item

        guard focussedItem != (numberOfItems - 1) else {
            self.focussedIndexPath = firstIndexPath
            return
        }

        self.focussedIndexPath = IndexPath(item: focussedItem + 1, section: 0)
    }

    @objc func selectPrev() {
        guard let focussedIndexPath = focussedIndexPath else {
            self.focussedIndexPath = lastIndexPath
            return
        }

        let focussedItem = focussedIndexPath.item

        guard focussedItem > 0 else {
            self.focussedIndexPath = lastIndexPath
            return
        }

        self.focussedIndexPath = IndexPath(item: focussedItem - 1, section: 0)
    }

    private var lastIndexPath: IndexPath {
        return IndexPath(item: collectionView.numberOfItems(inSection: 0) - 1, section: 0)
    }

    private var firstIndexPath: IndexPath {
        return IndexPath(item: 0, section: 0)
    }
}
