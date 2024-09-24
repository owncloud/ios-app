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
import CoreMedia

extension ServerListTableViewController {
	override var keyCommands: [UIKeyCommand]? {
		let nextObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: OCLocalizedString("Select Next", nil))
		let previousObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrevious), discoverabilityTitle: OCLocalizedString("Select Previous", nil))
		let selectObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: OCLocalizedString("Open Selected", nil))
		let addAccountCommand = UIKeyCommand.ported(input: "+", modifierFlags: [.command], action: #selector(addBookmark), discoverabilityTitle: OCLocalizedString("Add account", nil).localized)
		let openSettingsCommand = UIKeyCommand.ported(input: ",", modifierFlags: [.command], action: #selector(settings), discoverabilityTitle: OCLocalizedString("Settings", nil).localized)

		let editSettingsCommand = UIKeyCommand.ported(input: ",", modifierFlags: [.command, .shift], action: #selector(editBookmark), discoverabilityTitle: OCLocalizedString("Edit", nil))
		let manageSettingsCommand = UIKeyCommand.ported(input: "M", modifierFlags: [.command, .shift], action: #selector(manageBookmark), discoverabilityTitle: OCLocalizedString("Manage", nil))
		let deleteSettingsCommand = UIKeyCommand.ported(input: "\u{08}", modifierFlags: [.command, .shift], action: #selector(deleteBookmarkCommand), discoverabilityTitle: OCLocalizedString("Delete", nil))

		var shortcuts = [UIKeyCommand]()
		if let selectedRow = self.tableView?.indexPathForSelectedRow?.row {
			shortcuts.append(editSettingsCommand)
			shortcuts.append(manageSettingsCommand)
			shortcuts.append(deleteSettingsCommand)
			if UIDevice.current.isIpad {
				let openWindowCommand = UIKeyCommand.ported(input: "W", modifierFlags: [.command, .shift], action: #selector(openSelectedBookmarkInWindow), discoverabilityTitle: OCLocalizedString("Open in new Window", nil))
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
			let selectAccountCommand = UIKeyCommand.ported(input: accountIndex, modifierFlags: [.command, .shift], action: #selector(selectBookmark), discoverabilityTitle: bookmark.shortName)
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
			delete(bookmark: bookmark, at: indexPath) {
				OnMainThread {
					self.tableView.performBatchUpdates({
						self.tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.fade)
					}, completion: { (_) in
						self.ignoreServerListChanges = false
					})
				}
			}
		}
	}
}

extension StaticLoginSingleAccountServerListViewController {

	override var keyCommands: [UIKeyCommand]? {
		let nextObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: OCLocalizedString("Select Next", nil))
		let previousObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrevious), discoverabilityTitle: OCLocalizedString("Select Previous", nil))
		let selectObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: OCLocalizedString("Open Selected", nil))

		var shortcuts = [UIKeyCommand]()
		if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
			shortcuts.append(nextObjectCommand)
			if selectedIndexPath.section != 0 || (selectedIndexPath.section == 0 && selectedIndexPath.row != 0) {
				shortcuts.append(previousObjectCommand)
			}
			shortcuts.append(selectObjectCommand)
		} else if self.tableView?.numberOfRows(inSection: 0) ?? 0 > 0 {
			shortcuts.append(nextObjectCommand)
		}

		return shortcuts
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}
}

