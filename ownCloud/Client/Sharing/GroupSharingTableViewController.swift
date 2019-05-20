//
//  GroupSharingTableViewController.swift
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

class GroupSharingTableViewController: SharingTableViewController, UISearchResultsUpdating, UISearchBarDelegate, OCRecipientSearchControllerDelegate {

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
	var searchController : UISearchController?
	var recipientSearchController : OCRecipientSearchController?
	var meCanShareItem : Bool = false
	var shouldStartSearch : Bool = false

	// MARK: - Init & Deinit

	override public init(core inCore: OCCore, item inItem: OCItem) {
		super.init(core: inCore, item: inItem)

		if item.isShareable {
			if item.isSharedWithUser == false {
				meCanShareItem = true
			} else if item.isSharedWithUser, core?.connection.capabilities?.sharingResharing == true {
				meCanShareItem = true
			}
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

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
			recipientSearchController = core?.recipientSearchController(for: item)
			recipientSearchController?.delegate = self
		}

		messageView = MessageView(add: self.view)

		self.navigationItem.title = "Sharing".localized
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissAnimated))

		addHeaderView()

		shareQuery = core?.sharesWithReshares(for: item, initialPopulationHandler: { [weak self] (sharesWithReshares) in
			guard let item = self?.item else { return }

			if sharesWithReshares.count > 0 {
				self?.shares = sharesWithReshares.filter { (share) -> Bool in
					if share.type != .link {
						return true
					}
					return false
				}
				OnMainThread {
					self?.addShareSections()
				}
			}

			self?.core?.sharesSharedWithMe(for: item, initialPopulationHandler: { [weak self] (sharesWithMe) in
				OnMainThread {
					if sharesWithMe.count > 0 {
						var shares : [OCShare] = []
						shares.append(contentsOf: sharesWithMe)
						shares.append(contentsOf: sharesWithReshares)
						self?.shares = shares
						self?.removeShareSections()
						self?.addShareSections()
					}

					self?.addActionShareSection()
				}
			})
			}, changesAvailableNotificationHandler: { [weak self] (sharesWithReshares) in
				let sharesWithReshares = sharesWithReshares.filter { (share) -> Bool in
					if share.type != .link {
						return true
					}
					return false
				}
				self?.shares = sharesWithReshares
				OnMainThread {
					self?.removeShareSections()
					self?.addShareSections()

					self?.addActionShareSection()
				}
			}, keepRunning: true)
		shareQuery?.refreshInterval = 2
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if shouldStartSearch {
			shouldStartSearch = false
			// Setting search bar to first responder does only work, if view did appeared
			activateRecipienSearch()
		}
	}

	// MARK: - Action Section

	func addActionShareSection() {
		if let share = shares.first {

			let identifier = "action-section"
			if let section = self.sectionForIdentifier(identifier) {
				self.removeSection(section)
			}

			let dateFormatter = DateFormatter()
			dateFormatter.dateStyle = .medium
			dateFormatter.timeStyle = .short
			var footer = "This link is unique for this resource, but grants no additional permissions. Recipients can request permissions from the owner.".localized
			if let date = share.creationDate {
				footer = footer.appendingFormat("\n\nShared since: %@".localized, dateFormatter.string(from: date))
			}

			OnMainThread {
				if self.item.isSharedWithUser {
					let section = StaticTableViewSection(headerTitle: nil, footerTitle: footer, identifier: "action-section")
					var rows : [StaticTableViewRow] = []

					let declineRow = StaticTableViewRow(buttonWithAction: { (row, _) in
						let progressView = UIActivityIndicatorView(style: Theme.shared.activeCollection.activityIndicatorViewStyle)
						progressView.startAnimating()

						row.cell?.accessoryView = progressView
						self.core?.makeDecision(on: share, accept: false, completionHandler: { (error) in
							OnMainThread {
								if error == nil {
									self.dismissView()
								} else {
									if let shareError = error {
										let alertController = UIAlertController(with: "Decline Share failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
										self.present(alertController, animated: true)
									}
								}
							}
						})
					}, title: "Decline Share".localized, style: StaticTableViewRowButtonStyle.destructive)
					rows.append(declineRow)
					section.add(rows: rows)
					self.addSection(section)
				}
			}
		}
	}

	// MARK: - Sharing UI

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
				if let recipient = share.recipient {
					if canEdit(share: share) {
						shareRows.append( StaticTableViewRow(rowWithAction: { (_, _) in
							let editSharingViewController = GroupSharingEditUserGroupsTableViewController(style: .grouped)
							editSharingViewController.share = share
							editSharingViewController.reshares = resharedUsers
							editSharingViewController.core = self.core
							self.navigationController?.pushViewController(editSharingViewController, animated: true)
						}, title: recipient.displayName!, subtitle: share.permissionDescription(), image: recipient.user?.avatar, accessoryType: .disclosureIndicator) )
					} else {
						shareRows.append( StaticTableViewRow(rowWithAction: nil, title: recipient.displayName!, subtitle: share.permissionDescription(), image: recipient.user?.avatar, accessoryType: .none) )
					}
				}
			}
			let sectionType = "share-section-\(String(type.rawValue))"
			if let section = self.sectionForIdentifier(sectionType) {
				self.removeSection(section)
			}

			let section : StaticTableViewSection = StaticTableViewSection(headerTitle: title, footerTitle: nil, identifier: sectionType, rows: shareRows)
			self.addSection(section, animated: true)
		}
	}

	func addShareSections() {
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

			let identifier = "action-section"
			if let section = self.sectionForIdentifier(identifier) {
				self.removeSection(section)
			}
		}
	}

	func resetTable(showShares : Bool) {
		removeShareSections()
		messageView?.message(show: false)
		if let section = self.sectionForIdentifier("search-results") {
			self.removeSection(section)
		}
		if shares.count > 0 && showShares {
			self.addShareSections()
		}
	}

	// MARK: - Sharing Helper

	func share(at indexPath : IndexPath) -> OCShare? {
		var type : OCShareType?
		switch indexPath.section {
		case 0:
			type = .userShare
		case 1:
			type = .groupShare
		case 2:
			type = .remote
		default:
			break
		}

		if type != nil {
			let shares = self.shares.filter { (OCShare) -> Bool in
				if OCShare.type == type {
					return true
				}
				return false
			}
			if shares.indices.contains(indexPath.row) {
				return shares[indexPath.row]
			}
		}

		return nil
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
		if text.count > core?.connection.capabilities?.sharingSearchMinLength?.intValue ?? 1 {
			if let recipients = recipientSearchController?.recipients, recipients.count > 0,
				recipientSearchController?.searchTerm == text,
				self.sectionForIdentifier("search-results") == nil {
				self.searchControllerHasNewResults(recipientSearchController!, error: nil)
			}

			recipientSearchController?.searchTerm = text
		} else if searchController.isActive {
			resetTable(showShares: false)
		}
	}

	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		self.resetTable(showShares: true)
		self.searchController?.searchBar.isLoading = false
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

				guard let itemPath = self.item.path else { continue }
				var title = ""
				var image: UIImage?
				if recipient.type == .user {
					guard let displayName = recipient.displayName else { continue }
					title = displayName
					image = UIImage(named: "person")
				} else {
					guard let displayName = recipient.displayName else { continue }
					let groupTitle = "(Group)".localized
					title = "\(displayName) \(groupTitle)"
					image = UIImage(named: "group")
				}

				rows.append(
					StaticTableViewRow(rowWithAction: { (_, _) in
						var defaultPermissions : OCSharePermissionsMask = .read
						if let capabilitiesDefaultPermission = self.core?.connection.capabilities?.sharingDefaultPermissions {
							defaultPermissions = capabilitiesDefaultPermission
						}

						let share = OCShare(recipient: recipient, path: itemPath, permissions: defaultPermissions, expiration: nil)

						OnMainThread {
							self.searchController?.searchBar.text = ""
							self.searchController?.dismiss(animated: true, completion: nil)
						}
						self.core?.createShare(share, options: nil, completionHandler: { (error, newShare) in
							if error == nil, let share = newShare {
								OnMainThread {
									self.shares.append(share)
									self.resetTable(showShares: true)

									let editSharingViewController = GroupSharingEditUserGroupsTableViewController(style: .grouped)
									editSharingViewController.share = share
									editSharingViewController.core = self.core
									self.navigationController?.pushViewController(editSharingViewController, animated: true)
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
					}, title: title, image: image)
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
		if isSearching {
			self.searchController?.searchBar.isLoading = true
		} else {
			self.searchController?.searchBar.isLoading = false
		}
	}

	func activateRecipienSearch() {
		self.searchController?.isActive = true
		self.searchController?.searchBar.becomeFirstResponder()
	}

	// MARK: TableView Delegate

	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		if let shareAtPath = share(at: indexPath), self.canEdit(share: shareAtPath) {
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
						self.core?.delete(shareAtPath, completionHandler: { (error) in
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
					}))

					self.present(alertController, animated: true, completion: nil)
				})
			]
		}

		return []
	}
}
