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
	override var shares : [OCShare] {
		didSet {
			let meShares = shares.filter { (share) -> Bool in
				return (share.recipient?.user?.userName == core?.connection.loggedInUser?.userName && share.canShare) ||
				       (share.itemOwner?.userName == core?.connection.loggedInUser?.userName && share.canShare)
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
	var defaultPermissions : OCSharePermissionsMask {
		let meShares = shares.filter { (share) -> Bool in
			return (share.recipient?.user?.userName == core?.connection.loggedInUser?.userName && share.canShare)
		}
		if let share = meShares.first {
			return share.permissions
		}

		var defaultPermissions : OCSharePermissionsMask = .read

		if let capabilitiesDefaultPermission = self.core?.connection.capabilities?.sharingDefaultPermissions {
			defaultPermissions = capabilitiesDefaultPermission
		}

		return defaultPermissions
	}

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
			searchController?.searchBar.placeholder = "Add email or name".localized
			searchController?.searchBar.delegate = self
			navigationItem.hidesSearchBarWhenScrolling = false
			navigationItem.searchController = searchController
			definesPresentationContext = true
			searchController?.searchBar.applyThemeCollection(Theme.shared.activeCollection)
			recipientSearchController = core?.recipientSearchController(for: item)
			recipientSearchController?.delegate = self
		}

		messageView = MessageView(add: self.view)

		self.navigationItem.title = "Collaborators".localized
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissAnimated))

		addHeaderView()

		shareQuery = core?.sharesWithReshares(for: item, initialPopulationHandler: { [weak self] (sharesWithReshares) in
			guard let item = self?.item else { return }

			if sharesWithReshares.count > 0 {
				self?.shares = sharesWithReshares.filter { (share) -> Bool in
					return share.type != .link
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
				return share.type != .link
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
	var actionSection : StaticTableViewSection?

	func addActionShareSection() {
		if let share = shares.first {

			if let section = actionSection {
				self.removeSection(section)
			}

			OnMainThread {
				if self.item.isSharedWithUser {
					let section = StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: "action-section")
					var rows : [StaticTableViewRow] = []

					self.actionSection = section

					let declineRow = StaticTableViewRow(buttonWithAction: { (row, _) in
						let progressView = UIActivityIndicatorView(style: Theme.shared.activeCollection.activityIndicatorViewStyle)
						progressView.startAnimating()

						row.cell?.accessoryView = progressView
						self.core?.makeDecision(on: share, accept: false, completionHandler: { [weak self] (error) in
							guard let self = self else { return }
							OnMainThread {
								if error == nil {
									self.dismissAnimated()
								} else {
									if let shareError = error {
										let alertController = UIAlertController(with: "Unshare failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
										self.present(alertController, animated: true)
									}
								}
							}
						})
					}, title: "Unshare".localized, style: StaticTableViewRowButtonStyle.destructive)
					rows.append(declineRow)
					section.add(rows: rows)
					self.addSection(section)
				}
			}
		} else {
			OnMainThread {
				let shareRow = StaticTableViewRow(buttonWithAction: { [weak self] (_, _) in
					self?.activateRecipienSearch()
					if let actionSection = self?.sectionForIdentifier("action-section") {
						self?.removeSection(actionSection)
					}
					}, title: "Invite Collaborator".localized, style: StaticTableViewRowButtonStyle.plain)

				let section : StaticTableViewSection = StaticTableViewSection(headerTitle: " ", footerTitle: nil, identifier: "action-section", rows: [shareRow])

				self.actionSection = section
				self.addSection(section, animated: true)
			}
		}
	}

	// MARK: - Sharing UI
	var searchResultsSection : StaticTableViewSection?

	func addSectionFor(shares sharesOfType: [OCShare], with title: String, identifier: OCShareType) {
		var shareRows: [StaticTableViewRow] = []

		if sharesOfType.count > 0 {

			for share in sharesOfType {
				let resharedUsers = shares.filter { (filterShare) -> Bool in
					return share.recipient?.user?.userName == filterShare.owner?.userName
				}

				if let recipient = share.recipient {
					if canEdit(share: share) {
						let shareRow = StaticTableViewRow(rowWithAction: { [weak self] (row, _) in
							guard let self = self, let core = self.core else { return }
							let editSharingViewController = GroupSharingEditTableViewController(core: core, item: self.item, share: share, possiblePermissions: self.defaultPermissions, reshares: resharedUsers)

							if share.recipient?.type == .user {
								editSharingViewController.title = row.cell?.textLabel?.text
							} else {
								editSharingViewController.title = String(format:"%@ %@", row.cell?.textLabel?.text ?? "", "(Group)".localized)
							}

							self.navigationController?.pushViewController(editSharingViewController, animated: true)
						}, title: recipient.displayName!, subtitle: share.permissionDescription, image: recipient.user?.avatar, accessoryType: .disclosureIndicator)

						shareRow.representedObject = share

						shareRows.append(shareRow)
					} else {
						let shareRow = StaticTableViewRow(rowWithAction: nil, title: recipient.displayName ?? recipient.identifier ?? "-", subtitle: share.permissionDescription, image: recipient.user?.avatar, accessoryType: .none)

						shareRow.representedObject = share

						shareRows.append(shareRow)
					}
				}
			}
			let sectionIdentifier = "share-section-\(identifier.rawValue)"
			if let section = self.sectionForIdentifier(sectionIdentifier) {
				self.removeSection(section)
			}

			let section : StaticTableViewSection = StaticTableViewSection(headerTitle: title, footerTitle: nil, identifier: sectionIdentifier, rows: shareRows)
			self.addSection(section, animated: true)
		}
	}

	func addOwnerSection() {
		if let share = shares.first, let owner = share.itemOwner, let ownerName = owner.displayName, owner.userName != core?.connection.loggedInUser?.userName, self.sectionForIdentifier("owner-section") == nil {
			let dateFormatter = DateFormatter()
			dateFormatter.dateStyle = .medium
			dateFormatter.timeStyle = .short
			var footer : String?
			if let date = share.creationDate {
				footer = String(format: "Invited: %@".localized, dateFormatter.string(from: date))
			}

			let shareRow = StaticTableViewRow(rowWithAction: nil, title: String(format:"%@", ownerName), accessoryType: .none)

			let section : StaticTableViewSection = StaticTableViewSection(headerTitle: "Owner".localized, footerTitle: footer, identifier: "owner-section", rows: [shareRow])
			self.addSection(section, animated: true)
		}
	}

	func addShareSections() {
		OnMainThread {
			self.addOwnerSection()
			self.addSectionFor(shares: self.shares(ofTypes: [.userShare, .remote]), with: "Users".localized, identifier: .userShare)
			self.addSectionFor(shares: self.shares(ofTypes: [.groupShare]), with: "Groups".localized, identifier: .groupShare)
		}
	}

	func removeShareSections() {
		OnMainThread {
			let types : [OCShareType] = [.userShare, .groupShare]
			for type in types {
				let identifier = "share-section-\(type.rawValue)"
				if let section = self.sectionForIdentifier(identifier) {
					self.removeSection(section)
				}
			}

			if let section = self.sectionForIdentifier("owner-section") {
				self.removeSection(section)
			}
			if let section = self.actionSection {
				self.removeSection(section)
			}
		}
	}

	func resetTable(showShares : Bool) {
		removeShareSections()
		messageView?.message(show: false)
		if let section = searchResultsSection {
			self.removeSection(section)
		}
		if showShares {
			if shares.count > 0 {
				self.addShareSections()
			}
			addActionShareSection()
		}
	}

	// MARK: - UISearchResultsUpdating Delegate

	func updateSearchResults(for searchController: UISearchController) {
		guard let text = searchController.searchBar.text else { return }
		if text.count > core?.connection.capabilities?.sharingSearchMinLength?.intValue ?? 1 {
			if let recipients = recipientSearchController?.recipients, recipients.count > 0,
				recipientSearchController?.searchTerm == text,
				searchResultsSection == nil {
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
			guard let recipients = searchController.recipients, let core = self.core else {
				self.messageView?.message(show: true, imageName: "icon-search", title: "No matches".localized, message: "There are no results for this search term".localized)
				return
			}

			var rows : [StaticTableViewRow] = []
			for recipient in recipients {
				if !(self.shares.map { $0.recipient?.identifier == recipient.identifier }).contains(true) {

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
						StaticTableViewRow(rowWithAction: { [weak self] (row, _) in
							guard let self = self else { return }
							let share = OCShare(recipient: recipient, path: itemPath, permissions: self.defaultPermissions, expiration: nil)

							OnMainThread {
								self.searchController?.searchBar.text = ""
								self.searchController?.dismiss(animated: true, completion: nil)
								self.resetTable(showShares: true)
								let editSharingViewController = GroupSharingEditTableViewController(core: core, item: self.item, share: share, possiblePermissions: self.defaultPermissions)
								editSharingViewController.createShare = true
								editSharingViewController.title = row.cell?.textLabel?.text
								let navigationController = ThemeNavigationController(rootViewController: editSharingViewController)
								self.navigationController?.present(navigationController, animated: true, completion: nil)
							}
							}, title: title, image: image)
					)
				}
			}

			if rows.count > 0 {
				self.messageView?.message(show: false)
				
				self.removeShareSections()
				if let section = self.searchResultsSection {
					self.removeSection(section)
				}
				let searchResultsSection = StaticTableViewSection(headerTitle: "Invite Collaborator".localized, footerTitle: nil, identifier: "search-results", rows: rows)
				self.searchResultsSection = searchResultsSection

				self.addSection(searchResultsSection)
			} else {
				self.messageView?.message(show: true, imageName: "icon-search", title: "No matches".localized, message: "There are no results for this search term".localized)
			}
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

					let alertController = UIAlertController(title: "Delete Collaborator".localized, message: nil, preferredStyle: presentationStyle)

					alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
					alertController.addAction(UIAlertAction(title: "Delete".localized, style: .destructive, handler: { (_) in
						self.core?.delete(shareAtPath, completionHandler: { (error) in
							OnMainThread {
								if error == nil {
									self.navigationController?.popViewController(animated: true)
								} else {
									if let shareError = error {
										let alertController = UIAlertController(with: "Delete Collaborator failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
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
