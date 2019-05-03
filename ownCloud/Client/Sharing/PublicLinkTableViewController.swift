//
//  PublicLinkTableViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 01.05.19.
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

class PublicLinkTableViewController: StaticTableViewController {

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

		guard let item = item else { return }
		messageView = MessageView(add: self.view)

		self.navigationItem.title = "Public Links".localized
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissAnimated))
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPublicLink))

		let shareQuery = core!.sharesWithReshares(for: item, initialPopulationHandler: { (sharesWithReshares) in
			if sharesWithReshares.count > 0 {
				self.shares = sharesWithReshares.filter { (OCShare) -> Bool in
					if OCShare.type == .link {
						return true
					}
					return false
				}
				self.populateShares()
			}
		})

		shareQuery?.refreshInterval = 2
		shareQuery?.changesAvailableNotificationHandler = { query in
			let sharesWithReshares = query.queryResults.filter { (OCShare) -> Bool in
				if OCShare.type == .link {
					return true
				}
				return false
			}
			self.shares = sharesWithReshares
			self.removeShareSections()
			self.populateShares()
			self.handleEmptyShares()
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		handleEmptyShares()
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
				if canEdit(share: share) {
					shareRows.append( StaticTableViewRow(rowWithAction: { (_, _) in
						let editPublicLinkViewController = PublicLinkEditTableViewController(style: .grouped)
						editPublicLinkViewController.share = share
						editPublicLinkViewController.core = self.core
						editPublicLinkViewController.item = self.item
						self.navigationController?.pushViewController(editPublicLinkViewController, animated: true)
					}, title: share.name!, subtitle: share.permissionDescription(), accessoryType: .disclosureIndicator) )
				} else {
					shareRows.append( StaticTableViewRow(rowWithAction: nil, title: share.name!, subtitle: share.permissionDescription(), accessoryType: .none) )
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
			self.addSectionFor(type: .link, with: "Public Links".localized)
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
			messageView?.message(show: true, imageName: "icon-search", title: "Public Link".localized, message: "Add a public link".localized)
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

	// MARK: - Sharing Helper
	func canEdit(share: OCShare) -> Bool {
		if core?.connection.loggedInUser?.userName == share.owner?.userName || core?.connection.loggedInUser?.userName == share.itemOwner?.userName {
			return true
		}

		return false
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

					let alertController = UIAlertController(title: "Delete Public Link".localized,
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
											let alertController = UIAlertController(with: "Delete Public Link failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
											self.present(alertController, animated: true)
										}
									}
								}
							})
						}
					}))

					self.present(alertController, animated: true, completion: nil)
				}),

				UITableViewRowAction(style: .normal, title: "Copy".localized, handler: { (_, _) in
					if let shareURL = share.url {
						UIPasteboard.general.url = shareURL
					}
				})
			]
		}

		return []
	}

	@objc func addPublicLink() {
		if let item = item, let path = item.path, let name = item.name {
			var permissions = OCSharePermissionsMask.create
			if item.type == .file {
				permissions = OCSharePermissionsMask.read
			}

			let share = OCShare(publicLinkToPath: path, linkName: String(format:"%@ %@ (%ld)", name, "Link".localized, (shares.count + 1)), permissions: permissions, password: nil, expiration: nil)
			self.core?.createShare(share, options: nil, completionHandler: { (error, newShare) in
				if error == nil {
					OnMainThread {
						self.resetTable(showShares: true)

						let editPublicLinkViewController = PublicLinkEditTableViewController(style: .grouped)
						editPublicLinkViewController.share = newShare
						editPublicLinkViewController.core = self.core
						editPublicLinkViewController.item = item
						self.navigationController?.pushViewController(editPublicLinkViewController, animated: true)
					}
				} else {
					if let shareError = error {
						OnMainThread {
							self.resetTable(showShares: true)
							let alertController = UIAlertController(with: "Creating public link failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
							self.present(alertController, animated: true)
						}
					}
				}
			})
		}
	}
}
