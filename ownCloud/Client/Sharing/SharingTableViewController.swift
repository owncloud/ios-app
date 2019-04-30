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

class SharingTableViewController: StaticTableViewController, UISearchResultsUpdating, UISearchBarDelegate, OCRecipientSearchControllerDelegate {

	// MARK: - Instance Variables
	var shares : [OCShare] = [] {
		didSet {
			let meShares = shares.filter { (share) -> Bool in
				if share.recipient?.user?.userName == core?.connection.loggedInUser?.userName && share.canShare {
					return true
				} else if share.itemOwner?.userName == core?.connection.loggedInUser?.userName && share.canShare {
					return true
				}
				return false
			}
			if meShares.count > 0 {
				meCanShareItem = true
			}
		}
	}
	var core : OCCore?
	var item : OCItem? {
		didSet {
			if item?.isShareable ?? false {
				meCanShareItem = true
			}
		}
	}
	var searchController : UISearchController?
	var recipientSearchController : OCRecipientSearchController?
	var meCanShareItem : Bool = false
	var messageView : MessageView?

	override func viewDidLoad() {
		super.viewDidLoad()

		if meCanShareItem {
			searchController = UISearchController(searchResultsController: nil)
			searchController?.searchResultsUpdater = self
			searchController?.hidesNavigationBarDuringPresentation = true
			searchController?.dimsBackgroundDuringPresentation = false
			searchController?.searchBar.placeholder = "Search User, Group, Remote".localized
			searchController?.searchBar.delegate = self
			navigationItem.hidesSearchBarWhenScrolling = false
			navigationItem.searchController = searchController
			definesPresentationContext = true
			searchController?.searchBar.applyThemeCollection(Theme.shared.activeCollection)
		}

		guard let item = item else { return }
		messageView = MessageView(add: self.view)
		recipientSearchController = core?.recipientSearchController(for: item)
		recipientSearchController?.delegate = self

		self.navigationItem.title = "Sharing".localized
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissAnimated))

		let shareQuery = core!.sharesWithReshares(for: item, initialPopulationHandler: { (sharesWithReshares) in
			if sharesWithReshares.count > 0 {
				self.shares = sharesWithReshares
				self.populateShares()
			}
			_ = self.core!.sharesSharedWithMe(for: item, initialPopulationHandler: { (sharesWithMe) in
				if sharesWithMe.count > 0 {
					var shares : [OCShare] = []
					shares.append(contentsOf: sharesWithMe)
					shares.append(contentsOf: sharesWithReshares)
					self.shares = shares
					self.removeShareSections()
					self.populateShares()
				}
			})
		})

		shareQuery?.refreshInterval = 2
		shareQuery?.changesAvailableNotificationHandler = { query in
			let sharesWithReshares = query.queryResults
			self.shares = sharesWithReshares
			self.removeShareSections()
			self.populateShares()
			self.handleEmptyShares()
		}
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
				if canEdit(share: share) {
					shareRows.append( StaticTableViewRow(rowWithAction: { (_, _) in
						let editSharingViewController = SharingEditUserGroupsTableViewController(style: .grouped)
						editSharingViewController.share = share
						editSharingViewController.reshares = resharedUsers
						editSharingViewController.core = self.core
						self.navigationController?.pushViewController(editSharingViewController, animated: true)
					}, title: share.recipient!.displayName!, subtitle: share.permissionDescription(), accessoryType: .disclosureIndicator) )
				} else {
					shareRows.append( StaticTableViewRow(rowWithAction: nil, title: share.recipient!.displayName!, subtitle: share.permissionDescription(), accessoryType: .none) )
				}
			}
			let sectionType = "share-section-\(String(type.rawValue))"
			if let section = self.sectionForIdentifier(sectionType) {
				self.removeSection(section)
			}

			let section : StaticTableViewSection = StaticTableViewSection(headerTitle: title, footerTitle: nil, identifier: sectionType, rows: shareRows)
			self.addSection(section)
		}
	}

	func populateShares() {
		OnMainThread {
			self.addSectionFor(type: .userShare, with: "Users".localized)
			self.addSectionFor(type: .groupShare, with: "Groups".localized)
			self.addSectionFor(type: .remote, with: "Remote Users".localized)
		}
	}

	func removeShareSections() {
		OnMainThread {
			let types : [OCShareType] = [.userShare, .groupShare, .remote]
			for type in types {
				let identifier = "share-section-\(String(type.rawValue))"
				if let section = self.sectionForIdentifier(identifier) {
					self.removeSection(section)
				}
			}
		}
	}

	func resetTable(showShares : Bool) {
		removeShareSections()
		if let section = self.sectionForIdentifier("search-results") {
			self.removeSection(section)
		}
		if shares.count > 0 && showShares {
			messageView?.message(show: false)
			self.populateShares()
		} else {
			messageView?.message(show: true, imageName: "icon-search", title: "Search Recipients".localized, message: "Start typing to search users, groups and remote users.".localized)
		}
	}

	func handleEmptyShares() {
		if shares.count == 0 {
			OnMainThread {
				self.resetTable(showShares: false)
				self.searchController?.isActive = true
				self.searchController?.searchBar.becomeFirstResponder()
			}
		}
	}

	func canEdit(share: OCShare) -> Bool {
		if core?.connection.loggedInUser?.userName == share.owner?.userName || core?.connection.loggedInUser?.userName == share.itemOwner?.userName {
			return true
		}

		return false
	}

	// MARK: - UISearchResultsUpdating Delegate
	func updateSearchResults(for searchController: UISearchController) {
		guard let text = searchController.searchBar.text else { return }
		if text.count > 1 {
			recipientSearchController?.searchTerm = text
			recipientSearchController?.search()
		} else if searchController.isActive {
			resetTable(showShares: false)
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		handleEmptyShares()
	}

	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		self.resetTable(showShares: true)
	}

	func searchControllerHasNewResults(_ searchController: OCRecipientSearchController, error: Error?) {
		OnMainThread {
			guard let recipients = searchController.recipients else {
				self.messageView?.message(show: true, imageName: "icon-search", title: "No matches".localized, message: "There is no results for this search".localized)
				return
			}

			self.messageView?.message(show: false)
			var rows : [StaticTableViewRow] = []
			for recipient in recipients {

				guard let itemPath = self.item?.path else { continue }
				var title = ""
				if recipient.type == .user {
					guard let user = recipient.user, let name = user.displayName else { continue }
					title = name
				} else {
					guard let group = recipient.group, let name = group.name else { continue }
					let groupTitle = "(Group)".localized
					title = "\(name) \(groupTitle)"
				}

				rows.append(
					StaticTableViewRow(rowWithAction: { (_, _) in
						let share = OCShare(recipient: recipient, path: itemPath, permissions: .read, expiration: nil)

						OnMainThread {
							self.searchController?.searchBar.text = ""
							self.searchController?.dismiss(animated: true, completion: nil)
						}
						self.core?.createShare(share, options: nil, completionHandler: { (error, _) in
							if error == nil {
								OnMainThread {
									self.resetTable(showShares: true)
								}
							} else {
								if let shareError = error {
									OnMainThread {
										self.resetTable(showShares: true)
										let alertController = UIAlertController(with: "Adding User to Share failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
										self.present(alertController, animated: true)
									}
								}
							}
						})
					}, title: title)
				)
			}
			self.removeShareSections()
			if let section = self.sectionForIdentifier("search-results") {
				self.removeSection(section)
			}

			self.addSection(
				StaticTableViewSection(headerTitle: "Select Share Recipient".localized, footerTitle: nil, identifier: "search-results", rows: rows)
			)
		}
	}

	func searchController(_ searchController: OCRecipientSearchController, isWaitingForResults isSearching: Bool) {

	}

	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		let share = self.shares[indexPath.row]
		if self.canEdit(share: share) {
			return [
				UITableViewRowAction(style: .destructive, title: "Delete".localized, handler: { (_, _) in
					var presentationStyle: UIAlertController.Style = .actionSheet
					if UIDevice.current.isIpad() {
						presentationStyle = .alert
					}

					let alertController = UIAlertController(title: "Delete Recipient".localized,
															message: nil,
															preferredStyle: presentationStyle)
					alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))

					alertController.addAction(UIAlertAction(title: "Delete".localized, style: .destructive, handler: { (_) in
						if let core = self.core {
							core.delete(share, completionHandler: { (error) in
								OnMainThread {
									if error == nil {
										self.navigationController?.popViewController(animated: true)
									} else {
										if let shareError = error {
											let alertController = UIAlertController(with: "Delete Recipient failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
											self.present(alertController, animated: true)
										}
									}
								}
							})
						}
					}))

					self.present(alertController, animated: true, completion: nil)
				})
			]
		}

		return []
	}
}
