//
//  StaticLoginSingleAccountServerListViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 03.03.2020.
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
import CoreMedia

class StaticLoginSingleAccountServerListViewController: ServerListTableViewController, CustomStatusBarViewControllerProtocol {
	// Sections in the table view controller
	private enum SingleAccountSection : Int, CaseIterable {
		case accessFiles
		case actions
		case settings
	}

	// Rows by section
	private enum AccessFilesRowIndex : Int, CaseIterable {
		case accessFiles
	}

	private enum ActionRowIndex : Int, CaseIterable {
		case editLogin
		case manageStorage
		case logout
	}

	private enum SettingsRowIndex : Int, CaseIterable {
		case settings
		case addAccount
	}

	// Implementation
	var headerView : UIView?
	weak var staticLoginViewController : StaticLoginViewController?
	var canConfigureURL: Bool = true
	private var actionRows: [ActionRowIndex] = [.editLogin, .manageStorage, .logout]
	var displayName: String?

	private var settingsRows: [SettingsRowIndex] = [.settings]

	private var bookmarkChangesObserver : NSObjectProtocol?

	var themeApplierToken : ThemeApplierToken?

	deinit {
		Theme.shared.unregister(client: self)

		if themeApplierToken != nil {
			Theme.shared.remove(applierForToken: themeApplierToken)
			themeApplierToken = nil
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		Theme.shared.register(client: self, applyImmediately: true)

		self.tableView.isScrollEnabled = true
		self.tableView.register(ThemeTableViewCell.self, forCellReuseIdentifier: "login-cell")
		self.tableView.register(ServerListToolCell.self, forCellReuseIdentifier: "tool-cell")

		if !VendorServices.shared.canEditAccount {
			actionRows = [.manageStorage, .logout]
		}

		if VendorServices.shared.canAddAccount {
			staticLoginViewController?.toolbarShown = true
			settingsRows = [.settings, .addAccount]
		} else {
			staticLoginViewController?.toolbarShown = false
		}

		if !VendorServices.shared.isBranded {
			hasToolbar = false
			self.navigationItem.rightBarButtonItem = nil
		}

		retrieveDisplayName()

		bookmarkChangesObserver = NotificationCenter.default.addObserver(forName: .OCBookmarkManagerListChanged, object: nil, queue: OperationQueue.main) { [weak self] (_) in
			self?.retrieveDisplayName()
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		updateTableViewMargins(for: self.view.frame.size)
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)

		updateTableViewMargins(for: size)
	}

	func updateTableViewMargins(for size: CGSize) {
		if !VendorServices.shared.isBranded, UIDevice.current.isIpad {
			// Set a maximum table view width of 400 on iPad
			let width = size.width
			var margin : CGFloat = 0
			let tableViewWidth : CGFloat = 400

			margin = (width - tableViewWidth) / 2

			self.tableView.layoutMargins.left = margin
			self.tableView.layoutMargins.right = margin
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		staticLoginViewController?.navigationController?.setNeedsStatusBarAppearanceUpdate()
	}

	func statusBarStyle() -> UIStatusBarStyle {
		return Theme.shared.activeCollection.loginStatusBarStyle
	}

	override func numberOfSections(in tableView: UITableView) -> Int {
		return SingleAccountSection.allCases.count
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch SingleAccountSection(rawValue: section) {
			case .accessFiles: return AccessFilesRowIndex.allCases.count
			case .actions: 	   return actionRows.count
			case .settings:    return settingsRows.count

			default: 	   return 0
		}
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let section = SingleAccountSection(rawValue: indexPath.section)
		var rowCell : UITableViewCell

		switch section {
		case .accessFiles:
			guard let bookmarkCell = self.tableView.dequeueReusableCell(withIdentifier: "login-cell", for: indexPath) as? ThemeTableViewCell else {
				return ThemeTableViewCell()
			}

			bookmarkCell.textLabel?.text = "Access Files".localized
                        bookmarkCell.accessibilityIdentifier = "access-files"
			bookmarkCell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
			if #available(iOS 13.0, *) {
				bookmarkCell.imageView?.image = UIImage(systemName: "folder")
			} else {
				bookmarkCell.imageView?.image = UIImage(named: "folder")?.scaledImageFitting(in: CGSize(width: 28, height: 28))
			}

			themeApplierToken = Theme.shared.add(applier: { (_, themeCollection, _) in
				bookmarkCell.imageView?.tintColor = themeCollection.tableRowColors.labelColor
			})

			rowCell = bookmarkCell

		case .actions:
			guard let bookmarkCell = self.tableView.dequeueReusableCell(withIdentifier: "tool-cell", for: indexPath) as? ServerListToolCell else {
				   return ServerListToolCell()
			   }

			   switch actionRows[indexPath.row] {
				   case .editLogin:
					   bookmarkCell.textLabel?.text = "Edit Login".localized

					   if #available(iOS 13.0, *) {
						   bookmarkCell.imageView?.image = UIImage(systemName: "square.and.pencil")
					   } else {
						   bookmarkCell.imageView?.image = UIImage(named: "square.and.pencil")?.scaledImageFitting(in: CGSize(width: 28, height: 28))
					   }

				   case .manageStorage:
					   bookmarkCell.textLabel?.text = "Manage Storage".localized

					   if #available(iOS 13.0, *) {
						   bookmarkCell.imageView?.image = UIImage(systemName: "arrow.3.trianglepath")
					   } else {
						   bookmarkCell.imageView?.image = UIImage(named: "arrow.3.trianglepath")?.scaledImageFitting(in: CGSize(width: 28, height: 28))
					   }

				   case .logout:
					   bookmarkCell.textLabel?.text = "Log out".localized

					   if #available(iOS 13.0, *) {
						   bookmarkCell.imageView?.image = UIImage(systemName: "power")
					   } else {
						   bookmarkCell.imageView?.image = UIImage(named: "power")?.scaledImageFitting(in: CGSize(width: 28, height: 28))
					   }
			   }

