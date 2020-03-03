//
//  StaticLoginServerListViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 27.11.18.
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

class StaticLoginSingleAccountServerListViewController: ServerListTableViewController {
	var headerView : UIView?
	weak var staticLoginViewController : StaticLoginViewController?

	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.isScrollEnabled = true
		self.tableView.register(ThemeTableViewCell.self, forCellReuseIdentifier: "login-cell")
		self.tableView.register(ServerListToolCell.self, forCellReuseIdentifier: "tool-cell")
	}

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 3
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

		if section == 0 {
			return 1
		} else if section == 1 {
			return 3
		}

		return 1
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		if indexPath.section == 0 {
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

			return bookmarkCell
		}

		guard let bookmarkCell = self.tableView.dequeueReusableCell(withIdentifier: "tool-cell", for: indexPath) as? ServerListToolCell else {
			return ServerListToolCell()
		}

		if indexPath.section == 1 {
			switch indexPath.row {
			case 0:
				bookmarkCell.textLabel?.text = "Edit Login".localized

				bookmarkCell.clipsToBounds = true
				bookmarkCell.layer.cornerRadius = 8
				bookmarkCell.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]

				if #available(iOS 13.0, *) {
					bookmarkCell.imageView?.image = UIImage(systemName: "square.and.pencil")
				} else {
					bookmarkCell.imageView?.image = UIImage(named: "square.and.pencil")?.scaledImageFitting(in: CGSize(width: 28, height: 28))
				}
			case 1:
				bookmarkCell.textLabel?.text = "Manage Storage".localized

				if #available(iOS 13.0, *) {
					bookmarkCell.imageView?.image = UIImage(systemName: "arrow.3.trianglepath")
				} else {
					bookmarkCell.imageView?.image = UIImage(named: "arrow.3.trianglepath")?.scaledImageFitting(in: CGSize(width: 28, height: 28))
				}
			case 2:
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
		} else {
			bookmarkCell.textLabel?.text = "Settings".localized
			bookmarkCell.layer.cornerRadius = 8
			bookmarkCell.layer.masksToBounds = true
			if #available(iOS 13.0, *) {
				bookmarkCell.imageView?.image = UIImage(systemName: "gear")
			} else {
				bookmarkCell.imageView?.image = UIImage(named: "gear")?.scaledImageFitting(in: CGSize(width: 28, height: 28))
			}
		}

		return bookmarkCell
	}

	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		if section == 0 {
			if headerView == nil, let bookmark : OCBookmark = OCBookmarkManager.shared.bookmarks.first, let userName = bookmark.userName {
				let headerText = String(format: "You are connected as\n%@ to %@".localized, userName, bookmark.shortName)
				headerView = StaticTableViewSection.buildHeader(title: headerText)
			}

			return headerView
		}

		return nil
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 0 {
			super.tableView(tableView, didSelectRowAt: indexPath)
		} else if indexPath.section == 1, let bookmark : OCBookmark = OCBookmarkManager.shared.bookmarks.first {
			tableView.deselectRow(at: indexPath, animated: true)
			switch indexPath.row {
			case 0:
				showBookmarkUI(edit: bookmark)
			case 1:
				showBookmarkInfoUI(bookmark)
			case 2:
				deleteBookmark(bookmark) { (_) in
					self.staticLoginViewController?.showFirstScreen()
				}
			default:
				break
			}
		} else {
			tableView.deselectRow(at: indexPath, animated: true)
			settings()
		}
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

	override func openBookmark(_ bookmark: OCBookmark, closeHandler: (() -> Void)? = nil) {
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
