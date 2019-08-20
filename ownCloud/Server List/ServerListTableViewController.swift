//
//  ServerListTableViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.03.18.
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
import PocketSVG

class ServerListTableViewController: UITableViewController, Themeable {
	// MARK: - Views
	@IBOutlet var welcomeOverlayView: UIView!
	@IBOutlet var welcomeTitleLabel : UILabel!
	@IBOutlet var welcomeMessageLabel : UILabel!
	@IBOutlet var welcomeAddServerButton : ThemeButton!
	@IBOutlet var welcomeLogoImageView : UIImageView!
	@IBOutlet var welcomeLogoTVGView : VectorImageView!
	// @IBOutlet var welcomeLogoSVGView : SVGImageView!

	// MARK: - Internals
	var lockedBookmarks : [OCBookmark] = []
	var shownFirstTime = true

	// MARK: - Init
	override init(style: UITableView.Style) {
		super.init(style: style)

		NotificationCenter.default.addObserver(self, selector: #selector(serverListChanged), name: .OCBookmarkManagerListChanged, object: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		NotificationCenter.default.removeObserver(self, name: .OCBookmarkManagerListChanged, object: nil)
	}

	// TODO: Rebuild welcomeOverlayView in code
	/*
	override func loadView() {
	super.loadView()

	welcomeOverlayView = UIView()
	welcomeOverlayView.translatesAutoresizingMaskIntoConstraints = false

	welcomeTitleLabel = UILabel()
	welcomeTitleLabel.font = UIFont.boldSystemFont(ofSize: 34)
	welcomeTitleLabel.translatesAutoresizingMaskIntoConstraints = false

	welcomeAddServerButton = ThemeButton()
	}
	*/

	// MARK: - View controller events
	override func viewDidLoad() {
		super.viewDidLoad()

		OCItem.registerIcons()

		self.navigationController?.navigationBar.prefersLargeTitles = true
		self.navigationController?.navigationBar.isTranslucent = false
		self.navigationController?.toolbar.isTranslucent = false
		self.tableView.register(ServerListBookmarkCell.self, forCellReuseIdentifier: "bookmark-cell")
		self.tableView.rowHeight = UITableView.automaticDimension
		self.tableView.estimatedRowHeight = 80
		self.tableView.allowsSelectionDuringEditing = true

		let addServerBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addBookmark))
		addServerBarButtonItem.accessibilityLabel = "Add account".localized
		addServerBarButtonItem.accessibilityIdentifier = "addAccount"
		self.navigationItem.rightBarButtonItem = addServerBarButtonItem

		welcomeOverlayView.translatesAutoresizingMaskIntoConstraints = false

		Theme.shared.add(tvgResourceFor: "owncloud-logo")
		welcomeLogoTVGView.vectorImage = Theme.shared.tvgImage(for: "owncloud-logo")

		self.navigationItem.title = OCAppIdentity.shared.appName
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.navigationController?.setToolbarHidden(false, animated: animated)
		self.navigationController?.navigationBar.prefersLargeTitles = true

		Theme.shared.register(client: self)

		welcomeOverlayView.layoutSubviews()

