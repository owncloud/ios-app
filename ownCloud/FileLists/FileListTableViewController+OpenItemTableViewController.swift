//
//  FileListTableViewController+OpenItemTableViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 17.07.20.
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

extension FileListTableViewController : OpenItemHandling {
	@discardableResult public func open(item: OCItem, animated: Bool, pushViewController: Bool) -> UIViewController? {
		if let core = self.core {
			if #available(iOS 13.0, *) {
				if  let tabBarController = self.tabBarController as? ClientRootViewController {
					let activity = OpenItemUserActivity(detailItem: item, detailBookmark: tabBarController.bookmark)
					view.window?.windowScene?.userActivity = activity.openItemUserActivity
				}
			}

			switch item.type {
				case .collection:
					if let path = item.path {
						let clientQueryViewController = ClientQueryViewController(core: core, query: OCQuery(forPath: path))
						if pushViewController {
							self.navigationController?.pushViewController(clientQueryViewController, animated: animated)
						}

						return clientQueryViewController
					}

				case .file:
					guard let query = self.query(forItem: item) else {
						return nil
					}

					let itemViewController = DisplayHostViewController(core: core, selectedItem: item, query: query)
					itemViewController.hidesBottomBarWhenPushed = true
					itemViewController.progressSummarizer = self.progressSummarizer
					self.navigationController?.pushViewController(itemViewController, animated: animated)
			}
		}

		return nil
	}
}

extension FileListTableViewController : MoreItemHandling {
	public func moreOptions(for item: OCItem, core: OCCore, query: OCQuery?, sender: AnyObject?) -> Bool {
		guard let sender = sender else {
			return false
		}
		let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .moreItem)
		let actionContext = ActionContext(viewController: self, core: core, query: query, items: [item], location: actionsLocation, sender: sender)

		if let moreViewController = Action.cardViewController(for: item, with: actionContext, progressHandler: makeActionProgressHandler(), completionHandler: nil) {
			self.present(asCard: moreViewController, animated: true)
		}

		return true
	}
}
