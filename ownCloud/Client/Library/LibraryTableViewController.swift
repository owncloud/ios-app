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

	weak var core : OCCore?

	deinit {
		for query in startedQueries {
			core?.stop(query)
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.title = "Quick Access".localized
		self.navigationController?.navigationBar.prefersLargeTitles = true

		shareSection = StaticTableViewSection(headerTitle: "Shares".localized, footerTitle: nil, identifier: "share-section")
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.navigationBar.prefersLargeTitles = true
	}

	// MARK: - Share setup
	var startedQueries : [OCCoreQuery] = []

	var shareQueryWithUser : OCShareQuery?
	var shareQueryAcceptedCloudShares : OCShareQuery?
	var shareQueryByUser : OCShareQuery?
	var shareQueryPendingCloudShares : OCShareQuery?

	func setupQueries() {
		// Shared with user
		shareQueryWithUser = OCShareQuery(scope: .sharedWithUser, item: nil)

		if let shareQueryWithUser = shareQueryWithUser {
			shareQueryWithUser.refreshInterval = 60

			shareQueryWithUser.initialPopulationHandler = { [weak self] (query) in
				self?.handleSharedWithUserChanges()
			}
			shareQueryWithUser.changesAvailableNotificationHandler = shareQueryWithUser.initialPopulationHandler

			core?.start(shareQueryWithUser)
			startedQueries.append(shareQueryWithUser)
		}

		// Accepted cloud shares
		shareQueryAcceptedCloudShares = OCShareQuery(scope: .acceptedCloudShares, item: nil)

		if let shareQueryAcceptedCloudShares = shareQueryAcceptedCloudShares {
			shareQueryAcceptedCloudShares.refreshInterval = 60

			shareQueryAcceptedCloudShares.initialPopulationHandler = { [weak self] (query) in
				self?.handleSharedWithUserChanges()
			}
			shareQueryAcceptedCloudShares.changesAvailableNotificationHandler = shareQueryAcceptedCloudShares.initialPopulationHandler

			core?.start(shareQueryAcceptedCloudShares)
			startedQueries.append(shareQueryAcceptedCloudShares)
		}

		// Pending cloud shares
		shareQueryPendingCloudShares = OCShareQuery(scope: .pendingCloudShares, item: nil)

		if let shareQueryPendingCloudShares = shareQueryPendingCloudShares {
			shareQueryPendingCloudShares.refreshInterval = 60

			shareQueryPendingCloudShares.initialPopulationHandler = { [weak self] (query) in
				if let library = self {
					library.pendingCloudSharesCounter = query.queryResults.count
					OnMainThread {
						library.updatePendingShareRow(shares: query.queryResults, title: "Pending Federated Invites".localized, pendingCounter: library.pendingCloudSharesCounter)
					}
				}
			}
			shareQueryPendingCloudShares.changesAvailableNotificationHandler = shareQueryPendingCloudShares.initialPopulationHandler

			core?.start(shareQueryPendingCloudShares)
			startedQueries.append(shareQueryPendingCloudShares)
		}

		// Shared by user
		shareQueryByUser = OCShareQuery(scope: .sharedByUser, item: nil)

		if let shareQueryByUser = shareQueryByUser {
			shareQueryByUser.refreshInterval = 60

			shareQueryByUser.initialPopulationHandler = { [weak self] (query) in
				self?.handleSharedByUser(shares: query.queryResults)
			}
			shareQueryByUser.changesAvailableNotificationHandler = shareQueryByUser.initialPopulationHandler

			core?.start(shareQueryByUser)
			startedQueries.append(shareQueryByUser)
		}

		setupCollectionSection()
	}

	// MARK: - Handle sharing updates
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

	func handleSharedWithUserChanges() {
		var shareResults : [OCShare] = []

		if let queryResults = shareQueryWithUser?.queryResults {
			shareResults.append(contentsOf: queryResults)
		}

		if let queryResults = shareQueryAcceptedCloudShares?.queryResults {
			shareResults.append(contentsOf: queryResults)
		}

		self.handleSharedWithUser(shares: shareResults.unique { $0.itemPath })
	}

	func handleSharedWithUser(shares: [OCShare]) {
		let sharedWithUserPending = shares.filter({ (share) -> Bool in
			if share.state == .pending || share.state == .rejected {
				return true
			}
			return false
		})
		pendingLocalSharesCounter = sharedWithUserPending.filter({ (share) -> Bool in
			if share.state == .pending {
				return true
			}
			return false
		}).count

		let sharedWithUserAccepted = shares.filter({ (share) -> Bool in
			if share.state == .accepted || share.type == .remote {
				return true
			}
			return false
		})

		OnMainThread {
			self.updatePendingShareRow(shares: sharedWithUserPending, title: "Pending Invites".localized, pendingCounter: self.pendingLocalSharesCounter)
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
			self.updateGenericShareRow(shares: sharedByUser.unique { $0.itemPath }, title: "Shared with others".localized, image: UIImage(named: "group")!)
			self.updateGenericShareRow(shares: sharedByUserLinks.unique { $0.itemPath }, title: "Public Links".localized, image: UIImage(named: "link")!)
		}
	}

	// MARK: - Sharing Section Updates
	var shareSection : StaticTableViewSection?

	func updateShareSectionVisibility() {
		if let shareSection = shareSection {
			if shareSection.rows.count > 0 {
				if !shareSection.attached {
					self.insertSection(shareSection, at: 0, animated: false)
				}
			} else {
				if shareSection.attached {
					self.removeSection(shareSection, animated: false)
				}
			}
		}
	}

	func updatePendingShareRow(shares: [OCShare], title: String, pendingCounter: Int) {
		let rowIdentifier = String(format: "%@-share-row", title)

		if shares.count > 0 {
			let shareCounter = String(pendingCounter)

			if shareSection?.row(withIdentifier: rowIdentifier) == nil {
				let pendingLabel = RoundedLabel()
				pendingLabel.update(text: shareCounter, textColor: UIColor.white, backgroundColor: UIColor.red)

				let row = StaticTableViewRow(rowWithAction: { [weak self] (_, _) in
					let pendingSharesController = PendingSharesTableViewController()
					pendingSharesController.shares = shares
					pendingSharesController.title = title
					pendingSharesController.core = self?.core
					self?.navigationController?.pushViewController(pendingSharesController, animated: true)
				}, title: title, image: UIImage(named: "group"), accessoryType: .disclosureIndicator, accessoryView: pendingLabel, identifier: rowIdentifier)
				shareSection?.insert(row: row, at: 0, animated: true)
			} else if let row = shareSection?.row(withIdentifier: rowIdentifier) {
				guard let accessoryView = row.additionalAccessoryView as? RoundedLabel else { return }
				accessoryView.update(text: shareCounter, textColor: UIColor.white, backgroundColor: UIColor.red)
			}
		} else {
			shareSection?.remove(rowWithIdentifier: rowIdentifier, animated: true)
		}

		self.updateShareSectionVisibility()
	}

	func updateGenericShareRow(shares: [OCShare], title: String, image: UIImage) {
		let rowIdentifier = String(format:"share-%@row", title)

		if shares.count > 0 {
			if shareSection?.row(withIdentifier: rowIdentifier) == nil, let core = core {
				let row = StaticTableViewRow(rowWithAction: { [weak self] (row, _) in

					let sharesFileListController = SharesFilelistTableViewController(core: core)
					sharesFileListController.shares = shares
					sharesFileListController.title = title
					self?.navigationController?.pushViewController(sharesFileListController, animated: true)

					row.representedObject = sharesFileListController
				}, title: title, image: image, accessoryType: .disclosureIndicator, identifier: rowIdentifier)

				shareSection?.add(row: row)
			} else if let row = shareSection?.row(withIdentifier: rowIdentifier) {
				guard let sharesFileListController = row.representedObject as? SharesFilelistTableViewController else { return }
				sharesFileListController.shares = shares
			}
		} else {
			shareSection?.remove(rowWithIdentifier: rowIdentifier, animated: true)
		}

		self.updateShareSectionVisibility()
	}

	// MARK: - Collection Section
	func setupCollectionSection() {
		if self.sectionForIdentifier("collection-section") == nil {
			let section = StaticTableViewSection(headerTitle: "Collection".localized, footerTitle: nil, identifier: "collection-section")
			self.addSection(section)

			let lastWeekDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!
			let recentsQuery = OCQuery(condition: .require([
				.where(.lastUsed, isGreaterThan: lastWeekDate),
				.where(.name, isNotEqualTo: "/")
			]), inputFilter:nil)
			addCollectionRow(to: section, title: "Recents".localized, image: UIImage(named: "recents")!, query: recentsQuery, actionHandler: nil)
			startedQueries.append(recentsQuery)

			let favoriteQuery = OCQuery(condition: .where(.isFavorite, isEqualTo: true), inputFilter:nil)
			addCollectionRow(to: section, title: "Favorites".localized, image: UIImage(named: "star")!, query: favoriteQuery, actionHandler: { [weak self] (completion) in
				self?.core?.refreshFavorites(completionHandler: { (_, _) in
					completion()
				})
			})
			startedQueries.append(favoriteQuery)

			let imageQuery = OCQuery(condition: .where(.mimeType, contains: "image"), inputFilter:nil)
			addCollectionRow(to: section, title: "Images".localized, image: Theme.shared.image(for: "image", size: CGSize(width: 25, height: 25))!, query: imageQuery, actionHandler: nil)
			startedQueries.append(imageQuery)

			let pdfQuery = OCQuery(condition: .where(.mimeType, contains: "pdf"), inputFilter:nil)
			addCollectionRow(to: section, title: "PDF Documents".localized, image: Theme.shared.image(for: "application-pdf", size: CGSize(width: 25, height: 25))!, query: pdfQuery, actionHandler: nil)
			startedQueries.append(pdfQuery)
		}
	}

	func addCollectionRow(to section: StaticTableViewSection, title: String, image: UIImage, query: OCQuery?, actionHandler: ((_ completion: @escaping () -> Void) -> Void)?) {
		let identifier = String(format:"%@-collection-row", title)
		if section.row(withIdentifier: identifier) == nil, let core = core {
			let row = StaticTableViewRow(rowWithAction: { [weak self] (_, _) in

				if let query = query {
					let customFileListController = CustomFileListTableViewController(core: core, query: query)
					customFileListController.title = title
					customFileListController.pullToRefreshAction = actionHandler
					self?.navigationController?.pushViewController(customFileListController, animated: true)
				}

				actionHandler?({})
			}, title: title, image: image, accessoryType: .disclosureIndicator, identifier: identifier)
			section.add(row: row)
		}
	}

	// MARK: - Theming
	override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		super.applyThemeCollection(theme: theme, collection: collection, event: event)

		self.navigationController?.view.backgroundColor = theme.activeCollection.navigationBarColors.backgroundColor
	}
}