		self.tableView.reloadData()
	}

	override func viewDidAppear(_ animated: Bool) {
		var showBetaWarning = true

		super.viewDidAppear(animated)

		updateNoServerMessageVisibility()

		let helpBarButtonItem = UIBarButtonItem(title: "Feedback", style: UIBarButtonItem.Style.plain, target: self, action: #selector(help))
		helpBarButtonItem.accessibilityIdentifier = "helpBarButtonItem"

		let settingsBarButtonItem = UIBarButtonItem(title: "Settings".localized, style: UIBarButtonItem.Style.plain, target: self, action: #selector(settings))
		settingsBarButtonItem.accessibilityIdentifier = "settingsBarButtonItem"

		self.toolbarItems = [
			helpBarButtonItem,
			UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil),
			settingsBarButtonItem
		]

		if shownFirstTime {
			shownFirstTime = false
			
			if let bookmark = OCBookmarkManager.lastBookmarkSelectedForConnection {
				connect(to: bookmark)
				showBetaWarning = false
			}
		}

		if showBetaWarning {
			considerBetaWarning()
		}
	}

	func considerBetaWarning() {
		let lastBetaWarningCommit = OCAppIdentity.shared.userDefaults?.string(forKey: "LastBetaWarningCommit")

		Log.log("Show beta warning: \(String(describing: VendorServices.classSetting(forOCClassSettingsKey: .showBetaWarning) as? Bool))")

		if VendorServices.classSetting(forOCClassSettingsKey: .showBetaWarning) as? Bool == true,
			let lastGitCommit = LastGitCommit(),
			(lastBetaWarningCommit == nil) || (lastBetaWarningCommit != lastGitCommit) {
			// Beta warning has never been shown before - or has last been shown for a different release
			let betaAlert = UIAlertController(with: "Beta Warning", message: "\nThis is a BETA release that may - and likely will - still contain bugs.\n\nYOU SHOULD NOT USE THIS BETA VERSION WITH PRODUCTION SYSTEMS, PRODUCTION DATA OR DATA OF VALUE. YOU'RE USING THIS BETA AT YOUR OWN RISK.\n\nPlease let us know about any issues that come up via the \"Send Feedback\" option in the settings.", okLabel: "Agree") {
				OCAppIdentity.shared.userDefaults?.set(lastGitCommit, forKey: "LastBetaWarningCommit")
				OCAppIdentity.shared.userDefaults?.set(NSDate(), forKey: "LastBetaWarningAcceptDate")
			}

			self.present(betaAlert, animated: true, completion: nil)
		}
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		self.navigationController?.setToolbarHidden(true, animated: animated)

		Theme.shared.unregister(client: self)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		welcomeAddServerButton.themeColorCollection = collection.neutralColors

		self.tableView.applyThemeCollection(collection)

		self.welcomeTitleLabel.applyThemeCollection(collection, itemStyle: .title)
		self.welcomeMessageLabel.applyThemeCollection(collection, itemStyle: .message)
	}

	func updateNoServerMessageVisibility() {
		if OCBookmarkManager.shared.bookmarks.count == 0 {
			let safeAreaLayoutGuide : UILayoutGuide = self.tableView.safeAreaLayoutGuide
			var constraint : NSLayoutConstraint

			if welcomeOverlayView.superview != self.view {

				welcomeOverlayView.alpha = 0

				self.view.addSubview(welcomeOverlayView)

				UIView.animate(withDuration: 0.2, animations: {
					self.welcomeOverlayView.alpha = 1
				})

				welcomeOverlayView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor).isActive = true
				welcomeOverlayView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor).isActive = true

				constraint = welcomeOverlayView.leftAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.leftAnchor, constant: 30)
				constraint.isActive = true
				constraint = welcomeOverlayView.rightAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.rightAnchor, constant: 30)
				constraint.isActive = true

				self.tableView.tableHeaderView = nil
				self.navigationController?.navigationBar.shadowImage = nil

				welcomeAddServerButton.setTitle("Add account".localized, for: .normal)
				welcomeTitleLabel.text = "Welcome".localized
				let welcomeMessage = "Thanks for choosing %@! \n Start by adding your account.".localized
				welcomeMessageLabel.text = welcomeMessage.replacingOccurrences(of: "%@", with: OCAppIdentity.shared.appName ?? "ownCloud")

				tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
				tableView.reloadData()
				tableView.isScrollEnabled = false
			}

			if self.navigationItem.leftBarButtonItem != nil {
				self.navigationItem.leftBarButtonItem = nil
			}

		} else {

			if welcomeOverlayView.superview == self.view {
				welcomeOverlayView.removeFromSuperview()

				tableView.separatorStyle = UITableViewCell.SeparatorStyle.singleLine
				tableView.reloadData()
				tableView.isScrollEnabled = true
			}

			if self.navigationItem.leftBarButtonItem == nil {
				self.navigationItem.leftBarButtonItem = self.editButtonItem
			}

			// Add Header View
			self.tableView.tableHeaderView = ServerListTableHeaderView(frame: CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: 50.0))
			self.navigationController?.navigationBar.shadowImage = UIImage()
			self.tableView.tableHeaderView?.applyThemeCollection(Theme.shared.activeCollection)

			self.addThemableBackgroundView()
		}
	}

	// MARK: - Actions
	@IBAction func addBookmark() {
		showBookmarkUI()
	}

	func showBookmarkUI(edit bookmark: OCBookmark? = nil, performContinue: Bool = false) {
		let viewController : BookmarkViewController = BookmarkViewController(bookmark)
		let navigationController : ThemeNavigationController = ThemeNavigationController(rootViewController: viewController)

		// Prevent any in-progress connection from being shown
		resetPreviousBookmarkSelection()

		// Exit editing mode (unfortunately, self.isEditing = false will not do the trick as it leaves the left bar button unchanged as "Done")
		if self.tableView.isEditing,
			let target = self.navigationItem.leftBarButtonItem?.target,
			let action = self.navigationItem.leftBarButtonItem?.action {
			_ = target.perform(action, with: self)
		}

		self.present(navigationController, animated: true, completion: {
			if performContinue {
				viewController.handleContinue()
			}
		})
	}

	func showBookmarkInfoUI(_ bookmark: OCBookmark) {
		let viewController = BookmarkInfoViewController(bookmark)
		let navigationController : ThemeNavigationController = ThemeNavigationController(rootViewController: viewController)

		// Prevent any in-progress connection from being shown
		resetPreviousBookmarkSelection()

		self.present(navigationController, animated: true, completion: nil)
	}

	var themeCounter : Int = 0

	@IBAction func help() {
		// Prevent any in-progress connection from being shown
		resetPreviousBookmarkSelection()

		VendorServices.shared.sendFeedback(from: self)
	}

	@IBAction func settings() {
		let viewController : SettingsViewController = SettingsViewController(style: .grouped)

		// Prevent any in-progress connection from being shown
		resetPreviousBookmarkSelection()

		self.navigationController?.pushViewController(viewController, animated: true)
	}

	// MARK: - Track external changes
	var ignoreServerListChanges : Bool = false

	@objc func serverListChanged() {
		OnMainThread {
			if !self.ignoreServerListChanges {
				self.tableView.reloadData()
				self.updateNoServerMessageVisibility()
			}
		}
	}

	// MARK: - Connect and locking
	func isLocked(bookmark: OCBookmark, presentAlert: Bool = true) -> Bool {
		if lockedBookmarks.contains(bookmark) {
			if presentAlert {
				let alertController = UIAlertController(title: NSString(format: "'%@' is currently locked".localized as NSString, bookmark.shortName as NSString) as String,
									message: NSString(format: "An operation is currently performed that prevents connecting to '%@'. Please try again later.".localized as NSString, bookmark.shortName as NSString) as String,
									preferredStyle: .alert)

				alertController.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: { (_) in
					// There was an error erasing the vault => re-add bookmark to give user another chance to delete its contents
					OCBookmarkManager.shared.addBookmark(bookmark)
					self.updateNoServerMessageVisibility()
				}))

				self.present(alertController, animated: true, completion: nil)
			}

			return true
		}

		return false
	}

	func connect(to bookmark: OCBookmark) {
		if isLocked(bookmark: bookmark) {
			return
		}

		guard let indexPath = indexPath(for: bookmark) else {
			return
		}

		let clientRootViewController = ClientRootViewController(bookmark: bookmark)

		let bookmarkRow = self.tableView.cellForRow(at: indexPath)
		let activityIndicator = UIActivityIndicatorView(style: .white)

		var bookmarkRowAccessoryView : UIView?

		if bookmarkRow != nil {
			bookmarkRowAccessoryView = bookmarkRow?.accessoryView
			bookmarkRow?.accessoryView = activityIndicator

			activityIndicator.startAnimating()
		}

		self.setLastSelectedBookmark(bookmark, openedBlock: {
			activityIndicator.stopAnimating()
			bookmarkRow?.accessoryView = bookmarkRowAccessoryView
		})

		clientRootViewController.afterCoreStart {
			// Make sure only the UI for the last selected bookmark is actually presented (in case of other bookmarks facing a huge delay and users selecting another bookmark in the meantime)
			if self.lastSelectedBookmark?.uuid == bookmark.uuid {
				OCBookmarkManager.lastBookmarkSelectedForConnection = bookmark

				// Set up custom push transition for presentation
				if let navigationController = self.navigationController {
					let transitionDelegate = PushTransitionDelegate()

					clientRootViewController.pushTransition = transitionDelegate // Keep a reference, so it's still around on dismissal
					clientRootViewController.transitioningDelegate = transitionDelegate
					clientRootViewController.modalPresentationStyle = .custom

					navigationController.present(clientRootViewController, animated: true, completion: {
						self.resetPreviousBookmarkSelection(bookmark)
					})
				}
			}
		}
	}

	// MARK: - Table view delegate
	var lastSelectedBookmark : OCBookmark?
	var lastSelectedBookmarkOpenedBlock : (() -> Void)?

	func setLastSelectedBookmark(_ bookmark: OCBookmark, openedBlock: (() -> Void)?) {
		resetPreviousBookmarkSelection()

		lastSelectedBookmark = bookmark
		lastSelectedBookmarkOpenedBlock = openedBlock
	}

	func resetPreviousBookmarkSelection(_ bookmark: OCBookmark? = nil) {
		if (bookmark == nil) || ((bookmark != nil) && (bookmark?.uuid == lastSelectedBookmark?.uuid)) {
			if lastSelectedBookmark != nil, lastSelectedBookmarkOpenedBlock != nil {
				lastSelectedBookmarkOpenedBlock?()
				lastSelectedBookmarkOpenedBlock = nil

				lastSelectedBookmark = nil
			}
		}
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if let bookmark = OCBookmarkManager.shared.bookmark(at: UInt(indexPath.row)) {
			if self.isLocked(bookmark: bookmark) {
				return
			}

			if tableView.isEditing {
				self.showBookmarkUI(edit: bookmark)
			} else {
				self.connect(to: bookmark)
			}
		}
	}

	// MARK: - Table view data source
	func indexPath(for bookmark: OCBookmark) -> IndexPath? {
		var index = 0

		for otherBookmark in OCBookmarkManager.shared.bookmarks {
			if bookmark.uuid == otherBookmark.uuid {
				return IndexPath(item: index, section: 0)
			}

			index += 1
		}

		return nil
	}

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return OCBookmarkManager.shared.bookmarks.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let bookmarkCell = self.tableView.dequeueReusableCell(withIdentifier: "bookmark-cell", for: indexPath) as? ServerListBookmarkCell else {
			return ServerListBookmarkCell()
		}

		if let bookmark : OCBookmark = OCBookmarkManager.shared.bookmark(at: UInt(indexPath.row)) {
			bookmarkCell.titleLabel.text = bookmark.shortName
			bookmarkCell.detailLabel.text = (bookmark.originURL != nil) ? bookmark.originURL!.absoluteString : bookmark.url?.absoluteString
			bookmarkCell.accessibilityIdentifier = "server-bookmark-cell"
		}

		return bookmarkCell
	}

	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

		let deleteRowAction = UITableViewRowAction(style: .destructive, title: "Delete".localized, handler: { (_, indexPath) in
			if let bookmark = OCBookmarkManager.shared.bookmark(at: UInt(indexPath.row)) {
				var presentationStyle: UIAlertController.Style = .actionSheet
				if UIDevice.current.isIpad() {
					presentationStyle = .alert
				}

				let alertController = UIAlertController(title: NSString(format: "Really delete '%@'?".localized as NSString, bookmark.shortName) as String,
														message: "This will also delete all locally stored file copies.".localized,
														preferredStyle: presentationStyle)

				alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))

				alertController.addAction(UIAlertAction(title: "Delete".localized, style: .destructive, handler: { (_) in

					self.lockedBookmarks.append(bookmark)

					OCCoreManager.shared.scheduleOfflineOperation({ (bookmark, completionHandler) in
						let vault : OCVault = OCVault(bookmark: bookmark)

						vault.erase(completionHandler: { (_, error) in
							OnMainThread {
								if error != nil {
									// Inform user if vault couldn't be erased
									let alertController = UIAlertController(title: NSString(format: "Deletion of '%@' failed".localized as NSString, bookmark.shortName as NSString) as String,
																			message: error?.localizedDescription,
																			preferredStyle: .alert)

									alertController.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: nil))

									self.present(alertController, animated: true, completion: nil)
								} else {
									// Success! We can now remove the bookmark
									self.ignoreServerListChanges = true

									OCBookmarkManager.shared.removeBookmark(bookmark)

									tableView.performBatchUpdates({
										tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.fade)
									}, completion: { (_) in
										self.ignoreServerListChanges = false
									})

									self.updateNoServerMessageVisibility()
								}

								if let removeIndex = self.lockedBookmarks.index(of: bookmark) {
									self.lockedBookmarks.remove(at: removeIndex)
								}

								completionHandler()
							}
						})
					}, for: bookmark)
				}))

				self.present(alertController, animated: true, completion: nil)
			}
		})

		let editRowAction = UITableViewRowAction(style: .normal, title: "Edit".localized, handler: { [weak self] (_, indexPath) in
			if let bookmark = OCBookmarkManager.shared.bookmark(at: UInt(indexPath.row)) {
				self?.showBookmarkUI(edit: bookmark)
			}
		})
		editRowAction.backgroundColor = .blue

		let manageRowAction = UITableViewRowAction(style: .normal,
												   title: "Manage".localized,
												   handler: { [weak self] (_, indexPath) in
			if let bookmark = OCBookmarkManager.shared.bookmark(at: UInt(indexPath.row)) {
				self?.showBookmarkInfoUI(bookmark)
			}
		})

		return [deleteRowAction, editRowAction, manageRowAction]
	}

	override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
		OCBookmarkManager.shared.moveBookmark(from: UInt(fromIndexPath.row), to: UInt(to.row))
	}
}

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
		shortcuts.append(addAccountCommand)
		shortcuts.append(openSettingsCommand)

		return shortcuts
	}

	override var canBecomeFirstResponder: Bool {
		return true
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
		if self.viewControllers.count > 1 {
			return [
				UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [.command], action: #selector(backCommand), discoverabilityTitle: "Back".localized)
			]
		}

		return []
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}

	@objc func backCommand() {
		_ = popViewController(animated: true)
	}
}

