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
	var pendingSharesCounter : Int = 0 {
		didSet {
			OnMainThread {
				if self.pendingSharesCounter > 0 {
					self.navigationController?.tabBarItem.badgeValue = String(self.pendingSharesCounter)
				} else {
					self.navigationController?.tabBarItem.badgeValue = nil
				}
			}
		}
	}
	var pendingLocalSharesCounter : Int = 0 {
		didSet {
			pendingSharesCounter = pendingCloudSharesCounter + pendingLocalSharesCounter
		}
	}
	var pendingCloudSharesCounter : Int = 0 {
		didSet {
			pendingSharesCounter = pendingCloudSharesCounter + pendingLocalSharesCounter
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.title = "Quick Access".localized
		self.navigationController?.navigationBar.prefersLargeTitles = true
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.navigationBar.prefersLargeTitles = true
	}

	func updateLibrary() {
		let shareQueryWithUser = OCShareQuery(scope: .sharedWithUser, item: nil)
		let shareQueryByUser = OCShareQuery(scope: .sharedByUser, item: nil)
		let shareQueryCloudShares = OCShareQuery(scope: .pendingCloudShares, item: nil)

		core?.start(shareQueryWithUser!)
		shareQueryWithUser?.initialPopulationHandler = { query in
			self.handleSharedWithUser(shares: query.queryResults)
		}
		shareQueryWithUser?.changesAvailableNotificationHandler = { query in
			self.handleSharedWithUser(shares: query.queryResults)
		}

		core?.start(shareQueryCloudShares!)
		shareQueryCloudShares?.initialPopulationHandler = { query in
			self.pendingCloudSharesCounter = query.queryResults.count
			self.updatePendingShareRow(shares: query.queryResults, title: "Pending Cloud Shares".localized)
		}
		shareQueryCloudShares?.changesAvailableNotificationHandler = { query in
			self.pendingCloudSharesCounter = query.queryResults.count
			self.updatePendingShareRow(shares: query.queryResults, title: "Pending Cloud Shares".localized)
		}

		core?.start(shareQueryByUser!)
		shareQueryByUser?.initialPopulationHandler = { query in
			self.handleSharedByUser(shares: query.queryResults)
		}
		shareQueryByUser?.changesAvailableNotificationHandler = { query in
			self.handleSharedByUser(shares: query.queryResults)
		}
		addCollectionSection()
	}

	func handleSharedWithUser(shares: [OCShare]) {
		let sharedWithUserPending = shares.filter({ (share) -> Bool in
			if share.state == .pending {
				return true
			}
			return false
		})
		pendingCloudSharesCounter = sharedWithUserPending.count

		let sharedWithUserAccepted = shares.filter({ (share) -> Bool in
			if share.state == .accepted {
				return true
			}
			return false
		})

		OnMainThread {
			self.updatePendingShareRow(shares: sharedWithUserPending, title: "Pending Shares".localized)
			self.updateGenericShareRow(shares: sharedWithUserAccepted, title: "Shared with you".localized, image: UIImage(named: "group")!)
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
			self.updateGenericShareRow(shares: sharedByUser, title: "Shared with others".localized, image: UIImage(named: "group")!)
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

	func updatePendingShareRow(shares: [OCShare], title: String) {
		OnMainThread {
			self.addShareSection()
			let rowIdentifier = String(format: "%@-share-row", title)
			let section = self.sectionForIdentifier("share-section")
			if shares.count > 0 {
				let shareCounter = String(shares.count)

				if section?.row(withIdentifier: rowIdentifier) == nil {
					let pendingLabel = RoundedLabel()
					pendingLabel.update(text: shareCounter, textColor: UIColor.white, backgroundColor: UIColor.red)

					let row = StaticTableViewRow(rowWithAction: { (_, _) in
						let pendingSharesController = PendingSharesTableViewController()
						pendingSharesController.shares = shares
						pendingSharesController.title = title
						pendingSharesController.core = self.core
						self.navigationController?.pushViewController(pendingSharesController, animated: true)
					}, title: title, image: UIImage(named: "group"), accessoryType: .disclosureIndicator, accessoryView: pendingLabel, identifier: rowIdentifier)
					section?.insert(row: row, at: 0, animated: true)
				} else if let row = section?.row(withIdentifier: rowIdentifier) {
					guard let accessoryView = row.additionalAccessoryView as? RoundedLabel else { return }
					accessoryView.update(text: shareCounter, textColor: UIColor.white, backgroundColor: UIColor.red)
				}
			} else {
				if let row = section?.row(withIdentifier: rowIdentifier) {
					section?.remove(rows: [row], animated: true)
				}
			}
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
	// MARK: Collection Section

	func addCollectionSection() {
		if self.sectionForIdentifier("collection-section") == nil {
			let section = StaticTableViewSection(headerTitle: "Collection".localized, footerTitle: nil, identifier: "collection-section")
			self.addSection(section)

			let lastWeekDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!
			let query = OCQuery(condition: .require([
				.where(.lastUsed, isGreaterThan: lastWeekDate),
				.where(.name, isNotEqualTo: "/")
				]), inputFilter:nil)
			addCollectionRow(to: section, title: "Recents".localized, image: UIImage(named: "recents")!, query: query)

			let favoriteQuery = OCQuery(condition: .require([
				.where(.isFavorite, isEqualTo: true)
				]), inputFilter:nil)
			addCollectionRow(to: section, title: "Favorites".localized, image: UIImage(named: "star")!, query: favoriteQuery)

			let imageQuery = OCQuery(condition: .require([
				.where(.mimeType, contains: "image")
				]), inputFilter:nil)
			addCollectionRow(to: section, title: "Images".localized, image: Theme.shared.image(for: "image", size: CGSize(width: 25, height: 25))!, query: imageQuery)

			let pdfQuery = OCQuery(condition: .require([
				.where(.mimeType, contains: "pdf")
				]), inputFilter:nil)
			addCollectionRow(to: section, title: "PDF Documents".localized, image: Theme.shared.image(for: "application-pdf", size: CGSize(width: 25, height: 25))!, query: pdfQuery)
		}
	}

	func addCollectionRow(to section: StaticTableViewSection, title: String, image: UIImage, query: OCQuery) {
		let identifier = String(format:"%@-collection-row", title)
		if section.row(withIdentifier: identifier) == nil, let core = core {
			let row = StaticTableViewRow(rowWithAction: { (_, _) in

				let favoritesFileListController = CustomFilelistTableViewController(core: core, query: query)
				favoritesFileListController.title = title
				self.navigationController?.pushViewController(favoritesFileListController, animated: true)

			}, title: title, image: image, accessoryType: .disclosureIndicator, identifier: identifier)
			section.add(row: row)
		}
	}

}
