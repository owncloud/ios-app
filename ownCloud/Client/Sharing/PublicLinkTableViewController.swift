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
import MobileCoreServices

class PublicLinkTableViewController: SharingTableViewController {

	var publicLinkSharingEnabled : Bool {
		if let core = core, core.connectionStatus == .online, core.connection.capabilities?.sharingAPIEnabled == true, core.connection.capabilities?.publicSharingEnabled == true, item.isShareable { return true }
		return false
	}

	// MARK: - Instance Variables
	override func viewDidLoad() {
		super.viewDidLoad()

		messageView = MessageView(add: self.view)
		tableView.dragDelegate = self

		self.navigationItem.title = "Links".localized
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissAnimated))

		addHeaderView()
		addPrivateLinkSection()

		if publicLinkSharingEnabled {
			self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPublicLink))
			shareQuery = core?.sharesWithReshares(for: item, initialPopulationHandler: { [weak self] (sharesWithReshares) in
				if let self = self, sharesWithReshares.count > 0 {
					self.shares = sharesWithReshares.filter { (share) -> Bool in
						return share.type == .link
					}
					OnMainThread {
						self.addShareSections()
					}
				}
				}, changesAvailableNotificationHandler: { [weak self] (sharesWithReshares) in
					guard let self = self else { return }
					let sharesWithReshares = sharesWithReshares.filter { (share) -> Bool in
						return share.type == .link
					}
					self.shares = sharesWithReshares
					OnMainThread {
						self.removeShareSections()
						self.addShareSections()
						self.handleEmptyShares()
					}
				}, keepRunning: true)
			shareQuery?.refreshInterval = 2
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		handleEmptyShares()
	}

	// MARK: - Sharing UI
	func addSectionFor(shares sharesOfType: [OCShare], with title: String, identifier: OCShareType) {
		var shareRows: [StaticTableViewRow] = []

		if sharesOfType.count > 0 {
			for share in sharesOfType {
				if canEdit(share: share) {
					var linkName = ""
					if let shareName = share.name {
						linkName = shareName
					} else if let token = share.token {
						linkName = token
					}
					let shareRow = StaticTableViewRow(rowWithAction: { [weak self] (_, _) in
						guard let self = self, let core = self.core else { return }
						let editPublicLinkViewController = PublicLinkEditTableViewController(share: share, core: core, item: self.item, defaultLinkName: self.defaultLinkName())
						self.navigationController?.pushViewController(editPublicLinkViewController, animated: true)
					}, title: linkName, subtitle: share.permissionDescription(for: core?.connection.capabilities), accessoryType: .disclosureIndicator)

					shareRow.representedObject = share

					shareRows.append(shareRow)
				} else {
					let shareRow = StaticTableViewRow(rowWithAction: nil, title: share.name!, subtitle: share.permissionDescription(for: core?.connection.capabilities), accessoryType: .none)

					shareRow.representedObject = share

					shareRows.append(shareRow)
				}
			}
		}

		shareRows.append( StaticTableViewRow(buttonWithAction: { [weak self] (_, _) in
			self?.addPublicLink()
			}, title: "Create Public Link".localized, style: StaticTableViewRowButtonStyle.plain))

		let sectionIdentifier = "share-section-\(identifier.rawValue)"
		if let section = self.sectionForIdentifier(sectionIdentifier) {
			self.removeSection(section)
		}
		let section : StaticTableViewSection = StaticTableViewSection(headerTitle: title, footerTitle: nil, identifier: sectionIdentifier, rows: shareRows)
		self.addSection(section, animated: false)
	}

	func addShareSections() {
		if publicLinkSharingEnabled {
			OnMainThread {
				self.addSectionFor(shares: self.shares(ofTypes: [.link]), with: "Public Links".localized, identifier: .link)
			}
		}
	}

	func removeShareSections() {
		OnMainThread {
			let types : [OCShareType] = [.link]
			for type in types {
				let identifier = "share-section-\(type.rawValue)"
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
		}
		self.addShareSections()
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

		let footer = "Only recipients can use this link. Use it as a permanent link to point to this resource".localized

		OnMainThread {
			let section = StaticTableViewSection(headerTitle: "Private Link".localized, footerTitle: footer, identifier: "private-link-section")
			var rows : [StaticTableViewRow] = []

			self.core?.retrievePrivateLink(for: self.item, completionHandler: { (error, url) in

				guard let url = url else { return }
				if error == nil {
					OnMainThread {
						let privateLinkRow = StaticTableViewRow(buttonWithAction: { (row, _) in
							UIPasteboard.general.url = url
							row.cell?.textLabel?.text = url.absoluteString
							row.cell?.textLabel?.font = UIFont.systemFont(ofSize: 15.0)
							row.cell?.textLabel?.textColor = Theme.shared.activeCollection.tableRowColors.secondaryLabelColor
							row.cell?.textLabel?.numberOfLines = 0
							DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
								row.cell?.textLabel?.text = "Copy Private Link".localized
								row.cell?.textLabel?.font = UIFont.systemFont(ofSize: 17.0)
								row.cell?.textLabel?.textColor = Theme.shared.activeCollection.tintColor
								row.cell?.textLabel?.numberOfLines = 1
							}
						}, title: "Copy Private Link".localized, style: .plain)
						rows.append(privateLinkRow)

						section.add(rows: rows)
						self.insertSection(section, at: 0)
					}
				}
			})
		}
	}

	// MARK: TableView Delegate

	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		if let share = share(at: indexPath), self.canEdit(share: share) {
			return [
				UITableViewRowAction(style: .destructive, title: "Delete".localized, handler: { (_, _) in
					var presentationStyle: UIAlertController.Style = .actionSheet
					if UIDevice.current.isIpad() {
						presentationStyle = .alert
					}

					let alertController = ThemedAlertController(title: "Delete Public Link".localized,
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
										let alertController = ThemedAlertController(with: "Delete Public Link failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
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
		if let path = item.path, let core = core {

			func createLink(for itemPath:String, with permissions:OCSharePermissionsMask) {
				let share = OCShare(publicLinkToPath: itemPath, linkName: defaultLinkName(), permissions: permissions, password: nil, expiration: nil)
				let editPublicLinkViewController = PublicLinkEditTableViewController(share: share, core: core, item: self.item, defaultLinkName: defaultLinkName())
				editPublicLinkViewController.createLink = true
				let navigationController = ThemeNavigationController(rootViewController: editPublicLinkViewController)
				self.navigationController?.present(navigationController, animated: true, completion: nil)
			}

			var permissions : OCSharePermissionsMask?

			if item.isSharedWithUser {
				core.sharesSharedWithMe(for: item, initialPopulationHandler: { shares in
					OnMainThread {
						var deepestShare : OCShare?

						for share in shares {
							if share.itemPath == path {
								deepestShare = share
								break
							} else {
								if path.hasPrefix(share.itemPath) {
									if deepestShare == nil {
										deepestShare = share
									} else if let deepestShareItemPath = deepestShare?.itemPath, share.itemPath.count > deepestShareItemPath.count {
										deepestShare = share
									}
								}
							}
						}

						if let share = deepestShare {
							permissions = share.permissions
							createLink(for: path, with: permissions!)
						}
					}
				}, allowPartialMatch: true)
			} else {
				permissions = [.create, .read]
				createLink(for: path, with: permissions!)
			}
		}
	}

	func defaultLinkName() -> String {
		guard let name = item.name else { return "" }
		var linkName = String(format:"%@ %@", name, "Link".localized)
		if let defaultLinkName = core?.connection.capabilities?.publicSharingDefaultLinkName {
			linkName = defaultLinkName
		}
		if shares.count >= 1 {
			linkName = String(format:"%@ (%ld)", linkName, shares.count)
		}

		return linkName
	}
}

// MARK: - Drag delegate
extension PublicLinkTableViewController: UITableViewDragDelegate {

	func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
		if let share = share(at: indexPath), let url = share.url {
			let itemProvider = NSItemProvider(item: url as URL as NSSecureCoding, typeIdentifier: kUTTypeURL as String)
				let dragItem = UIDragItem(itemProvider: itemProvider)

			return [dragItem]
		}

		return []
	}
}
