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
import ownCloudAppShared
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
		if let selectedRow = self.tableView?.indexPathForSelectedRow?.row {
			shortcuts.append(editSettingsCommand)
			shortcuts.append(manageSettingsCommand)
			shortcuts.append(deleteSettingsCommand)
			if #available(iOS 13.0, *), UIDevice.current.isIpad() {
				let openWindowCommand = UIKeyCommand(input: "W", modifierFlags: [.command, .shift], action: #selector(openSelectedBookmarkInWindow), discoverabilityTitle: "Open in new Window".localized)
				shortcuts.append(openWindowCommand)
			}

			if selectedRow < OCBookmarkManager.shared.bookmarks.count - 1 {
				shortcuts.append(nextObjectCommand)
			}
			if selectedRow > 0 {
				shortcuts.append(previousObjectCommand)
			}
			shortcuts.append(selectObjectCommand)
		} else if self.tableView?.numberOfRows(inSection: 0) ?? 0 > 0 {
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

	@available(iOS 13.0, *)
	@objc func openSelectedBookmarkInWindow() {
		if let indexPath = self.tableView?.indexPathForSelectedRow {
			openAccountInWindow(at: indexPath)
		}
	}

	@objc func selectBookmark(_ command : UIKeyCommand) {
		for bookmark in OCBookmarkManager.shared.bookmarks {
			if bookmark.shortName == command.discoverabilityTitle {
				self.connect(to: bookmark, lastVisibleItemId: nil, animated: true)
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
			delete(bookmark: bookmark, at: indexPath)
		}
	}
}

extension BookmarkViewController {
	override var keyCommands: [UIKeyCommand]? {
		return [
			UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismiss), discoverabilityTitle: "Cancel".localized),
			UIKeyCommand(input: "C", modifierFlags: [.command], action: #selector(handleContinue), discoverabilityTitle: "Continue".localized)
		]
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}
}

extension IssuesViewController {
	override public var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()

		if let buttons = buttons {
			var counter = 1
			for button in buttons {
				let command = UIKeyCommand(input: String(counter), modifierFlags: [.command], action: #selector(issueButtonPressed), discoverabilityTitle: button.title)
				shortcuts.append(command)
				counter += 1
			}
		}

		return shortcuts
	}

	@objc func issueButtonPressed(_ command : UIKeyCommand) {
		guard let button = buttons?.first(where: {$0.title == command.discoverabilityTitle}) else { return }

		let buttonPressed: IssueButton = button
		buttonPressed.action()
	}

	override public var canBecomeFirstResponder: Bool {
		return true
	}
}

extension UIAlertController {

    typealias AlertHandler = @convention(block) (UIAlertAction) -> Void

	override open var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()
		var counter = 1
		for action in actions {
			if let title = action.title {
				let command = UIKeyCommand(input: String(counter), modifierFlags: [.command], action: #selector(tapActionButton), discoverabilityTitle: title)
				shortcuts.append(command)
				counter += 1
			}
		}

		return shortcuts
	}

    @objc func tapActionButton(_ command : UIKeyCommand) {
		guard let action = actions.first(where: {$0.title == command.discoverabilityTitle}) else { return }
		guard let block = action.value(forKey: "handler") else {
			dismiss(animated: true, completion: nil)
			return
		}

		let handler = unsafeBitCast(block as AnyObject, to: AlertHandler.self)
		dismiss(animated: true) {
			handler(action)
		}
	}

	override open var canBecomeFirstResponder: Bool {
		return true
	}
}

extension BookmarkInfoViewController {
	override var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()
		if let superKeyCommands = super.keyCommands {
			shortcuts.append(contentsOf: superKeyCommands)
		}

		let doneCommand = UIKeyCommand(input: "D", modifierFlags: [.command], action: #selector(userActionDone), discoverabilityTitle: "Done".localized)
		shortcuts.append(doneCommand)

		return shortcuts
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}
}

extension ThemeNavigationController {
	override public var keyCommands: [UIKeyCommand]? {

		var shortcuts = [UIKeyCommand]()

		if self.viewControllers.count > 1 {
			let backCommand = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [.command], action: #selector(popViewControllerAnimated), discoverabilityTitle: "Back".localized)
			shortcuts.append(backCommand)
		}

		return shortcuts
	}

