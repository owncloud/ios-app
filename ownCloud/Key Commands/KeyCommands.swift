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
import MobileCoreServices

extension ServerListTableViewController {
	override var keyCommands: [UIKeyCommand]? {
		let nextObjectCommand = UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: "Select Next".localized)
		let previousObjectCommand = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrevious), discoverabilityTitle: "Select Previous".localized)
		let selectObjectCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: "Open Selected".localized)
		let addAccountCommand = UIKeyCommand(input: "+", modifierFlags: [.command], action: #selector(addBookmark), discoverabilityTitle: "Add account".localized.localized)
		let openSettingsCommand = UIKeyCommand(input: ",", modifierFlags: [.command], action: #selector(settings), discoverabilityTitle: "Settings".localized.localized)

		let editSettingsCommand = UIKeyCommand(input: ",", modifierFlags: [.command, .shift], action: #selector(editBookmark), discoverabilityTitle: "Edit".localized)
		let manageSettingsCommand = UIKeyCommand(input: "M", modifierFlags: [.command, .shift], action: #selector(manageBookmark), discoverabilityTitle: "Manage".localized)
		let deleteSettingsCommand = UIKeyCommand(input: "\u{08}", modifierFlags: [.command, .shift], action: #selector(deleteBookmarkCommand), discoverabilityTitle: "Delete".localized)

		var shortcuts = [UIKeyCommand]()
		/*
		var index = 1
		if #available(iOS 13.0, *) {
		for sceneSession in UIApplication.shared.openSessions {
				var title = "Switch to Window"

			if let sceneTitle = sceneSession.scene?.title {
					title = String(format: "Switch to Window %@", sceneTitle)
				}

				let switchWindowCommand = UIKeyCommand(input: String(index), modifierFlags: [.command], action: #selector(switchToWindow), discoverabilityTitle: title)
				shortcuts.append(switchWindowCommand)
				index += 1
			}
		}*/

		if let selectedRow = self.tableView?.indexPathForSelectedRow?.row {
			shortcuts.append(editSettingsCommand)
			shortcuts.append(manageSettingsCommand)
			shortcuts.append(deleteSettingsCommand)

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
/*
	@objc func switchToWindow(_ command : UIKeyCommand) {
		if #available(iOS 13.0, *) {
			let sceneSession = Array(UIApplication.shared.openSessions)
			UIApplication.shared.requestSceneSessionActivation(sceneSession.last, userActivity: nil, options: nil)
			/*if let index = command.input, let scene = sceneSession[Int(index)] {

			}*/
		}
	}*/

	@objc func selectBookmark(_ command : UIKeyCommand) {
		for bookmark in OCBookmarkManager.shared.bookmarks {
			if bookmark.shortName == command.discoverabilityTitle {
				self.connect(to: bookmark, animated: true) { (_, _) in
				}
			}
		}
	}

	@objc func editBookmark() {
		if let indexPath = self.tableView?.indexPathForSelectedRow, let bookmark = OCBookmarkManager.shared.bookmark(at: UInt(indexPath.row)) {
			showBookmarkUI(edit: bookmark)
		}
	}

	@objc func manageBookmark() {
		if let indexPath = self.tableView?.indexPathForSelectedRow, let bookmark = OCBookmarkManager.shared.bookmark(at: UInt(indexPath.row)) {
			showBookmarkInfoUI(bookmark)
		}
	}

	@objc func deleteBookmarkCommand() {
		if let indexPath = self.tableView?.indexPathForSelectedRow, let bookmark = OCBookmarkManager.shared.bookmark(at: UInt(indexPath.row)) {
			deleteBookmark(bookmark, on: indexPath)
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

		if let core = core {
			let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .window)
			let actionContext = ActionContext(viewController: self, core: core, items: [], location: actionsLocation)
			let actions = Action.sortedApplicableActions(for: actionContext)

			actions.forEach({
				if let keyCommand = $0.actionExtension.keyCommand {
					let actionCommand = UIKeyCommand(input: keyCommand, modifierFlags: [.command], action: #selector(performWindowItemAction), discoverabilityTitle: $0.actionExtension.name)
					shortcuts.append(actionCommand)
				}
			})
		}

		return shortcuts
	}

	@objc func selectTab(sender: UIKeyCommand) {
		if let newIndex = Int(sender.input!), newIndex >= 1 && newIndex <= (self.tabBar.items?.count ?? 0) {
			self.selectedIndex = newIndex - 1
		}
	}

	@objc func performWindowItemAction(_ command : UIKeyCommand) {
		if let core = core {
			let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .window)
			let actionContext = ActionContext(viewController: self, core: core, items: [], location: actionsLocation)
			let actions = Action.sortedApplicableActions(for: actionContext)
			actions.forEach({
				if command.discoverabilityTitle == $0.actionExtension.name {
					$0.perform()
				}
			})
		}
	}

	override var canBecomeFirstResponder: Bool {
		return true
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

	@objc func selectPrevious(sender: UIKeyCommand) {
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

	override open var canBecomeFirstResponder: Bool {
		return true
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

	override var canBecomeFirstResponder: Bool {
		return true
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

	override var canBecomeFirstResponder: Bool {
		return true
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

	override var canBecomeFirstResponder: Bool {
		return true
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

	override var canBecomeFirstResponder: Bool {
		return true
	}
}

extension StaticTableViewController {

	override var keyCommands: [UIKeyCommand]? {
		let nextObjectCommand = UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: "Select Next".localized)
		let previousObjectCommand = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrevious), discoverabilityTitle: "Select Previous".localized)
		let selectObjectCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: "Open Selected".localized)

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

	@objc override func selectPrevious(sender: UIKeyCommand) {
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

	override var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()
		if let superKeyCommands = super.keyCommands {
			shortcuts.append(contentsOf: superKeyCommands)
		}

		let nextObjectCommand = UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: "Select Next".localized)
		let previousObjectCommand = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrevious), discoverabilityTitle: "Select Previous".localized)
		let selectObjectCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: "Open Selected".localized)

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

	override var canBecomeFirstResponder: Bool {
		return true
	}
}

extension LibrarySharesTableViewController {

	override var canBecomeFirstResponder: Bool {
		return true
	}

	override var keyCommands: [UIKeyCommand]? {

		var shortcuts = [UIKeyCommand]()

		let nextObjectCommand = UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: "Select Next".localized)
		let previousObjectCommand = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrevious), discoverabilityTitle: "Select Previous".localized)
		let selectObjectCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: "Open Selected".localized)

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

		let nextObjectCommand = UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: "Select Next".localized)
		let selectLastPageObjectCommand = UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [.command], action: #selector(selectLastPageObject), discoverabilityTitle: "Select Last Item on Page".localized)
		let previousObjectCommand = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrevious), discoverabilityTitle: "Select Previous".localized)
		let selectObjectCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: "Open Selected".localized)
		let scrollTopCommand = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [.command, .shift], action: #selector(scrollToFirstRow), discoverabilityTitle: "Scroll to Top".localized)
		let scrollBottomCommand = UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [.command, .shift], action: #selector(scrollToLastRow), discoverabilityTitle: "Scroll to Bottom".localized)
		let toggleSortCommand = UIKeyCommand(input: "S", modifierFlags: [.command, .shift], action: #selector(toggleSortOrder), discoverabilityTitle: "Change Sort Order".localized)
		let searchCommand = UIKeyCommand(input: "F", modifierFlags: [.command], action: #selector(enableSearch), discoverabilityTitle: "Search".localized)
		let copyCommand = UIKeyCommand(input: "C", modifierFlags: [.command, .shift], action: #selector(copyToPasteboard), discoverabilityTitle: "Copy to Pasteboard".localized)
		let pasteCommand = UIKeyCommand(input: "V", modifierFlags: [.command, .shift], action: #selector(importPasteboard), discoverabilityTitle: "Paste from Pasteboard".localized)
		let cutCommand = UIKeyCommand(input: "X", modifierFlags: [.command, .shift], action: #selector(cutItem), discoverabilityTitle: "Cut".localized)
		let favoriteCommand = UIKeyCommand(input: "F", modifierFlags: [.command, .shift], action: #selector(toggleFavoriteItem), discoverabilityTitle: "Favorite".localized)
		// Add key commands for file name letters
		if sortMethod == .alphabetically {
			let indexTitles = Array( Set( self.items.map { String(( $0.name?.first!.uppercased())!) })).sorted()
			for title in indexTitles {
				let letterCommand = UIKeyCommand(input: title, modifierFlags: [], action: #selector(selectLetter))
				shortcuts.append(letterCommand)
			}
		}

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
			shortcuts.append(favoriteCommand)

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

		if self.tableView?.indexPathForSelectedRow != nil {
			shortcuts.append(copyCommand)
			shortcuts.append(cutCommand)
		}
		shortcuts.append(pasteCommand)
		shortcuts.append(searchCommand)
		shortcuts.append(toggleSortCommand)

		for (index, method) in SortMethod.all.enumerated() {
			let sortTitle = String(format: "Sort by %@".localized, method.localizedName())
			let sortCommand = UIKeyCommand(input: String(index + 1), modifierFlags: [.command, .alternate], action: #selector(changeSortMethod), discoverabilityTitle: sortTitle)
			shortcuts.append(sortCommand)
		}

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
		shortcuts.append(scrollTopCommand)
		shortcuts.append(scrollBottomCommand)
		if self.items.count > 0 {
			shortcuts.append(selectLastPageObjectCommand)
		}

		return shortcuts
	}

	@objc func selectLetter(_ command : UIKeyCommand) {
		if let title = command.input {
			let firstItem = self.items.filter { (( $0.name?.uppercased().hasPrefix(title) ?? nil)! ) }.first

			if let firstItem = firstItem {
				if let itemIndex = self.items.index(of: firstItem) {
					let indexPath = IndexPath(row: itemIndex, section: 0)
					tableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.middle, animated: false)
					tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
				}
			}
		}
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

	@objc func toggleFavoriteItem() {
		if let core = core, let indexPath = self.tableView?.indexPathForSelectedRow, let item = itemAt(indexPath: indexPath) {
			if item.isFavorite == true {
				item.isFavorite = false
			} else {
				item.isFavorite = true
			}
			core.update(item, properties: [OCItemPropertyName.isFavorite], options: nil, resultHandler: { (error, _, _, _) in
				if error == nil {
				}
			})
		}
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

	@objc func selectLastPageObject() {
		if self.items.count > 0, let lastCell = tableView.visibleCells.last, let indexPath = tableView.indexPath(for: lastCell) {
			self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
			tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
			}
	}

	@objc func scrollToFirstRow() {
		if self.items.count > 0 {
			self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
			tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .bottom)
			}
		}

		@objc func scrollToLastRow() {
			if self.items.count > 0 {
				self.tableView.scrollToRow(at: IndexPath(row: self.items.count - 1, section: 0), at: .bottom, animated: true)
				tableView.selectRow(at: IndexPath(row: self.items.count - 1, section: 0), animated: true, scrollPosition: .bottom)
			}
	}

	@objc func cutItem() {
		if let indexPath = self.tableView?.indexPathForSelectedRow, let item = itemAt(indexPath: indexPath), let tabBarController = self.tabBarController as? ClientRootViewController {
			if let fileData = item.serializedData() {
				let pasteboard = UIPasteboard(name: UIPasteboard.Name(rawValue: "com.owncloud.pasteboard"), create: true)
				pasteboard?.setData(fileData as Data, forPasteboardType: "com.owncloud.uti.OCItem.cut")
				tabBarController.pasteboardChangedCounter = UIPasteboard.general.changeCount
			}
		}
	}

	@objc func importPasteboard() {
		if let core = self.core, let rootItem = query.rootItem, let tabBarController = self.tabBarController as? ClientRootViewController {
			let pasteboard = UIPasteboard.general

			// Determine, if the internal pasteboard is the current item and use it
			if pasteboard.changeCount == tabBarController.pasteboardChangedCounter {
				// Internal Pasteboard
				if let pasteboard = UIPasteboard(name: UIPasteboard.Name(rawValue: "com.owncloud.pasteboard"), create: false) {
					if let data = pasteboard.data(forPasteboardType: "com.owncloud.uti.OCItem.copy"), let object = NSKeyedUnarchiver.unarchiveObject(with: data) {
						if let item = object as? OCItem, let name = item.name {
							core.copy(item, to: rootItem, withName: name, options: nil, resultHandler: { (error, _, _, _) in
								if error != nil {
								} else {
								}
							})
						}
					} else if let data = pasteboard.data(forPasteboardType: "com.owncloud.uti.OCItem.cut"), let object = NSKeyedUnarchiver.unarchiveObject(with: data) {
						if let item = object as? OCItem, let name = item.name {
							core.copy(item, to: rootItem, withName: name, options: nil, resultHandler: { (error, _, _, _) in
								if error != nil {
								} else {
									core.delete(item, requireMatch: true) { (_, _, _, _) in
									}
								}
							})
						}
					}
				}
			} else {
				// System-wide Pasteboard
				for type in pasteboard.types {
					guard let data = pasteboard.data(forPasteboardType: type) else { return }
					if let extUTI = UTTypeCopyPreferredTagWithClass(type as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue() {
						let fileName = type
						let localURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName).appendingPathExtension(extUTI as String)
						do {
							try data.write(to: localURL)

							core.importItemNamed(localURL.lastPathComponent,
												 at: rootItem,
												 from: localURL,
												 isSecurityScoped: false,
												 options: [
													OCCoreOption.importByCopying : false,
													OCCoreOption.automaticConflictResolutionNameStyle : OCCoreDuplicateNameStyle.bracketed.rawValue
								],
												 placeholderCompletionHandler: { (error, item) in
													if error != nil {
														Log.debug("Error uploading \(Log.mask(fileName)) to \(Log.mask(rootItem.path)), error: \(error?.localizedDescription ?? "" )")
													}
							},
												 resultHandler: { (error, _ core, _ item, _) in
													if error != nil {
														Log.debug("Error uploading \(Log.mask(fileName)) to \(Log.mask(rootItem.path)), error: \(error?.localizedDescription ?? "" )")
													} else {
														Log.debug("Success uploading \(Log.mask(fileName)) to \(Log.mask(rootItem.path))")
													}
							}
							)
						} catch let error as NSError {
							print(error)
						}

					}
				}
			}
		}
	}

	@objc func copyToPasteboard() {
		if let core = self.core, let indexPath = self.tableView?.indexPathForSelectedRow, let item = itemAt(indexPath: indexPath), let tabBarController = self.tabBarController as? ClientRootViewController {

			// Internal Pasteboard
			if let fileData = item.serializedData() {
				let pasteboard = UIPasteboard(name: UIPasteboard.Name(rawValue: "com.owncloud.pasteboard"), create: true)
				pasteboard?.setData(fileData as Data, forPasteboardType: "com.owncloud.uti.OCItem.copy")
			}

			// General system-wide Pasteboard
			if item.type == .collection {
				let pasteboard = UIPasteboard.general
				tabBarController.pasteboardChangedCounter = pasteboard.changeCount
			} else if item.type == .file {
				if let itemMimeType = item.mimeType {
					let mimeTypeCF = itemMimeType as CFString
					if let rawUti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeTypeCF, nil)?.takeRetainedValue() {
						if core.localCopy(of: item) == nil {
							core.downloadItem(item, options: [ .returnImmediatelyIfOfflineOrUnavailable : true ], resultHandler: { (error, core, item, _) in
								if error == nil {
									if let item = item {
										if let fileData = NSData(contentsOf: core.localURL(for: item)) {
											let rawUtiString = rawUti as String
											let pasteboard = UIPasteboard.general
											pasteboard.setData(fileData as Data, forPasteboardType: rawUtiString)
											tabBarController.pasteboardChangedCounter = pasteboard.changeCount
										}

									}
								} else {
								}
							})
						} else {
							if let fileData = NSData(contentsOf: core.localURL(for: item)) {
								let rawUtiString = rawUti as String
								let pasteboard = UIPasteboard.general
								pasteboard.setData(fileData as Data, forPasteboardType: rawUtiString)
								tabBarController.pasteboardChangedCounter = pasteboard.changeCount
							}
						}
					}
				}
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

		let nextObjectCommand = UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: "Select Next".localized)
		let previousObjectCommand = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrevious), discoverabilityTitle: "Select Previous".localized)
		let selectObjectCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: "Open Selected".localized)

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

		let nextObjectCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: "Select Next".localized)
		let previousObjectCommand = UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(selectPrevious), discoverabilityTitle: "Select Previous".localized)
		let selectObjectCommand = UIKeyCommand(input: " ", modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: "Select".localized)
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

    @objc func selectPrevious() {
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

extension PasscodeViewController {

    override var keyCommands: [UIKeyCommand]? {
        var keyCommands : [UIKeyCommand] = []
        for i in 0 ..< 10 {
            keyCommands.append(
                UIKeyCommand(input:String(i),
                             modifierFlags: [],
                             action: #selector(self.performKeyCommand(sender:)),
                             discoverabilityTitle: String(i))
            )
        }

        keyCommands.append(
            UIKeyCommand(input: "\u{8}",
                         modifierFlags: [],
                         action: #selector(self.performKeyCommand(sender:)),
                         discoverabilityTitle: "Delete".localized)
        )

        if cancelButton?.isHidden == false {
            keyCommands.append(

                UIKeyCommand(input: UIKeyCommand.inputEscape,
                            modifierFlags: [],
                            action: #selector(self.performKeyCommand(sender:)),
                            discoverabilityTitle: "Cancel".localized)
            )
        }

        return keyCommands
    }

	override open var canBecomeFirstResponder: Bool {
		return true
	}

    @objc func performKeyCommand(sender: UIKeyCommand) {
        guard let key = sender.input else {
            return
        }

        switch key {
        case "\u{8}":
            deleteLastDigit()
        case UIKeyCommand.inputEscape:
            cancelHandler?(self)
        default:
            appendDigit(digit: key)
        }

    }
}

extension DisplayHostViewController {

	override var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()
		if let superKeyCommands = super.keyCommands {
			shortcuts.append(contentsOf: superKeyCommands)
		}

		let nextObjectCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: "Next".localized)
		let previousObjectCommand = UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(selectPrevious), discoverabilityTitle: "Previous".localized)

		var showCommands = false
		if let firstViewController = self.viewControllers?.first, let pdfController = firstViewController as? PDFViewerViewController {
			showCommands = true
		} else if items?.count ?? 0 > 1 {
			showCommands = true
		}

		if showCommands {
			shortcuts.append(nextObjectCommand)
			shortcuts.append(previousObjectCommand)
		}

		return shortcuts
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}

    @objc func selectNext() {
        guard let currentViewController = self.viewControllers?.first else { return }

		if let pdfController = currentViewController as? PDFViewerViewController {
			pdfController.pdfView.goToNextPage(self)
		} else {
			guard let nextViewController = dataSource?.pageViewController( self, viewControllerAfter: currentViewController ) else { return }

			setViewControllers([nextViewController], direction: .forward, animated: false, completion: nil)
		}
    }

    @objc func selectPrevious() {
        guard let currentViewController = self.viewControllers?.first else { return }

		if let pdfController = currentViewController as? PDFViewerViewController {
			pdfController.pdfView.goToPreviousPage(self)
		} else {
			guard let previousViewController = dataSource?.pageViewController( self, viewControllerBefore: currentViewController ) else { return }

			setViewControllers([previousViewController], direction: .reverse, animated: false, completion: nil)
		}
    }
}