			   rowCell = bookmarkCell

		case .settings:

			guard let bookmarkCell = self.tableView.dequeueReusableCell(withIdentifier: "tool-cell", for: indexPath) as? ServerListToolCell else {
				return ServerListToolCell()
			}

			switch settingsRows[indexPath.row] {

			case .settings:

				bookmarkCell.textLabel?.text = "Settings".localized
				if #available(iOS 13.0, *) {
					bookmarkCell.imageView?.image = UIImage(systemName: "gear")
				} else {
					bookmarkCell.imageView?.image = UIImage(named: "gear")?.scaledImageFitting(in: CGSize(width: 28, height: 28))
				}

			case .addAccount:
				bookmarkCell.textLabel?.text = "Add Account".localized
				if #available(iOS 13.0, *) {
					bookmarkCell.imageView?.image = UIImage(systemName: "plus")
				} else {
					bookmarkCell.imageView?.image = UIImage(named: "round-add-button")?.scaledImageFitting(in: CGSize(width: 28, height: 28))
				}

			}

			rowCell = bookmarkCell

		default:
			rowCell = ServerListToolCell()
		}

		return rowCell
	}

	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if VendorServices.shared.isBranded {
			var borderColor = Theme.shared.activeCollection.navigationBarColors.backgroundColor
			if borderColor == UIColor(hex: 0xFFFFFF) {
				borderColor = Theme.shared.activeCollection.navigationBarColors.tintColor
			}

			self.colorSection(tableView, willDisplay: cell, forRowAt: indexPath, borderColor: borderColor)
		}
	}

	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		if SingleAccountSection(rawValue: section) == .accessFiles {
			if headerView == nil, let bookmark : OCBookmark = OCBookmarkManager.shared.bookmarks.first, let displayName = self.displayName ?? bookmark.userName {
				let headerText = String(format: "You are connected as\n%@".localized, displayName)
				if VendorServices.shared.isBranded {
					headerView = StaticTableViewSection.buildHeader(title: headerText)
				} else {
					headerView = StaticTableViewSection.buildHeader(title: headerText, image: UIImage(named: "branding-login-logo"), topSpacing: 10)
				}
			}

			return headerView
		}

		return nil
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		switch SingleAccountSection(rawValue: indexPath.section) {
			case .accessFiles:
				super.tableView(tableView, didSelectRowAt: indexPath)

			case .actions:
				if let bookmark : OCBookmark = OCBookmarkManager.shared.bookmarks.first {
					tableView.deselectRow(at: indexPath, animated: true)
					switch actionRows[indexPath.row] {
						case .editLogin:
						showBookmarkUI(edit: bookmark, removeAuthDataFromCopy: false)

						case .manageStorage:
							showBookmarkInfoUI(bookmark)

						case .logout:
							delete(bookmark: bookmark, at: IndexPath(row: 0, section: 0) ) {
								self.didUpdateServerList()
							}
					}
				}

			case .settings:
				tableView.deselectRow(at: indexPath, animated: true)
				switch settingsRows[indexPath.row] {
					case .settings:
						settings()
					case .addAccount:
						addAccount()
				}

			default: break
		}
	}

	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		return nil
	}

	override func didUpdateServerList() {
		if VendorServices.shared.isBranded {
			if OCBookmarkManager.shared.bookmarks.count == 0 {
				self.staticLoginViewController?.showFirstScreen()
			}
		} else {
			if OCBookmarkManager.shared.bookmarks.count != 1 {
				let serverListTableViewController = ServerListTableViewController(style: .plain)
				self.navigationController?.setViewControllers([serverListTableViewController], animated: false)
			}
		}
	}

	override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		super.applyThemeCollection(theme: theme, collection: collection, event: event)
		if VendorServices.shared.isBranded {
			self.tableView.backgroundColor = .clear
		} else {
			self.tableView.backgroundColor = collection.navigationBarColors.backgroundColor
		}
	}

	override func showModal(viewController: UIViewController, completion: (() -> Void)? = nil) {
		if let staticLoginViewController = self.staticLoginViewController {
			// Ensure the presenting view controller isn't removed when the presentation ends
			if viewController.modalPresentationStyle == .fullScreen {
				viewController.modalPresentationStyle = .overFullScreen
			}

			staticLoginViewController.present(viewController, animated: true, completion: completion)
		} else {
			super.showModal(viewController: viewController, completion: completion)
		}
	}

	func openBookmark(_ bookmark: OCBookmark, closeHandler: (() -> Void)? = nil) {
		self.staticLoginViewController?.openBookmark(bookmark, closeHandler: closeHandler)
	}

	@IBAction override func settings() {
		let viewController : SettingsViewController = SettingsViewController(style: .grouped)
		let navigationController : ThemeNavigationController = ThemeNavigationController(rootViewController: viewController)

		// Prevent any in-progress connection from being shown
		resetPreviousBookmarkSelection()

		self.showModal(viewController: navigationController)
	}

	@objc func addAccount() {
		if VendorServices.shared.isBranded {
			if staticLoginViewController?.loginBundle.profiles.count == 1, let profile = staticLoginViewController?.loginBundle.profiles.first {
				if let setupViewController = staticLoginViewController?.buildSetupViewController(for: profile) {
					self.navigationController?.pushViewController(setupViewController, animated: true)
				}
			} else if let viewController = staticLoginViewController?.buildProfileSetupSelector(title: "Add account".localized, includeCancelOption: true) {
				self.navigationController?.pushViewController(viewController, animated: false)
			}
		} else {
			super.addBookmark()
		}
	}
}

extension StaticLoginSingleAccountServerListViewController {

	func retrieveDisplayName() {
		if let userDisplayName = OCBookmarkManager.shared.bookmarks.first?.displayName {
			if self.displayName != userDisplayName {
				OnMainThread {
					self.displayName = userDisplayName
					self.headerView = nil

					self.tableView.reloadData()
				}
			}
		}
	}
}

extension StaticLoginSingleAccountServerListViewController {

	override func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
		if indexPath.section == 0, indexPath.row == 0 {
			return super.tableView(tableView, itemsForBeginning: session, at: indexPath)
		}

		return []
	}

	@available(iOS 13.0, *)
	override func tableView(_ tableView: UITableView,
	contextMenuConfigurationForRowAt indexPath: IndexPath,
	point: CGPoint) -> UIContextMenuConfiguration? {
		if indexPath.section == 0, indexPath.row == 0 {
			return super.tableView(tableView, contextMenuConfigurationForRowAt: indexPath, point: point)
		}

		return nil
	}

}