extension BookmarkViewController {
	override var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()
		if let superKeyCommands = super.keyCommands {
			shortcuts.append(contentsOf: superKeyCommands)
		}
		let cancelCommand = UIKeyCommand.ported(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismiss), discoverabilityTitle: OCLocalizedString("Cancel", nil))
		shortcuts.append(cancelCommand)

		let continueCommand = UIKeyCommand.ported(input: "C", modifierFlags: [.command], action: #selector(handleContinue), discoverabilityTitle: OCLocalizedString("Continue", nil))
		shortcuts.append(continueCommand)

		return shortcuts
	}

	override var canBecomeFirstResponder: Bool {
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
				let command = UIKeyCommand.ported(input: String(counter), modifierFlags: [.command], action: #selector(tapActionButton), discoverabilityTitle: title)
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

		let doneCommand = UIKeyCommand.ported(input: "D", modifierFlags: [.command], action: #selector(userActionDone), discoverabilityTitle: OCLocalizedString("Done", nil))
		shortcuts.append(doneCommand)

		return shortcuts
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}
}

extension ThemeNavigationController {
	open override var keyCommands: [UIKeyCommand]? {

		var shortcuts = [UIKeyCommand]()

		if self.viewControllers.count > 1, !(self.visibleViewController?.isKind(of: UIAlertController.self) ?? true) {
			let backCommand = UIKeyCommand.ported(input: UIKeyCommand.inputUpArrow, modifierFlags: [.command], action: #selector(popViewControllerAnimated), discoverabilityTitle: OCLocalizedString("Back", nil))
			shortcuts.append(backCommand)
		}

		return shortcuts
	}

	open override var canBecomeFirstResponder: Bool {
		return true
	}

	@objc func popViewControllerAnimated() {
		_ = popViewController(animated: true)
	}
}

extension NamingViewController {
	open override var keyCommands: [UIKeyCommand]? {

		var shortcuts = [UIKeyCommand]()
		if let leftItem = self.navigationItem.leftBarButtonItem, let action = leftItem.action {
			let dismissCommand = UIKeyCommand.ported(input: UIKeyCommand.inputEscape, modifierFlags: [], action: action, discoverabilityTitle: OCLocalizedString("Cancel", nil))
			shortcuts.append(dismissCommand)
		}
		if let rightItem = self.navigationItem.rightBarButtonItem, let action = rightItem.action {
			let doneCommand = UIKeyCommand.ported(input: "D", modifierFlags: [.command], action: action, discoverabilityTitle: OCLocalizedString("Done", nil))
			shortcuts.append(doneCommand)
		}

		return shortcuts
	}

	open override var canBecomeFirstResponder: Bool {
		return true
	}
}

extension PDFSearchViewController {

	override var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()

		let nextObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: OCLocalizedString("Select Next", nil))
		let previousObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrevious), discoverabilityTitle: OCLocalizedString("Select Previous", nil))
		let selectObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: OCLocalizedString("Open Selected", nil))
		let cancelCommand = UIKeyCommand.ported(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismiss), discoverabilityTitle: OCLocalizedString("Cancel", nil))

		if self.tableView.numberOfRows(inSection: 0) > 0 {
			shortcuts.append(nextObjectCommand)
		}
		if self.tableView.indexPathForSelectedRow?.row ?? 0 > 0 {
			shortcuts.append(previousObjectCommand)
		}
		if (self.tableView?.indexPathForSelectedRow) != nil {
			shortcuts.append(selectObjectCommand)
		}
		shortcuts.append(cancelCommand)

		return shortcuts
	}

	override var canBecomeFirstResponder: Bool {
		return false
	}
}

extension ClientRootViewController {
	override var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()

		let excludeViewControllers = [ThemedAlertController.self, SharingTableViewController.self, PublicLinkTableViewController.self, PublicLinkEditTableViewController.self, GroupSharingEditTableViewController.self]

		if let navigationController = self.selectedViewController as? ThemeNavigationController, let visibleController = navigationController.visibleViewController {
			if excludeViewControllers.contains(where: {$0 == type(of: visibleController)}) {
				return shortcuts
			} else if let controller = visibleController as? PDFSearchViewController {
				return controller.keyCommands
			}
		}

		if let navigationController = self.selectedViewController as? ThemeNavigationController, navigationController.visibleViewController?.navigationItem.searchController?.isActive ?? false {
			let cancelCommand = UIKeyCommand.ported(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismissSearch), discoverabilityTitle: OCLocalizedString("Cancel", nil))
			shortcuts.append(cancelCommand)