	override public var canBecomeFirstResponder: Bool {
		return true
	}

	@objc public func popViewControllerAnimated() {
		_ = popViewController(animated: true)
	}
}

extension NamingViewController {
	override public var keyCommands: [UIKeyCommand]? {

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

	override public var canBecomeFirstResponder: Bool {
		return true
	}
}

extension ClientRootViewController {
	override open var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()

		let excludeViewControllers = [ThemedAlertController.self, SharingTableViewController.self, PublicLinkTableViewController.self, PublicLinkEditTableViewController.self, GroupSharingEditTableViewController.self]

		if let navigationController = self.selectedViewController as? ThemeNavigationController, let visibleController = navigationController.visibleViewController {
			if excludeViewControllers.contains(where: {$0 == type(of: visibleController)}) {
				return shortcuts
			}
		}

		let keyCommands = self.tabBar.items?.enumerated().map { (index, item) -> UIKeyCommand in
			let tabIndex = String(index + 1)
			return UIKeyCommand(input: tabIndex, modifierFlags: .command, action:#selector(selectTab), discoverabilityTitle: item.title ?? String(format: "Tab %@".localized, tabIndex))
		}
		if let keyCommands = keyCommands {
			shortcuts.append(contentsOf: keyCommands)
		}

		if let navigationController = self.selectedViewController as? ThemeNavigationController, (navigationController.visibleViewController is ClientQueryViewController || navigationController.visibleViewController is GroupSharingTableViewController) {
			let cancelCommand = UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismissSearch), discoverabilityTitle: "Cancel".localized)
			shortcuts.append(cancelCommand)
		}

		return shortcuts
	}

	@objc func dismissSearch(sender: UIKeyCommand) {
		if let navigationController = self.selectedViewController as? ThemeNavigationController {
			if let clientQueryViewController = navigationController.visibleViewController as? ClientQueryViewController {
				clientQueryViewController.searchController?.isActive = false
			} else if let groupSharingViewController = navigationController.visibleViewController as? GroupSharingTableViewController {
				groupSharingViewController.searchController?.isActive = false
			}
		}
	}

	@objc func selectTab(sender: UIKeyCommand) {
		if let newIndex = Int(sender.input!), newIndex >= 1 && newIndex <= (self.tabBar.items?.count ?? 0) {
			self.selectedIndex = newIndex - 1
		}
	}

	override open var canBecomeFirstResponder: Bool {
		return true
	}
}

extension UITableViewController {

	@objc func selectNext(sender: UIKeyCommand) {
		if let selectedIndexPath = self.tableView?.indexPathForSelectedRow, selectedIndexPath.row < (self.tableView?.numberOfRows(inSection: selectedIndexPath.section) ?? 0 ) - 1 {
			self.tableView.selectRow(at: NSIndexPath(row: selectedIndexPath.row + 1, section: selectedIndexPath.section) as IndexPath, animated: true, scrollPosition: .middle)
		} else if self.tableView?.numberOfRows(inSection: 0) ?? 0 > 0 {
			self.tableView.selectRow(at: NSIndexPath(row: 0, section: 0) as IndexPath, animated: true, scrollPosition: .top)
		}
	}

	@objc func selectPrevious(sender: UIKeyCommand) {
		if let selectedIndexPath = self.tableView?.indexPathForSelectedRow, selectedIndexPath.row > 0 {
			self.tableView.selectRow(at: NSIndexPath(row: selectedIndexPath.row - 1, section: selectedIndexPath.section) as IndexPath, animated: true, scrollPosition: .middle)
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
	override public var keyCommands: [UIKeyCommand]? {
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

	override public var canBecomeFirstResponder: Bool {
		return true
	}
}

extension GroupSharingEditTableViewController {
	override public var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()
		if let superKeyCommands = super.keyCommands {
			shortcuts.append(contentsOf: superKeyCommands)
		}
		let dismissCommand = UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismiss), discoverabilityTitle: "Cancel".localized)
		let createCommand = UIKeyCommand(input: "S", modifierFlags: [.command], action: #selector(createShareAndDismiss), discoverabilityTitle: "Save".localized)
		shortcuts.append(dismissCommand)
		shortcuts.append(createCommand)

		if createShare {
			let showInfoObjectCommand = UIKeyCommand(input: "H", modifierFlags: [.command, .alternate], action: #selector(showInfoSubtitles), discoverabilityTitle: "Help".localized)
			shortcuts.append(showInfoObjectCommand)
		}

		return shortcuts
	}

	override public var canBecomeFirstResponder: Bool {
		return true
	}
}

extension PublicLinkTableViewController {
	override public var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()
		if let superKeyCommands = super.keyCommands {
			shortcuts.append(contentsOf: superKeyCommands)
		}
		let doneCommand = UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismiss), discoverabilityTitle: "Done".localized)
		shortcuts.append(doneCommand)

