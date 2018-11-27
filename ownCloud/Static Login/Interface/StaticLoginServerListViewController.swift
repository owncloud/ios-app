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

class StaticLoginServerListViewController: ServerListTableViewController {
	var headerView : UIView?
	weak var staticLoginViewController : StaticLoginViewController?

	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.register(ThemeTableViewCell.self, forCellReuseIdentifier: "login-cell")
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		staticLoginViewController?.toolbarShown = true
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		staticLoginViewController?.toolbarShown = false
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return super.tableView(tableView, numberOfRowsInSection: section) + 1
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let bookmarkCell = self.tableView.dequeueReusableCell(withIdentifier: "login-cell", for: indexPath) as? ThemeTableViewCell else {
			return ThemeTableViewCell()
		}

		if indexPath.row < OCBookmarkManager.shared.bookmarks.count {
			if let bookmark : OCBookmark = OCBookmarkManager.shared.bookmark(at: UInt(indexPath.row)) {
				bookmarkCell.textLabel?.text = bookmark.shortName
			}
		} else {
			bookmarkCell.textLabel?.text = "Add account"
			bookmarkCell.accessoryType = .disclosureIndicator
		}

		return bookmarkCell
	}

	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		if headerView == nil {
			headerView = StaticTableViewSection.buildHeader(title: "Accounts")
		}

		return headerView
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.row < OCBookmarkManager.shared.bookmarks.count {
			super.tableView(tableView, didSelectRowAt: indexPath)
		} else {
			if let viewController = staticLoginViewController?.buildProfileSetupSelector(title: "Add account", includeCancelOption: true) {
				self.navigationController?.pushViewController(viewController, animated: true)
			}
		}
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

	override func showModal(viewController: UIViewController) {
		staticLoginViewController?.present(viewController, animated: true, completion: nil)
	}

	override func openBookmark(_ bookmark: OCBookmark, closeHandler: (() -> Void)? = nil) {
		self.staticLoginViewController?.openBookmark(bookmark, closeHandler: closeHandler)
	}
}
