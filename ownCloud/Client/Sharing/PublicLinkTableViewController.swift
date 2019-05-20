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
	var shares : [OCShare] = []
	weak var core : OCCore?
	var item : OCItem
	var messageView : MessageView?
	var shareQuery : OCShareQuery?

	// MARK: - Init & Deinit

	public init(core inCore: OCCore, item inItem: OCItem) {
		core = inCore
		item = inItem

		super.init(style: .grouped)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		messageView = MessageView(add: self.view)

		self.navigationItem.title = "Public Links".localized
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissView))
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPublicLink))

		addHeaderView()
		addPrivateLinkSection()

		shareQuery = core?.sharesWithReshares(for: item, initialPopulationHandler: { (sharesWithReshares) in
			if sharesWithReshares.count > 0 {
				self.shares = sharesWithReshares.filter { (OCShare) -> Bool in
					if OCShare.type == .link {
						return true
					}
					return false
				}
				OnMainThread {
					self.addShareSections()
				}
			}
		}, changesAvailableNotificationHandler: { (sharesWithReshares) in
			let sharesWithReshares = sharesWithReshares.filter { (OCShare) -> Bool in
				if OCShare.type == .link {
					return true
				}
				return false
			}
			self.shares = sharesWithReshares
			OnMainThread {
				self.removeShareSections()
				self.addShareSections()
				self.handleEmptyShares()
			}
		})
		shareQuery?.refreshInterval = 2
	}

	@objc func dismissView() {
		if let query = self.shareQuery {
			self.core?.stop(query)
		}
		dismissAnimated()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		handleEmptyShares()
	}

	// MARK: - Header View

	func addHeaderView() {
		guard let core = core else { return }
		let containerView = UIView()
		containerView.translatesAutoresizingMaskIntoConstraints = false

		let headerView = MoreViewHeader(for: item, with: core, favorite: false)
		containerView.addSubview(headerView)
		self.tableView.tableHeaderView = containerView

		containerView.centerXAnchor.constraint(equalTo: self.tableView.centerXAnchor).isActive = true
		containerView.widthAnchor.constraint(equalTo: self.tableView.widthAnchor).isActive = true
		containerView.topAnchor.constraint(equalTo: self.tableView.topAnchor).isActive = true
		containerView.heightAnchor.constraint(equalTo: headerView.heightAnchor).isActive = true

		self.tableView.tableHeaderView?.layoutIfNeeded()
		self.tableView.tableHeaderView = self.tableView.tableHeaderView
		self.tableView.tableHeaderView?.backgroundColor = Theme.shared.activeCollection.tableBackgroundColor
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
			self.addSection(section, animated: true)
		}
	}

	func addShareSections() {
		OnMainThread {
			self.addSectionFor(type: .link, with: "Public Links".localized)
		}
	}

	func removeShareSections() {
		OnMainThread {
			let types : [OCShareType] = [.link]
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
		if shares.count > 0 && showShares {
			messageView?.message(show: false)
			self.addShareSections()
		}
	}

	func handleEmptyShares() {
		if shares.count == 0 {
			OnMainThread {
				self.resetTable(showShares: false)
			}
		}
	}

	// MARK: - Private Link Section

	func addPrivateLinkSection() {
			let identifier = "private-link-section"
			if let section = self.sectionForIdentifier(identifier) {
				self.removeSection(section)
			}

			let footer = "This link is unique for this resource, but grants no additional permissions. Recipients can request permissions from the owner.".localized

			OnMainThread {
				let section = StaticTableViewSection(headerTitle: nil, footerTitle: footer, identifier: "private-link-section")
				var rows : [StaticTableViewRow] = []

				let privateLinkRow = StaticTableViewRow(buttonWithAction: { (row, _) in
					let progressView = UIActivityIndicatorView(style: Theme.shared.activeCollection.activityIndicatorViewStyle)
					progressView.startAnimating()

					row.cell?.accessoryView = progressView

					self.core?.retrievePrivateLink(for: self.item, completionHandler: { (error, url) in
						OnMainThread {
							row.cell?.accessoryView = nil
						}
						if error == nil {
							guard let url = url else { return }
							UIPasteboard.general.url = url
						}
					})

				}, title: "Copy Private Link".localized, style: StaticTableViewRowButtonStyle.plain)
				rows.append(privateLinkRow)

				section.add(rows: rows)
				self.addSection(section)
			}
	}

	// MARK: - Sharing Helper
	func canEdit(share: OCShare) -> Bool {
		if core?.connection.loggedInUser?.userName == share.owner?.userName || core?.connection.loggedInUser?.userName == share.itemOwner?.userName {
			return true
		}

		return false
	}

	// MARK: TableView Delegate

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
							self.core?.delete(share, completionHandler: { (error) in
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

	// MARK: Add New Link Share

	@objc func addPublicLink() {
		if let path = item.path, let name = item.name {
			var permissions = OCSharePermissionsMask.create
			if item.type == .file {
				permissions = OCSharePermissionsMask.read
			}

			var linkName = String(format:"%@ %@ (%ld)", name, "Link".localized, (shares.count + 1))
			if let defaultLinkName = core?.connection.capabilities?.publicSharingDefaultLinkName {
				linkName = defaultLinkName
			}

			let share = OCShare(publicLinkToPath: path, linkName: linkName, permissions: permissions, password: nil, expiration: nil)
			self.core?.createShare(share, options: nil, completionHandler: { (error, newShare) in
				if error == nil, let share = newShare {
					OnMainThread {
						self.shares.append(share)
						self.resetTable(showShares: true)

						let editPublicLinkViewController = PublicLinkEditTableViewController(style: .grouped)
						editPublicLinkViewController.share = share
						editPublicLinkViewController.core = self.core
						editPublicLinkViewController.item = self.item
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