		return shortcuts
	}

	override public var canBecomeFirstResponder: Bool {
		return true
	}
}

extension PublicLinkEditTableViewController {
	override public var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()
		if let superKeyCommands = super.keyCommands {
			shortcuts.append(contentsOf: superKeyCommands)
		}
		let dismissCommand = UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismiss), discoverabilityTitle: "Cancel".localized)
		let createCommand = UIKeyCommand(input: "S", modifierFlags: [.command], action: #selector(createPublicLink), discoverabilityTitle: "Create".localized)
		shortcuts.append(dismissCommand)
		shortcuts.append(createCommand)

		if createLink {
			let showInfoObjectCommand = UIKeyCommand(input: "H", modifierFlags: [.command, .alternate], action: #selector(showInfoSubtitles), discoverabilityTitle: "Help".localized)
			shortcuts.append(showInfoObjectCommand)
		} else {
			let shareObjectCommand = UIKeyCommand(input: "S", modifierFlags: [.command, .alternate], action: #selector(shareLinkURL), discoverabilityTitle: "Share".localized)
			shortcuts.append(shareObjectCommand)
		}

		return shortcuts
	}

	override public var canBecomeFirstResponder: Bool {
		return true
	}
}

extension StaticTableViewController {

	public override var keyCommands: [UIKeyCommand]? {
		let nextObjectCommand = UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: "Select Next".localized)
		let previousObjectCommand = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrevious), discoverabilityTitle: "Select Previous".localized)
		let selectObjectCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: "Open Selected".localized)

		var shortcuts = [UIKeyCommand]()

		if let selectedIndexPath = self.tableView?.indexPathForSelectedRow {
			let selectedRow = selectedIndexPath.row
			let selectedSection = selectedIndexPath.section
			if selectedRow < sections[selectedSection].rows.count - 1 || sections.count > selectedSection {
				shortcuts.append(nextObjectCommand)
			}
			if selectedRow > 0 || selectedSection > 0 {
				shortcuts.append(previousObjectCommand)
			}
			if staticRowForIndexPath(selectedIndexPath).type == .slider {
				let row = staticRowForIndexPath(selectedIndexPath)
				let sliders = row.cell?.subviews.filter { $0 is UISlider }
				if let slider = sliders?.first as? UISlider {
					slider.thumbTintColor = Theme.shared.activeCollection.tableRowHighlightColors.backgroundColor
				}
				let sliderDownCommand = UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(sliderDown), discoverabilityTitle: "Decrease Slider Value".localized)
				let sliderUpCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(sliderUp), discoverabilityTitle: "Increase Slider Value".localized)
				shortcuts.append(sliderDownCommand)
				shortcuts.append(sliderUpCommand)
			} else {
				shortcuts.append(selectObjectCommand)
			}
		} else if self.tableView?.numberOfSections ?? 0 > 0, self.tableView?.numberOfRows(inSection: 0) ?? 0 > 0 {
			shortcuts.append(nextObjectCommand)
		}

		return shortcuts
	}

	override public var canBecomeFirstResponder: Bool {
		return true
	}

	@objc func sliderDown() {
		if let selectedIndexPath = self.tableView?.indexPathForSelectedRow {
			let row = staticRowForIndexPath(selectedIndexPath)
			let sliders = row.cell?.subviews.filter { $0 is UISlider }
			if let slider = sliders?.first as? UISlider, slider.value > slider.minimumValue {
				slider.value = (slider.value - 1.0)
				slider.sendActions(for: .valueChanged)
			}
		}
	}

	@objc func sliderUp() {
		if let selectedIndexPath = self.tableView?.indexPathForSelectedRow {
			let row = staticRowForIndexPath(selectedIndexPath)
			let sliders = row.cell?.subviews.filter { $0 is UISlider }
			if let slider = sliders?.first as? UISlider, slider.value < slider.maximumValue {
				slider.value = (slider.value + 1.0)
				slider.sendActions(for: .valueChanged)
			}
		}
	}

	@objc override func selectNext(sender: UIKeyCommand) {
		if let selectedIndexPath = self.tableView?.indexPathForSelectedRow {
			let staticRow = staticRowForIndexPath(selectedIndexPath)
			self.tableView.endEditing(true)
			if staticRow.type == .switchButton, let switchButton = staticRow.cell?.accessoryView as? UISwitch {
				switchButton.tintColor = .white
				staticRow.cell?.textLabel?.textColor = Theme.shared.activeCollection.tableRowColors.labelColor
			} else if staticRow.type == .text || staticRow.type == .secureText, let textField = staticRow.textField {
				textField.textColor = Theme.shared.activeCollection.tableRowColors.labelColor
			} else if staticRow.type == .slider {
				let sliders = staticRow.cell?.subviews.filter { $0 is UISlider }
				if let slider = sliders?.first as? UISlider {
					slider.thumbTintColor = .white
				}
			}

			if (selectedIndexPath.row + 1) < sections[selectedIndexPath.section].rows.count {
				self.tableView.selectRow(at: NSIndexPath(row: selectedIndexPath.row + 1, section: selectedIndexPath.section) as IndexPath, animated: true, scrollPosition: .middle)
			} else if (selectedIndexPath.section + 1) < sections.count {
				// New Section
				self.tableView.selectRow(at: NSIndexPath(row: 0, section: (selectedIndexPath.section + 1)) as IndexPath, animated: true, scrollPosition: .middle)
			}
		} else {
			self.tableView.selectRow(at: NSIndexPath(row: 0, section: 0) as IndexPath, animated: true, scrollPosition: .top)
		}

		if let selectedIndexPath = self.tableView?.indexPathForSelectedRow {
			let staticRow = staticRowForIndexPath(selectedIndexPath)
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
			} else if staticRow.type == .slider {
				let sliders = staticRow.cell?.subviews.filter { $0 is UISlider }
				if let slider = sliders?.first as? UISlider {
					slider.thumbTintColor = .white
				}
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

	override public var keyCommands: [UIKeyCommand]? {
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
			var item = rootItem
			if let indexPath = self.tableView?.indexPathForSelectedRow, let selectedItem = itemAt(indexPath: indexPath) {
				item = selectedItem
			}
			let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .moreFolder)
			let actionContext = ActionContext(viewController: self, core: core, items: [item], location: actionsLocation)
			let actions = Action.sortedApplicableActions(for: actionContext)

			actions.forEach({
				if let keyCommand = $0.actionExtension.keyCommand, let keyModifierFlags = $0.actionExtension.keyModifierFlags {
					let actionCommand = UIKeyCommand(input: keyCommand, modifierFlags: keyModifierFlags, action: #selector(performFolderAction), discoverabilityTitle: $0.actionExtension.name)
					shortcuts.append(actionCommand)
				}
			})
		}

		return shortcuts
	}

	@objc func performFolderAction(_ command : UIKeyCommand) {
		if let core = core, let rootItem = query.rootItem {
			var item = rootItem
			if let indexPath = self.tableView?.indexPathForSelectedRow, let selectedItem = itemAt(indexPath: indexPath) {
				item = selectedItem
			}
			let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .moreFolder)
			let actionContext = ActionContext(viewController: self, core: core, items: [item], location: actionsLocation)
			let actions = Action.sortedApplicableActions(for: actionContext)
			actions.forEach({
				if command.discoverabilityTitle == $0.actionExtension.name {
					$0.perform()
				}
			})
		}
	}

	override open var canBecomeFirstResponder: Bool {
		return true
	}
}

