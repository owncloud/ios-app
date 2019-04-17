//
//  SharingTableViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 10.04.19.
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

class SharingTableViewController: StaticTableViewController {

	var shares : [OCShare] = []
	var core : OCCore?
	var item : OCItem?
	var searchController : UISearchController?

	override func viewDidLoad() {
		super.viewDidLoad()

		let resultsController = SharingSearchResultsTableViewController(style: .grouped)
		searchController = UISearchController(searchResultsController: resultsController)
		searchController?.searchResultsUpdater = resultsController
		searchController?.obscuresBackgroundDuringPresentation = true
		searchController?.hidesNavigationBarDuringPresentation = true
		searchController?.searchBar.placeholder = "Search User, Group, Remote"
		navigationItem.hidesSearchBarWhenScrolling = false
		navigationItem.searchController = searchController

		self.navigationItem.title = "Sharing".localized
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissAnimated))

		addSectionFor(type: .userShare, with: "Users".localized)
		addSectionFor(type: .groupShare, with: "Groups".localized)
		addSectionFor(type: .remote, with: "Remote Users".localized)
	}

	func addSectionFor(type: OCShareType, with title: String) {
		var shareRows: [StaticTableViewRow] = []

		let user = shares.filter { (OCShare) -> Bool in
			if OCShare.type == type {
				return true
			}
			return false
		}

		if user.count > 0 {
			for share in user {
				let resharedUsers = shares.filter { (OCShare) -> Bool in
					if OCShare.owner == share.recipient?.user {
						return true
					}
					return false
				}

				var canEdit = false
				var accessoryType : UITableViewCell.AccessoryType = .none
				if core?.connection.loggedInUser == share.owner {
					canEdit = true
					accessoryType = .disclosureIndicator
				}

				print("--> edit share \(share)")

				shareRows.append( StaticTableViewRow(rowWithAction: { (row, _) in

					if canEdit {
						let editSharingViewController = SharingEditUserGroupsTableViewController(style: .grouped)
						editSharingViewController.share = share
						editSharingViewController.reshares = resharedUsers
						editSharingViewController.core = self.core
						self.navigationController?.pushViewController(editSharingViewController, animated: true)
					} else {
						row.cell?.selectionStyle = .none
					}
				}, title: share.recipient!.displayName!, subtitle: share.permissionDescription(), accessoryType: accessoryType) )
			}

			let section : StaticTableViewSection = StaticTableViewSection(headerTitle: title, footerTitle: nil, rows: shareRows)
			self.addSection(section)
		}
	}
}