			if let visibleViewController = navigationController.visibleViewController, let keyCommands = visibleViewController.keyCommands {
				let newKeyCommands = keyCommands.map { (keyCommand) -> UIKeyCommand in
					if let input = keyCommand.input, let discoverabilityTitle = keyCommand.discoverabilityTitle {
						return UIKeyCommand.ported(input: input, modifierFlags: keyCommand.modifierFlags, action: #selector(performActionOnVisibleViewController), discoverabilityTitle: discoverabilityTitle)
					}

					return UIKeyCommand(input: keyCommand.input!, modifierFlags: keyCommand.modifierFlags, action: #selector(performActionOnVisibleViewController))
				}

				shortcuts.append(contentsOf: newKeyCommands)
			}
		}

		if let navigationController = self.selectedViewController as? ThemeNavigationController, !((navigationController.visibleViewController as? UIAlertController) != nil) {
			let keyCommands = self.tabBar.items?.enumerated().map { (index, item) -> UIKeyCommand in
				let tabIndex = String(index + 1)
				return UIKeyCommand.ported(input: tabIndex, modifierFlags: .command, action:#selector(selectTab), discoverabilityTitle: item.title ?? String(format: OCLocalizedString("Tab %@", nil), tabIndex))
			}
			if let keyCommands = keyCommands, self.presentedViewController == nil {
				shortcuts.append(contentsOf: keyCommands)
			}
		}

		if let availableStyles = ThemeStyle.availableStyles, availableStyles.count > 1 {
			let switchThemeCommand = UIKeyCommand.ported(input: "T", modifierFlags: [.alternate], action: #selector(switchTheme), discoverabilityTitle: OCLocalizedString("Switch Theme Style", nil))
			shortcuts.append(switchThemeCommand)
		}

		return shortcuts
	}

	@objc func switchTheme(sender: UIKeyCommand) {
		if let availableStyles = ThemeStyle.availableStyles {
			let currentIndex = availableStyles.firstIndex(of: ThemeStyle.preferredStyle) ?? 0
			var newStyle = ThemeStyle.preferredStyle
			if currentIndex + 1 < availableStyles.count {
				newStyle = availableStyles[currentIndex + 1]
			} else if let style = availableStyles.first {
				newStyle = style
			}

			ThemeStyle.followSystemAppearance = false
			ThemeStyle.preferredStyle = newStyle
		}
	}

	@objc func performActionOnVisibleViewController(sender: UIKeyCommand) {
		if let navigationController = self.selectedViewController as? ThemeNavigationController, let visibleController = navigationController.visibleViewController, let keyCommands = visibleController.keyCommands {
			let commands = keyCommands.filter { (keyCommand) -> Bool in
				if keyCommand.discoverabilityTitle == sender.discoverabilityTitle {
					return true
				}
				return false
			}

			if let command = commands.first {
				visibleController.perform(command.action, with: sender)
			}
		}
	}

	@objc func dismissSearch(sender: UIKeyCommand) {
		if let navigationController = self.selectedViewController as? ThemeNavigationController {
			if let searchController = navigationController.visibleViewController?.navigationItem.searchController {
				searchController.isActive = false
			}
		}
	}

	@objc func selectTab(sender: UIKeyCommand) {
		if let newIndex = Int(sender.input!), newIndex >= 1 && newIndex <= (self.tabBar.items?.count ?? 0) {
			self.selectedIndex = newIndex - 1
		}
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}

	@objc func selectNext(sender: UIKeyCommand) {
		if let navigationController = self.selectedViewController as? ThemeNavigationController, let visibleController = navigationController.visibleViewController {

			if let controller = visibleController as? PDFSearchViewController {
				controller.selectNext(sender: sender)
			}
		}
	}

	@objc func selectPrevious(sender: UIKeyCommand) {
		if let navigationController = self.selectedViewController as? ThemeNavigationController, let visibleController = navigationController.visibleViewController {

			if let controller = visibleController as? PDFSearchViewController {
				controller.selectPrevious(sender: sender)
			}
		}
	}

	@objc func selectCurrent(sender: UIKeyCommand) {
		if let navigationController = self.selectedViewController as? ThemeNavigationController, let visibleController = navigationController.visibleViewController {

			if let controller = visibleController as? PDFSearchViewController {
				controller.selectCurrent(sender: sender)
			}
		}
	}
}

extension UITableViewController {

	@objc func selectNext(sender: UIKeyCommand) {
		if let selectedIndexPath = self.tableView?.indexPathForSelectedRow {
			if selectedIndexPath.row < (self.tableView?.numberOfRows(inSection: selectedIndexPath.section) ?? 0 ) - 1 {
				self.tableView.selectRow(at: NSIndexPath(row: selectedIndexPath.row + 1, section: selectedIndexPath.section) as IndexPath, animated: true, scrollPosition: .middle)
			} else if (selectedIndexPath.section + 1) < self.tableView?.numberOfSections ?? 0 {
				// New Section
				self.tableView.selectRow(at: NSIndexPath(row: 0, section: (selectedIndexPath.section + 1)) as IndexPath, animated: true, scrollPosition: .middle)
			}
		} else if self.tableView?.numberOfRows(inSection: 0) ?? 0 > 0 {
			self.tableView.selectRow(at: NSIndexPath(row: 0, section: 0) as IndexPath, animated: true, scrollPosition: .top)
		}
	}

	@objc func selectPrevious(sender: UIKeyCommand) {
		guard let selectedIndexPath = self.tableView?.indexPathForSelectedRow else { return }

		if selectedIndexPath.row > 0 {
			if selectedIndexPath.row == 0, selectedIndexPath.section > 0 {
				self.tableView.selectRow(at: NSIndexPath(row: tableView.numberOfRows(inSection: selectedIndexPath.section - 1) - 1, section: selectedIndexPath.section - 1) as IndexPath, animated: true, scrollPosition: .middle)
			} else {
				self.tableView.selectRow(at: NSIndexPath(row: selectedIndexPath.row - 1, section: selectedIndexPath.section) as IndexPath, animated: true, scrollPosition: .middle)
			}
		} else if selectedIndexPath.row == 0, selectedIndexPath.section > 0 {
			let section = selectedIndexPath.section - 1
			if let numberOfRows = self.tableView?.numberOfRows(inSection: section), numberOfRows > 0 {
				self.tableView.selectRow(at: NSIndexPath(row: numberOfRows - 1, section: section) as IndexPath, animated: true, scrollPosition: .middle)
			}
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

extension StaticTableViewController {

	open override var keyCommands: [UIKeyCommand]? {
		let nextObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: OCLocalizedString("Select Next", nil))
		let previousObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrevious), discoverabilityTitle: OCLocalizedString("Select Previous", nil))
		let selectObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: OCLocalizedString("Open Selected", nil))

		var shortcuts = [UIKeyCommand]()

		if let visibleViewController = self.presentedViewController as? UIAlertController, let keyCommands = visibleViewController.keyCommands {
			let newKeyCommands = keyCommands.map { (keyCommand) -> UIKeyCommand in
				if let input = keyCommand.input, let discoverabilityTitle = keyCommand.discoverabilityTitle {
					return UIKeyCommand.ported(input: input, modifierFlags: keyCommand.modifierFlags, action: #selector(performActionOnVisibleViewController), discoverabilityTitle: discoverabilityTitle)
				}

				return UIKeyCommand(input: keyCommand.input!, modifierFlags: keyCommand.modifierFlags, action: #selector(performActionOnVisibleViewController))
			}
			return newKeyCommands
		}

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
				let sliderDownCommand = UIKeyCommand.ported(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(sliderDown), discoverabilityTitle: OCLocalizedString("Decrease Slider Value", nil))
				let sliderUpCommand = UIKeyCommand.ported(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(sliderUp), discoverabilityTitle: OCLocalizedString("Increase Slider Value", nil))
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

	open override var canBecomeFirstResponder: Bool {
		return true
	}

	@objc func performActionOnVisibleViewController(sender: UIKeyCommand) {
		if let visibleViewController = self.presentedViewController as? UIAlertController, let keyCommands = visibleViewController.keyCommands {

				let commands = keyCommands.filter { (keyCommand) -> Bool in
					if keyCommand.discoverabilityTitle == sender.discoverabilityTitle {
						return true
					}
					return false
				}

				if let command = commands.first {
					visibleViewController.perform(command.action, with: sender)
				}
		}
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
			if staticRow.type == .switchButton, let switchButton = staticRow.cell?.accessoryView as? UISwitch, switchButton.isEnabled {
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

	open override var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()

		let scopeCommand = UIKeyCommand.ported(input: "F", modifierFlags: [.command], action: #selector(changeSearchScope(_:)), discoverabilityTitle: OCLocalizedString("Toggle Search Scope", nil))
		if let searchController = searchController, searchController.isActive {
			shortcuts.append(scopeCommand)
		}

		if let superKeyCommands = super.keyCommands {
			shortcuts.append(contentsOf: superKeyCommands)
		}

		if searchController?.isActive ?? false, searchScope == .global, hasSearchResults, self.tableView?.indexPathForSelectedRow != nil {
			let revealObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputRightArrow, modifierFlags: [.command], action: #selector(revealItem), discoverabilityTitle: OCLocalizedString("Reveal in folder", nil))
			shortcuts.append(revealObjectCommand)
		}

		let nextObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: OCLocalizedString("Select Next", nil))
		let previousObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrevious), discoverabilityTitle: OCLocalizedString("Select Previous", nil))
		let selectObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: OCLocalizedString("Open Selected", nil))

		if let selectedIndexPath = self.tableView?.indexPathForSelectedRow {
			if selectedIndexPath.row < self.items.count - 1 {
				shortcuts.append(nextObjectCommand)
			}
			if selectedIndexPath.row > 0 || selectedIndexPath.section > 0 {
				shortcuts.append(previousObjectCommand)
			}
			shortcuts.append(selectObjectCommand)
		} else {
			shortcuts.append(nextObjectCommand)
		}

		if let core = core, let rootItem = query.rootItem, !isMoreButtonPermanentlyHidden {
			var item = rootItem
			if let indexPath = self.tableView?.indexPathForSelectedRow, let selectedItem = itemAt(indexPath: indexPath) {
				item = selectedItem
			}
			let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .moreFolder)
			let actionContext = ActionContext(viewController: self, core: core, items: [item], location: actionsLocation, preferences: ["rootItem" :  rootItem])
			let actions = Action.sortedApplicableActions(for: actionContext)

			actions.forEach({
				if let keyCommand = $0.actionExtension.keyCommand, let keyModifierFlags = $0.actionExtension.keyModifierFlags {
					let actionCommand = UIKeyCommand.ported(input: keyCommand, modifierFlags: keyModifierFlags, action: #selector(performFolderAction), discoverabilityTitle: $0.actionExtension.name)
					shortcuts.append(actionCommand)
				}
			})
		}

		return shortcuts
	}

	@objc func revealItem(_ command : UIKeyCommand) {
		if let indexPath = self.tableView?.indexPathForSelectedRow, let cell = tableView(self.tableView, cellForRowAt: indexPath) as? ClientItemCell {
			revealButtonTapped(cell: cell)
		}
	}

	@objc func changeSearchScope(_ command : UIKeyCommand) {
		if self.sortBar?.searchScope == .global {
			self.sortBar?.searchScope = .local
		} else {
			self.sortBar?.searchScope = .global
		}
		updateCustomSearchQuery()
		self.searchController?.isActive = true
		self.searchController?.searchBar.becomeFirstResponder()
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

	open override var canBecomeFirstResponder: Bool {
		return true
	}
}

extension LibrarySharesTableViewController {

	override var canBecomeFirstResponder: Bool {
		return true
	}

	override var keyCommands: [UIKeyCommand]? {

		var shortcuts = [UIKeyCommand]()

		let nextObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: OCLocalizedString("Select Next", nil))
		let previousObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrevious), discoverabilityTitle: OCLocalizedString("Select Previous", nil))
		let selectObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: OCLocalizedString("Open Selected", nil))

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