extension LibrarySharesTableViewController {

	override public var canBecomeFirstResponder: Bool {
		return true
	}

	override public var keyCommands: [UIKeyCommand]? {

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

	override open var canBecomeFirstResponder: Bool {
		return true
	}

	override open var keyCommands: [UIKeyCommand]? {

		var shortcuts = [UIKeyCommand]()

		let nextObjectCommand = UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: "Select Next".localized)
		let selectLastPageObjectCommand = UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [.command], action: #selector(selectLastPageObject), discoverabilityTitle: "Select Last Item on Page".localized)
		let previousObjectCommand = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrevious), discoverabilityTitle: "Select Previous".localized)
		let selectObjectCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: "Open Selected".localized)
		let scrollTopCommand = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [.command, .shift], action: #selector(scrollToFirstRow), discoverabilityTitle: "Scroll to Top".localized)
		let scrollBottomCommand = UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [.command, .shift], action: #selector(scrollToLastRow), discoverabilityTitle: "Scroll to Bottom".localized)
		let toggleSortCommand = UIKeyCommand(input: "S", modifierFlags: [.command, .shift], action: #selector(toggleSortOrder), discoverabilityTitle: "Change Sort Order".localized)
		let searchCommand = UIKeyCommand(input: "F", modifierFlags: [.command], action: #selector(enableSearch), discoverabilityTitle: "Search".localized)
		// Add key commands for file name letters
		if sortMethod == .alphabetically {
			let indexTitles = Array( Set( self.items.map { String(( $0.name?.first!.uppercased())!) })).sorted()
			for title in indexTitles {
				let letterCommand = UIKeyCommand(input: title, modifierFlags: [], action: #selector(selectLetter))
				shortcuts.append(letterCommand)
			}
		}

		if let core = core, let rootItem = query.rootItem {
			var item = rootItem
			if let indexPath = self.tableView?.indexPathForSelectedRow, let selectedItem = itemAt(indexPath: indexPath) {
				item = selectedItem
			}
			let actionsLocationCollaborate = OCExtensionLocation(ofType: .action, identifier: .keyboardShortcut)
			let actionContextCollaborate = ActionContext(viewController: self, core: core, items: [item], location: actionsLocationCollaborate)
			let actionsCollaborate = Action.sortedApplicableActions(for: actionContextCollaborate)

			actionsCollaborate.forEach({
				if let keyCommand = $0.actionExtension.keyCommand, let keyModifierFlags = $0.actionExtension.keyModifierFlags {
					let actionCommand = UIKeyCommand(input: keyCommand, modifierFlags: keyModifierFlags, action: #selector(performMoreItemAction), discoverabilityTitle: $0.actionExtension.name)
					shortcuts.append(actionCommand)
				}
			})
		}

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
		if let core = core, let rootItem = query.rootItem {
			var item = rootItem
			if let indexPath = self.tableView?.indexPathForSelectedRow, let selectedItem = itemAt(indexPath: indexPath) {
				item = selectedItem
			}
			let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .keyboardShortcut)
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
		for method in SortMethod.all {
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
}

extension ClientDirectoryPickerViewController {
	override public var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()

		let nextObjectCommand = UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: "Select Next".localized)
		let previousObjectCommand = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrevious), discoverabilityTitle: "Select Previous".localized)
		let selectObjectCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: "Open Selected".localized)
		shortcuts.append(nextObjectCommand)
		shortcuts.append(previousObjectCommand)
		shortcuts.append(selectObjectCommand)

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

	override public var canBecomeFirstResponder: Bool {
		return true
	}
}

extension PhotoAlbumTableViewController {
	override public var keyCommands: [UIKeyCommand]? {
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

	override public var canBecomeFirstResponder: Bool {
		return true
	}
}

extension PhotoSelectionViewController {

	override public var keyCommands: [UIKeyCommand]? {
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

	override public var canBecomeFirstResponder: Bool {
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

	override public var keyCommands: [UIKeyCommand]? {
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

	override public var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()
		if let superKeyCommands = super.keyCommands {
			shortcuts.append(contentsOf: superKeyCommands)
		}

		let nextObjectCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: "Next".localized)
		let previousObjectCommand = UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(selectPrevious), discoverabilityTitle: "Previous".localized)

		var showCommands = false
		if (self.viewControllers?.first as? PDFViewerViewController) != nil {
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

	override public var canBecomeFirstResponder: Bool {
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
