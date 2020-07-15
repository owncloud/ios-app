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

class StaticLoginSingleAccountServerListViewController: ServerListTableViewController {
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
	}

	// Implementation
	var headerView : UIView?
	weak var staticLoginViewController : StaticLoginViewController?

	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.isScrollEnabled = true
		self.tableView.register(ThemeTableViewCell.self, forCellReuseIdentifier: "login-cell")
		self.tableView.register(ServerListToolCell.self, forCellReuseIdentifier: "tool-cell")
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		staticLoginViewController?.toolbarShown = false
	}

	override func numberOfSections(in tableView: UITableView) -> Int {
		return SingleAccountSection.allCases.count
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch SingleAccountSection(rawValue: section) {
			case .accessFiles: return AccessFilesRowIndex.allCases.count
			case .actions: 	   return ActionRowIndex.allCases.count
			case .settings:    return SettingsRowIndex.allCases.count

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
				bookmarkCell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
				bookmarkCell.layer.cornerRadius = 8
				bookmarkCell.layer.masksToBounds = true
				if #available(iOS 13.0, *) {
					bookmarkCell.imageView?.image = UIImage(systemName: "folder")
				} else {
					bookmarkCell.imageView?.image = UIImage(named: "folder")?.scaledImageFitting(in: CGSize(width: 28, height: 28))
				}

				rowCell = bookmarkCell

			case .actions:
				guard let bookmarkCell = self.tableView.dequeueReusableCell(withIdentifier: "tool-cell", for: indexPath) as? ServerListToolCell else {
					return ServerListToolCell()
				}

				switch ActionRowIndex(rawValue: indexPath.row) {
					case .editLogin:
						bookmarkCell.textLabel?.text = "Edit Login".localized

						bookmarkCell.clipsToBounds = true
						bookmarkCell.layer.cornerRadius = 8
						bookmarkCell.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]

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
						bookmarkCell.textLabel?.text = "Logout".localized

						bookmarkCell.clipsToBounds = true
						bookmarkCell.layer.cornerRadius = 8
						bookmarkCell.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]

						if #available(iOS 13.0, *) {
							bookmarkCell.imageView?.image = UIImage(systemName: "power")
						} else {
							bookmarkCell.imageView?.image = UIImage(named: "power")?.scaledImageFitting(in: CGSize(width: 28, height: 28))
						}

					default:
						bookmarkCell.textLabel?.text = ""
				}

				rowCell = bookmarkCell

			case .settings:
				guard let bookmarkCell = self.tableView.dequeueReusableCell(withIdentifier: "tool-cell", for: indexPath) as? ServerListToolCell else {
					return ServerListToolCell()
				}

				bookmarkCell.textLabel?.text = "Settings".localized
				bookmarkCell.layer.cornerRadius = 8
				bookmarkCell.layer.masksToBounds = true
				if #available(iOS 13.0, *) {
					bookmarkCell.imageView?.image = UIImage(systemName: "gear")
				} else {
					bookmarkCell.imageView?.image = UIImage(named: "gear")?.scaledImageFitting(in: CGSize(width: 28, height: 28))
				}

				rowCell = bookmarkCell

			default:
				rowCell = ServerListToolCell()
		}

		return rowCell
	}

	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		if SingleAccountSection(rawValue: section) == .accessFiles {
			if headerView == nil, let bookmark : OCBookmark = OCBookmarkManager.shared.bookmarks.first, let userName = bookmark.userName {
				let headerText = String(format: "You are connected as\n%@ to %@".localized, userName, bookmark.shortName)
				headerView = StaticTableViewSection.buildHeader(title: headerText)
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
					switch ActionRowIndex(rawValue: indexPath.row) {
						case .editLogin:
							showBookmarkUI(edit: bookmark)

						case .manageStorage:
							showBookmarkInfoUI(bookmark)

						case .logout:
							delete(bookmark: bookmark, at: IndexPath(row: 0, section: 0) ) {
								self.staticLoginViewController?.showFirstScreen()
							}

						default: break
					}
				}

			case .settings:
				tableView.deselectRow(at: indexPath, animated: true)
				settings()

			default: break
		}
	}

	@available(iOS 13.0, *)
	override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		return nil
	}

	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		return nil
	}

	override func didUpdateServerList() {
		if OCBookmarkManager.shared.bookmarks.count == 0 {
			self.staticLoginViewController?.showFirstScreen()
		}
	}

	override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		super.applyThemeCollection(theme: theme, collection: collection, event: event)
		self.tableView.backgroundColor = .clear
	}

	override func showModal(viewController: UIViewController, completion: (() -> Void)? = nil) {
		// Ensure the presenting view controller isn't removed when the presentation ends
 		if viewController.modalPresentationStyle == .fullScreen {
 			viewController.modalPresentationStyle = .overFullScreen
 		}

  		self.staticLoginViewController?.present(viewController, animated: true, completion: completion)
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
}