class TabBarShortcutController: UITabBarController {
	override var keyCommands: Array<UIKeyCommand>? {
		return self.tabBar.items?.enumerated().map { (index, item) -> UIKeyCommand in
			let tabIndex = String(index + 1)
			return UIKeyCommand(input: tabIndex, modifierFlags: .command, action:#selector(selectTab), discoverabilityTitle: item.title ?? "Tab \(tabIndex)")
		}
	}

	@objc func selectTab(sender: UIKeyCommand) {
		if let newIndex = Int(sender.input!), newIndex >= 1 && newIndex <= (self.tabBar.items?.count ?? 0) {
			self.selectedIndex = newIndex - 1;
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
		if let delegate = tableView.delegate, let tableView = tableView, let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
			delegate.tableView!(tableView, didSelectRowAt: indexPathForSelectedRow)
		}
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
		if let selectedIP = self.tableView?.indexPathForSelectedRow {
			if let row = sections[selectedIP.section].rows[selectedIP.row] as? StaticTableViewRow, row.type == .switchButton, let switchButon = row.cell?.accessoryView as? UISwitch {
				switchButon.tintColor = .white
			}

			if (selectedIP.row + 1) < sections[selectedIP.section].rows.count {
				self.tableView.selectRow(at: NSIndexPath(row: selectedIP.row + 1, section: selectedIP.section) as IndexPath, animated: true, scrollPosition: .middle)
			} else if (selectedIP.section + 1) < sections.count {
// New Section
				self.tableView.selectRow(at: NSIndexPath(row: 0, section: (selectedIP.section + 1)) as IndexPath, animated: true, scrollPosition: .middle)
			}
		} else {
			self.tableView.selectRow(at: NSIndexPath(row: 0, section: 0) as IndexPath, animated: true, scrollPosition: .top)
		}

		if let selectedIP = self.tableView?.indexPathForSelectedRow, let row = sections[selectedIP.section].rows[selectedIP.row] as? StaticTableViewRow, row.type == .switchButton, let switchButon = row.cell?.accessoryView as? UISwitch {
			switchButon.tintColor = Theme.shared.activeCollection.tableRowHighlightColors.backgroundColor
		}
	}

	@objc override func selectPrev(sender: UIKeyCommand) {
		if let selectedIP = self.tableView?.indexPathForSelectedRow {

			if let row = sections[selectedIP.section].rows[selectedIP.row] as? StaticTableViewRow, row.type == .switchButton, let switchButon = row.cell?.accessoryView as? UISwitch {
				switchButon.tintColor = .white
			}

			if selectedIP.row == 0, selectedIP.section > 0 {
				let sectionRows = sections[selectedIP.section - 1]
				self.tableView.selectRow(at: NSIndexPath(row: sectionRows.rows.count - 1, section: selectedIP.section - 1) as IndexPath, animated: true, scrollPosition: .middle)
			} else {
				self.tableView.selectRow(at: NSIndexPath(row: selectedIP.row - 1, section: selectedIP.section) as IndexPath, animated: true, scrollPosition: .middle)
			}

			if let indexPath = self.tableView?.indexPathForSelectedRow, let row = sections[indexPath.section].rows[indexPath.row] as? StaticTableViewRow, row.type == .switchButton, let switchButon = row.cell?.accessoryView as? UISwitch {
				switchButon.tintColor = Theme.shared.activeCollection.tableRowHighlightColors.backgroundColor
			}
		}
	}

	@objc override func selectCurrent(sender: UIKeyCommand) {
		if let indexPath = self.tableView?.indexPathForSelectedRow, let row = sections[indexPath.section].rows[indexPath.row] as? StaticTableViewRow, row.type == .switchButton, let switchButon = row.cell?.accessoryView as? UISwitch {
				if switchButon.isOn {
					switchButon.setOn(false, animated: true)
				} else {
					switchButon.setOn(true, animated: true)
				}

			let staticRow : StaticTableViewRow = staticRowForIndexPath(indexPath)

			if let action = staticRow.action {
				print("--> action \(action)")
				action(staticRow, self)
			}
		} else if let delegate = tableView.delegate, let tableView = tableView, let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
			delegate.tableView!(tableView, didSelectRowAt: indexPathForSelectedRow)
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
					let actionCommand = UIKeyCommand(input: keyCommand, modifierFlags: [.command], action: #selector(performExtensionAction), discoverabilityTitle: $0.actionExtension.name)
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
			let sortTitle = String(format: "%@ %@", "Sort by".localized, method.localizedName())
			let sortCommand = UIKeyCommand(input: String(index + 1), modifierFlags: [.command, .shift], action: #selector(changeSortMethod), discoverabilityTitle: sortTitle)
			shortcuts.append(sortCommand)
		}

		return shortcuts
	}

	@objc func performExtensionAction(_ command : UIKeyCommand) {
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

	@objc func enableSearch() {
		self.searchController?.isActive = true
		self.searchController?.searchBar.becomeFirstResponder()
	}

	@objc func toggleSortOrder() {
		self.sortBar?.sortMethod = self.sortMethod
	}

	@objc func changeSortMethod(_ command : UIKeyCommand) {
		for (_, method) in SortMethod.all.enumerated() {
			let sortTitle = String(format: "%@ %@", "Sort by".localized, method.localizedName())
			if command.discoverabilityTitle == sortTitle {
				self.sortBar?.sortMethod = method
				break
			}
		}
	}
}

extension DisplayViewController {
	override var keyCommands: [UIKeyCommand]? {
		return [
			UIKeyCommand(input: "M", modifierFlags: [.command], action: #selector(optionsBarButtonPressed), discoverabilityTitle: "More Menu".localized)
		]
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}
}

extension ClientDirectoryPickerViewController {
	override var keyCommands: [UIKeyCommand]? {
		var shortcuts = [UIKeyCommand]()
		if let superKeyCommands = super.keyCommands {
			shortcuts.append(contentsOf: superKeyCommands)
		}
		if let selectButtonTitle = selectBarButton?.title, let selector = selectBarButton?.action {
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

extension OCBookmarkManager {
	static private let lastConnectedBookmarkUUIDDefaultsKey = "last-connected-bookmark-uuid"

	// MARK: - Defaults Keys
	static var lastBookmarkSelectedForConnection : OCBookmark? {
		get {
			if let bookmarkUUIDString = OCAppIdentity.shared.userDefaults?.string(forKey: OCBookmarkManager.lastConnectedBookmarkUUIDDefaultsKey), let bookmarkUUID = UUID(uuidString: bookmarkUUIDString) {
				return OCBookmarkManager.shared.bookmark(for: bookmarkUUID)
			}

			return nil
		}

		set {
			OCAppIdentity.shared.userDefaults?.set(newValue?.uuid.uuidString, forKey: OCBookmarkManager.lastConnectedBookmarkUUIDDefaultsKey)
		}
	}
}
