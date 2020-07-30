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
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if VendorServices.shared.canAddAccount {
			let addServerBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addAccount))
			addServerBarButtonItem.accessibilityLabel = "Add account".localized
			addServerBarButtonItem.accessibilityIdentifier = "addAccount"
			var items = self.staticLoginViewController?.toolbarItems
			items?.insert(addServerBarButtonItem, at: 0)
			self.staticLoginViewController?.toolbarItems = items
		}
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		var items = self.staticLoginViewController?.toolbarItems
		if items?.count ?? 0 > 0, items?.first?.accessibilityIdentifier == "addAccount" {
			items?.remove(at: 0)
			self.staticLoginViewController?.toolbarItems = items
		}
		self.staticLoginViewController?.toolbarItems = items
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let bookmarkCell = self.tableView.dequeueReusableCell(withIdentifier: "bookmark-cell", for: indexPath) as? ServerListBookmarkCell else {
			return ServerListBookmarkCell()
		}

		if let bookmark : OCBookmark = OCBookmarkManager.shared.bookmark(at: UInt(indexPath.row)) {
			bookmarkCell.titleLabel.text =  bookmark.shortName
			bookmarkCell.detailLabel.text = bookmark.displayName ?? bookmark.userName
			bookmarkCell.accessibilityIdentifier = "server-bookmark-cell"
		}

		return bookmarkCell
	}

	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		if headerView == nil {
			headerView = StaticTableViewSection.buildHeader(title: "Accounts".localized)
		}

		return headerView
	}

	@objc func addAccount() {
		if staticLoginViewController?.loginBundle.profiles.count == 1, let profile = staticLoginViewController?.loginBundle.profiles.first {
			if let setupViewController = staticLoginViewController?.buildSetupViewController(for: profile) {
				self.navigationController?.pushViewController(setupViewController, animated: true)
			}
		} else if let viewController = staticLoginViewController?.buildProfileSetupSelector(title: "Add account".localized, includeCancelOption: true) {
			self.navigationController?.pushViewController(viewController, animated: false)
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

	override func updateNoServerMessageVisibility() {
		if OCBookmarkManager.shared.bookmarks.count == 0 {
			self.staticLoginViewController?.showFirstScreen()
		}
	}
}
