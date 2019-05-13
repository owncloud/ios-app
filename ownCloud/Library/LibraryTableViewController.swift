//
//  LibraryTableViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 12.05.19.
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

class LibraryTableViewController: StaticTableViewController {

	var core : OCCore?

	override func viewDidLoad() {
		super.viewDidLoad()

		self.title = "Library".localized
		self.navigationController?.navigationBar.prefersLargeTitles = true
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.navigationBar.prefersLargeTitles = true
	}

	func updateLibrary() {
		let shareQueryWithUser = OCShareQuery(scope: .sharedWithUser, item: nil)
		let shareQueryByUser = OCShareQuery(scope: .sharedByUser, item: nil)

		core?.start(shareQueryWithUser!)
		shareQueryWithUser?.initialPopulationHandler = { query in
			self.handleSharedWithUser(shares: query.queryResults)
		}
		shareQueryWithUser?.changesAvailableNotificationHandler = { query in
			self.handleSharedWithUser(shares: query.queryResults)
		}

		core?.start(shareQueryByUser!)
		shareQueryByUser?.initialPopulationHandler = { query in
			self.handleSharedByUser(shares: query.queryResults)
		}
		shareQueryByUser?.changesAvailableNotificationHandler = { query in
			self.handleSharedByUser(shares: query.queryResults)
		}
	}

	func handleSharedWithUser(shares: [OCShare]) {
		let sharedWithUserPending = shares.filter({ (share) -> Bool in
			if share.state == .pending {
				return true
			}
			return false
		})

		let sharedWithUserAccepted = shares.filter({ (share) -> Bool in
			if share.state == .accepted {
				return true
			}
			return false
		})

		OnMainThread {
			self.updatePendingShareRow(sharedWithUser: sharedWithUserPending)
			self.updateGenericShareRow(shares: sharedWithUserAccepted, title: "Shared with you".localized, image: UIImage(named: "shared")!)
		}
	}

	func handleSharedByUser(shares: [OCShare]) {
		let sharedByUserLinks = shares.filter({ (share) -> Bool in
			if share.type == .link {
				return true
			}
			return false
		})

		let sharedByUser = shares.filter({ (share) -> Bool in
			if share.type != .link {
				return true
			}
			return false
		})

		OnMainThread {
			self.updateGenericShareRow(shares: sharedByUser, title: "Shared with others".localized, image: UIImage(named: "shared")!)
			self.updateGenericShareRow(shares: sharedByUserLinks, title: "Public Links".localized, image: UIImage(named: "link")!)
		}
	}

	// MARK: Sharing Section

	func addShareSection() {
		if self.sectionForIdentifier("share-section") == nil {
			let section = StaticTableViewSection(headerTitle: "Shares".localized, footerTitle: nil, identifier: "share-section")
			self.insertSection(section, at: 0, animated: false)
		}
	}

	func updatePendingShareRow(sharedWithUser: [OCShare]) {
		self.addShareSection()
		let section = self.sectionForIdentifier("share-section")
		if sharedWithUser.count > 0 {
			let shareCounter = String(sharedWithUser.count)
			self.navigationController?.tabBarItem.badgeValue = shareCounter

			if section?.row(withIdentifier: "pending-share-row") == nil {
				let pendingLabel = RoundedLabel()
				pendingLabel.update(text: shareCounter, textColor: UIColor.white, backgroundColor: UIColor.red)

				let row = StaticTableViewRow(rowWithAction: { (_, _) in
					let pendingSharesController = PendingSharesTableViewController()
					pendingSharesController.shares = sharedWithUser
					pendingSharesController.core = self.core
					self.navigationController?.pushViewController(pendingSharesController, animated: true)
				}, title: "Pending Shares".localized, image: UIImage(named: "group"), accessoryType: .disclosureIndicator, accessoryView: pendingLabel, identifier: "pending-share-row")
				section?.insert(row: row, at: 0, animated: true)
			} else if let row = section?.row(withIdentifier: "pending-share-row") {
				OnMainThread {
					guard let accessoryView = row.additionalAccessoryView as? RoundedLabel else { return }
					accessoryView.update(text: shareCounter, textColor: UIColor.white, backgroundColor: UIColor.red)
				}
			}
		} else {
			if let row = section?.row(withIdentifier: "pending-share-row") {
				section?.remove(rows: [row], animated: true)
			}
			self.navigationController?.tabBarItem.badgeValue = nil
		}
	}

	func updateGenericShareRow(shares: [OCShare], title: String, image: UIImage) {
		let section = self.sectionForIdentifier("share-section")
		let rowIdentifier = String(format:"share-%@row", title)
		if shares.count > 0 {
			if self.sectionForIdentifier("share-section") == nil {
				self.addShareSection()
			}

			if section?.row(withIdentifier: rowIdentifier) == nil, let core = core {
				let row = StaticTableViewRow(rowWithAction: { (_, _) in

					let sharesFileListController = SharesFilelistTableViewController(core: core)
					sharesFileListController.shares = shares
					sharesFileListController.title = title
					self.navigationController?.pushViewController(sharesFileListController, animated: true)

				}, title: title, image: image, accessoryType: .disclosureIndicator, identifier: rowIdentifier)
				section?.add(row: row)
			}
		} else {
			if let row = section?.row(withIdentifier: rowIdentifier) {
				section?.remove(rows: [row], animated: true)
			}
		}
	}

}