		let nextObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: OCLocalizedString("Select Next", nil))
		let selectLastPageObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputDownArrow, modifierFlags: [.command], action: #selector(selectLastPageObject), discoverabilityTitle: OCLocalizedString("Select Last Item on Page", nil))
		let previousObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrevious), discoverabilityTitle: OCLocalizedString("Select Previous", nil))
		let selectObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: OCLocalizedString("Open Selected", nil))
		let scrollTopCommand = UIKeyCommand.ported(input: UIKeyCommand.inputUpArrow, modifierFlags: [.command, .shift], action: #selector(scrollToFirstRow), discoverabilityTitle: OCLocalizedString("Scroll to Top", nil))
		let scrollBottomCommand = UIKeyCommand.ported(input: UIKeyCommand.inputDownArrow, modifierFlags: [.command, .shift], action: #selector(scrollToLastRow), discoverabilityTitle: OCLocalizedString("Scroll to Bottom", nil))
		let toggleSortCommand = UIKeyCommand.ported(input: "S", modifierFlags: [.alternate], action: #selector(toggleSortOrder), discoverabilityTitle: OCLocalizedString("Change Sort Order", nil))
		let searchCommand = UIKeyCommand.ported(input: "F", modifierFlags: [.command], action: #selector(enableSearch), discoverabilityTitle: OCLocalizedString("Search", nil))
		// Add key commands for file name letters
		if sortMethod == .alphabetically, let searchController = searchController, !searchController.isActive {
			let indexTitles = Array( Set( self.items.map { String(( $0.name?.first!.uppercased())!) })).sorted()
			for title in indexTitles {
				let letterCommand = UIKeyCommand(input: title, modifierFlags: [], action: #selector(selectLetter))
				shortcuts.append(letterCommand)
			}
		}

		if let core = core, let rootItem = query.rootItem, !isMoreButtonPermanentlyHidden {
			var item = rootItem
			if let indexPath = self.tableView?.indexPathForSelectedRow, let selectedItem = itemAt(indexPath: indexPath) {
				item = selectedItem
			}
			let actionsLocationCollaborate = OCExtensionLocation(ofType: .action, identifier: .keyboardShortcut)
			let actionContextCollaborate = ActionContext(viewController: self, core: core, items: [item], location: actionsLocationCollaborate)
			let actionsCollaborate = Action.sortedApplicableActions(for: actionContextCollaborate)

			actionsCollaborate.forEach({
				if let keyCommand = $0.actionExtension.keyCommand, let keyModifierFlags = $0.actionExtension.keyModifierFlags {
					let actionCommand = UIKeyCommand.ported(input: keyCommand, modifierFlags: keyModifierFlags, action: #selector(performMoreItemAction), discoverabilityTitle: $0.actionExtension.name)
					shortcuts.append(actionCommand)
				}
			})
		}

		if let searchController = searchController, !searchController.isActive {
			shortcuts.append(searchCommand)
		}
		shortcuts.append(toggleSortCommand)

		for (index, method) in SortMethod.all.enumerated() {
			let sortTitle = String(format: OCLocalizedString("Sort by %@", nil), method.localizedName)
			let sortCommand = UIKeyCommand.ported(input: String(index + 1), modifierFlags: [.alternate], action: #selector(changeSortMethod), discoverabilityTitle: sortTitle)
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
				if let itemIndex = self.items.firstIndex(of: firstItem) {
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
			let actionContext = ActionContext(viewController: self, core: core, items: [item], location: actionsLocation, preferences: ["rootItem" : rootItem])
			actionContext.sender = command
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
			let sortTitle = String(format: OCLocalizedString("Sort by %@", nil), method.localizedName)
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
	open override var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()

		if let superKeyCommands = super.keyCommands {
			shortcuts.append(contentsOf: superKeyCommands)
		}

		if let selectButtonTitle = selectButton?.title, let selector = selectButton?.action {
			let doCommand = UIKeyCommand.ported(input: "\r", modifierFlags: [.command], action: selector, discoverabilityTitle: selectButtonTitle)
			shortcuts.append(doCommand)
		}

		let createFolder = UIKeyCommand.ported(input: "N", modifierFlags: [.command], action: #selector(createFolderButtonPressed), discoverabilityTitle: OCLocalizedString("Create Folder", nil))
		shortcuts.append(createFolder)
		let dismissCommand = UIKeyCommand.ported(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismiss), discoverabilityTitle: OCLocalizedString("Cancel", nil))
		shortcuts.append(dismissCommand)

		return shortcuts
	}

	open override var canBecomeFirstResponder: Bool {
		return true
	}
}

extension PhotoAlbumTableViewController {
	override var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()
		if let superKeyCommands = super.keyCommands {
			shortcuts.append(contentsOf: superKeyCommands)
		}

		let nextObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: OCLocalizedString("Select Next", nil))
		let previousObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPrevious), discoverabilityTitle: OCLocalizedString("Select Previous", nil))
		let selectObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: OCLocalizedString("Open Selected", nil))

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

		let dismissCommand = UIKeyCommand.ported(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismiss), discoverabilityTitle: OCLocalizedString("Cancel", nil))
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

		let nextObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: OCLocalizedString("Select Next", nil))
		let previousObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(selectPrevious), discoverabilityTitle: OCLocalizedString("Select Previous", nil))
		let selectObjectCommand = UIKeyCommand.ported(input: " ", modifierFlags: [], action: #selector(selectCurrent), discoverabilityTitle: OCLocalizedString("Select", nil))
		let selectAllCommand = UIKeyCommand.ported(input: "A", modifierFlags: [.command], action: #selector(selectAllItems), discoverabilityTitle: OCLocalizedString("Select All", nil))
		let deselectAllCommand = UIKeyCommand.ported(input: "D", modifierFlags: [.command], action: #selector(deselectAllItems), discoverabilityTitle: OCLocalizedString("Deselect All", nil))
		let uploadCommand = UIKeyCommand.ported(input: "U", modifierFlags: [.command], action: #selector(upload), discoverabilityTitle: OCLocalizedString("Upload", nil))
		let dismissCommand = UIKeyCommand.ported(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismiss), discoverabilityTitle: OCLocalizedString("Cancel", nil))

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

extension DisplayHostViewController {

	override var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()
		if let superKeyCommands = super.keyCommands {
			shortcuts.append(contentsOf: superKeyCommands)
		}

		let nextObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectNext), discoverabilityTitle: OCLocalizedString("Next", nil))
		let previousObjectCommand = UIKeyCommand.ported(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(selectPrevious), discoverabilityTitle: OCLocalizedString("Previous", nil))

		var showCommands = false
		if let pdfViewController = self.viewControllers?.first as? PDFViewerViewController {
			showCommands = true

			let searchCommand = UIKeyCommand.ported(input: "S", modifierFlags: [.command], action: #selector(search), discoverabilityTitle: OCLocalizedString("Search", nil))
			let gotoCommand = UIKeyCommand.ported(input: "G", modifierFlags: [.control], action: #selector(goToPage), discoverabilityTitle: OCLocalizedString("Go to Page", nil))

			if !pdfViewController.searchResultsView.isHidden, pdfViewController.searchResultsView.matches?.count ?? 0 > 0 {

				if pdfViewController.searchResultsView.forwardButton.isEnabled {
					let findNextCommand = UIKeyCommand.ported(input: "G", modifierFlags: [.command], action: #selector(findNext), discoverabilityTitle: OCLocalizedString("Find Next", nil))
				shortcuts.append(findNextCommand)
				}

				if pdfViewController.searchResultsView.backButton.isEnabled {
					let findPreviousCommand = UIKeyCommand.ported(input: "G", modifierFlags: [.command, .shift], action: #selector(findPrevious), discoverabilityTitle: OCLocalizedString("Find Previous", nil))
				shortcuts.append(findPreviousCommand)
				}

				let closeFindCommand = UIKeyCommand.ported(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(closeFind), discoverabilityTitle: OCLocalizedString("Close Search", nil))
				shortcuts.append(closeFindCommand)
			}

			shortcuts.append(searchCommand)
			shortcuts.append(gotoCommand)
		} else if let viewController = (self.viewControllers?.first as? MediaDisplayViewController) {
			let fullscreenCommand = UIKeyCommand.ported(input: "F", modifierFlags: [], action: #selector(enterFullScreen), discoverabilityTitle: OCLocalizedString("Full Screen", nil))
			let playbackCommand = UIKeyCommand.ported(input: " ", modifierFlags: [], action: #selector(tooglePlayback), discoverabilityTitle: OCLocalizedString("Play/Pause", nil))
			let seekBackwardCommand = UIKeyCommand.ported(input: UIKeyCommand.inputLeftArrow, modifierFlags: [.control], action: #selector(seek), discoverabilityTitle: OCLocalizedString("Skip Back", nil))
			let seekForwardCommand = UIKeyCommand.ported(input: UIKeyCommand.inputRightArrow, modifierFlags: [.control], action: #selector(seek), discoverabilityTitle: OCLocalizedString("Skip Ahead", nil))
			let replayCommand = UIKeyCommand.ported(input: UIKeyCommand.inputLeftArrow, modifierFlags: [.command], action: #selector(replay), discoverabilityTitle: OCLocalizedString("Go to Beginning", nil))
			let muteCommand = UIKeyCommand.ported(input: "M", modifierFlags: [], action: #selector(toggleMute), discoverabilityTitle: OCLocalizedString("Mute/Unmute", nil))

			if viewController.canEnterFullScreen() {
				shortcuts.append(fullscreenCommand)
			}
			shortcuts.append(playbackCommand)
			shortcuts.append(seekBackwardCommand)
			shortcuts.append(seekForwardCommand)
			shortcuts.append(replayCommand)
			shortcuts.append(muteCommand)
		}
		if let viewController = (self.viewControllers?.first as? DisplayViewController), (viewController.navigationController?.isNavigationBarHidden ?? false) {
			let closeCommand = UIKeyCommand.ported(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(closePresentationMode), discoverabilityTitle: OCLocalizedString("Exit Full Screen", nil))
			shortcuts.append(closeCommand)
		}

		if items?.count ?? 0 > 1 {
			showCommands = true
		}

		if showCommands {
			shortcuts.append(nextObjectCommand)
			shortcuts.append(previousObjectCommand)
		}

		guard let core = core else { return shortcuts }
		guard let currentViewController = self.viewControllers?.first as? DisplayViewController else { return shortcuts }

		if let item = currentViewController.item {
			let actionsLocationCollaborate = OCExtensionLocation(ofType: .action, identifier: .keyboardShortcut)
			let actionContextCollaborate = ActionContext(viewController: currentViewController, core: core, items: [item], location: actionsLocationCollaborate)
			let actionsCollaborate = Action.sortedApplicableActions(for: actionContextCollaborate)

			actionsCollaborate.forEach({
				if let keyCommand = $0.actionExtension.keyCommand, let keyModifierFlags = $0.actionExtension.keyModifierFlags {
					let actionCommand = UIKeyCommand.ported(input: keyCommand, modifierFlags: keyModifierFlags, action: #selector(performMoreItemAction), discoverabilityTitle: $0.actionExtension.name)
					shortcuts.append(actionCommand)
				}
			})
		}

		return shortcuts
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}

	@objc func performMoreItemAction(_ command : UIKeyCommand) {
		guard let core = core else { return }
		guard let currentViewController = self.viewControllers?.first as? DisplayViewController else { return }

		if let item = currentViewController.item {
			let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .keyboardShortcut)
			let actionContext = ActionContext(viewController: currentViewController, core: core, items: [item], location: actionsLocation)
			actionContext.sender = command
			let actions = Action.sortedApplicableActions(for: actionContext)
			actions.forEach({
				if command.discoverabilityTitle == $0.actionExtension.name {
					$0.perform()
				}
			})
		}
	}

	@objc func tooglePlayback() {
		guard let currentViewController = self.viewControllers?.first else { return }

		if let mediaController = currentViewController as? MediaDisplayViewController {
			if mediaController.isPlaying {
				mediaController.pause()
			} else {
				mediaController.play()
			}
		}
	}

	@objc func replay() {
		guard let currentViewController = self.viewControllers?.first else { return }

		if let mediaController = currentViewController as? MediaDisplayViewController {
			mediaController.seek(to: .zero)
			mediaController.play()
		}
	}

	@objc func seek(_ command : UIKeyCommand) {
		guard let currentViewController = self.viewControllers?.first else { return }

		if let mediaController = currentViewController as? MediaDisplayViewController {
			var seekSeconds : Double = 1
			if command.input == UIKeyCommand.inputLeftArrow {
				seekSeconds = -1
			}

			let newTime = CMTimeAdd(mediaController.currentTime(), CMTime(seconds: seekSeconds, preferredTimescale: mediaController.currentTime().timescale))
			mediaController.seek(to: newTime)
		}
	}

	@objc func toggleMute(_ command : UIKeyCommand) {
		guard let currentViewController = self.viewControllers?.first else { return }
		if let mediaController = currentViewController as? MediaDisplayViewController {
			mediaController.toggleMute()
		}
	}

	@objc func enterFullScreen(_ command : UIKeyCommand) {
		guard let currentViewController = self.viewControllers?.first else { return }
		if let mediaController = currentViewController as? MediaDisplayViewController {
			mediaController.enterFullScreen()
		}
	}

	@objc func search() {
		guard let currentViewController = self.viewControllers?.first else { return }

		if let pdfController = currentViewController as? PDFViewerViewController {
			pdfController.search(sender: nil)
		}
	}

	@objc func goToPage() {
		guard let currentViewController = self.viewControllers?.first else { return }

		if let pdfController = currentViewController as? PDFViewerViewController {
			pdfController.goToPage()
		}
	}

	@objc func findNext() {
		guard let currentViewController = self.viewControllers?.first else { return }

		if let pdfController = currentViewController as? PDFViewerViewController {
			pdfController.searchResultsView.forward()
		}
	}

	@objc func findPrevious() {
		guard let currentViewController = self.viewControllers?.first else { return }

		if let pdfController = currentViewController as? PDFViewerViewController {
			pdfController.searchResultsView.back()
		}
	}

	@objc func closeFind() {
		guard let currentViewController = self.viewControllers?.first else { return }

		if let pdfController = currentViewController as? PDFViewerViewController {
			pdfController.searchResultsView.close()
		}
	}

	@objc func closePresentationMode() {
		guard let currentViewController = self.viewControllers?.first else { return }

		if let controller = currentViewController as? DisplayViewController {
			controller.navigationController?.setNavigationBarHidden(false, animated: true)
		}
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

extension AlertViewController {
	override var keyCommands: [UIKeyCommand]? {
		var commands : [UIKeyCommand] = []
		var index : Int = 1
		var defaultCommand : UIKeyCommand?

		if options.count == 1, let option = options.first {
			defaultCommand = UIKeyCommand.ported(input: "\r", modifierFlags: [], action: #selector(chooseDefaultOption), discoverabilityTitle: option.label)
		} else {
			for option in options {
				if option.type == .default {
					defaultCommand = UIKeyCommand.ported(input: "\r", modifierFlags: [], action: #selector(chooseDefaultOption), discoverabilityTitle: option.label)
				} else {
					let command = UIKeyCommand.ported(input: "\(index)", modifierFlags: .command, action: #selector(chooseOption(_:)), discoverabilityTitle: option.label)
					commands.append(command)
				}

				index += 1
			}
		}

		if let defaultCommand = defaultCommand {
			commands.append(defaultCommand)
		}

		return commands
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}

	@objc func chooseDefaultOption() {
		for option in options {
			if option.type == .default {
				alertView?.selectOption(option: option)
				return
			}
		}

		if let firstOption = options.first {
			alertView?.selectOption(option: firstOption)
		}
	}

	@objc func chooseOption(_ sender: Any?) {
		if let command = sender as? UIKeyCommand, let input = command.input, let intInput = Int(input) {
			let offset = intInput - 1

			alertView?.selectOption(option: self.options[offset])
		}
	}
}

extension FrameViewController {
	open override var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()

		if let issuesCard = self.viewController as? IssuesCardViewController {
			if let buttons = issuesCard.alertView?.optionViews {
				var counter = 1
				for button in buttons {
					if let buttonTitle = button.currentTitle {
						let command = UIKeyCommand.ported(input: String(counter), modifierFlags: [.command], action: #selector(issueButtonPressed), discoverabilityTitle: buttonTitle)
						shortcuts.append(command)
					}
					counter += 1
				}
			}
		} else {
			let cancelCommand = UIKeyCommand.ported(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismissCard), discoverabilityTitle: OCLocalizedString("Close", nil))
			shortcuts.append(cancelCommand)
		}

		return shortcuts
	}

	open override var canBecomeFirstResponder: Bool {
		return true
	}

	@objc func dismissCard(_ sender: Any?) {
		self.dismiss(animated: false, completion: nil)
	}

	@objc func issueButtonPressed(_ command : UIKeyCommand) {
		if let issuesCard = self.viewController as? IssuesCardViewController, let alertView = issuesCard.alertView {
			guard let button = alertView.optionViews.first(where: {$0.currentTitle == command.discoverabilityTitle}) else { return }

			alertView.optionSelected(sender: button)
		}
	}
}
