//
//  GroupSharingEditUserGroupsTableViewController.swift
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

class GroupSharingEditUserGroupsTableViewController: StaticTableViewController {

	// MARK: - Instance Variables
	var share : OCShare?
	var item : OCItem?
	var reshares : [OCShare]?
	weak var core : OCCore?
	var showSubtitles : Bool = false
	var createShare : Bool = false
	var permissionMask : OCSharePermissionsMask?

	// MARK: - Init

	override func viewDidLoad() {
		super.viewDidLoad()

		let infoButton = UIButton(type: .infoLight)
		infoButton.addTarget(self, action: #selector(showInfoSubtitles), for: .touchUpInside)
		let infoBarButtonItem = UIBarButtonItem(customView: infoButton)
		toolbarItems = [ UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), infoBarButtonItem]
		navigationController?.toolbar.isTranslucent = false
		navigationController?.isToolbarHidden = false

		addPermissionSection()

		guard let share = share else { return }
		if share.itemType == .collection, (share.canDelete || share.canCreate || share.canUpdate) {
			addPermissionEditSection()
		}
		addResharesSection()

		if createShare {
			let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissAnimated))
			self.navigationItem.leftBarButtonItem = cancel

			let save = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(createShareAndDismiss))
			self.navigationItem.rightBarButtonItem = save

			permissionMask = OCSharePermissionsMask.read
			if let capabilitiesDefaultPermission = self.core?.connection.capabilities?.sharingDefaultPermissions {
				permissionMask = capabilitiesDefaultPermission
			}
		} else {
			addActionSection()
		}
	}

	// MARK: Create Share

	@objc func createShareAndDismiss() {
		guard let share = share else { return }

		if let recipient = share.recipient, let permissionMask = permissionMask {
			let newShare = OCShare(recipient: recipient, path: share.itemPath, permissions: permissionMask, expiration: nil)
			self.core?.createShare(newShare, options: nil, completionHandler: { (error, _) in
				if error == nil {
					OnMainThread {
						self.dismissAnimated()
					}
				} else {
					if let shareError = error {
						OnMainThread {
							let alertController = UIAlertController(with: "Adding User to Share failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
							self.present(alertController, animated: true)
						}
					}
				}
			})
		}
	}

	// MARK: Permission Section

	func addPermissionSection() {
		let section = StaticTableViewSection(headerTitle: "Permissions".localized, footerTitle: nil, identifier: "permission-section")
		guard let share = share else { return }

		var canEdit = false
		if !createShare, share.canUpdate || share.canCreate || share.canDelete {
			canEdit = true
		}
		var canShare = false
		if !createShare, share.canShare {
			canShare = true
		}

		section.add(row: StaticTableViewRow(toggleItemWithAction: { [weak self] (row, _) in
			if let selected = row.value as? Bool {
				self?.changePermissions(enabled: selected, permissions: [.share], completionHandler: {(_) in
				})
			}
		}, title: "Can Share".localized, subtitle: "", selected: canShare, identifier: "permission-section-share"))

		section.add(row: StaticTableViewRow(toggleItemWithAction: { [weak self] (row, _) in
			guard let self = self, let item = self.item else { return }
			if let selected = row.value as? Bool {
				if item.type == .collection {
					if selected {
						self.addPermissionEditSection(animated: true)
					} else {
						if let section = self.sectionForIdentifier("permission-edit-section") {
							self.removeSection(section, animated: true)
						}
					}
					self.changePermissions(enabled: selected, permissions: [.create, .update, .delete], completionHandler: { (_) in
					})
				} else {
					self.changePermissions(enabled: selected, permissions: [.update], completionHandler: { (_) in
					})
				}
			}
		}, title: share.itemType == .collection ? "Can Edit".localized : "Can Edit".localized, subtitle: "", selected: canEdit, identifier: "permission-section-edit"))

		let subtitles = [
			"Allows the users you share with to re-share".localized,
			"Allows the users you share with to edit your shared files, and to collaborate".localized
		]
		updateSubtitles(subtitles: subtitles, section: section)

		self.insertSection(section, at: 0, animated: false)
	}

	private func addPermissionRow(to section: StaticTableViewSection, with title: String, permission: OCSharePermissionsMask, selected: Bool, identifier: String) {
		section.add(row: StaticTableViewRow(toggleItemWithAction: { [weak self] (row, _) in
			if let self = self, let selected = row.value as? Bool {
				self.changePermissions(enabled: selected, permissions: [ permission ], completionHandler: {(_) in
					self.hidePermissionsIfNeeded()
				})
			}
		}, title: title.localized, subtitle: "", selected: selected, identifier: identifier))
	}

	func addPermissionEditSection(animated : Bool = false) {
		let section = StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: "permission-edit-section")
		guard let share = share else { return }

		self.addPermissionRow(to: section, with: "Can Create", permission: .create, selected: share.canCreate, identifier: "permission-section-edit-create")
		self.addPermissionRow(to: section, with: "Can Change", permission: .update, selected: share.canUpdate, identifier: "permission-section-edit-change")
		self.addPermissionRow(to: section, with: "Can Delete", permission: .delete, selected: share.canDelete, identifier: "permission-section-edit-delete")

		let subtitles = [
			"Allows the users you share with to create new files and add them to the share".localized,
			"Allows uploading a new version of a shared file and replacing it".localized,
			"Allows the users you share with to delete shared files".localized
		]
		updateSubtitles(subtitles: subtitles, section: section)

		self.insertSection(section, at: 1, animated: animated)
	}

	func hidePermissionsIfNeeded() {
		if share?.canDelete == false, share?.canCreate == false, share?.canUpdate == false {
			OnMainThread {
				let section = self.sectionForIdentifier("permission-section")
				let newRow = section?.row(withIdentifier: "permission-section-edit")
				newRow?.cell?.accessoryType = .none
				newRow?.value = false

				if let section = self.sectionForIdentifier("permission-edit-section") {
					self.removeSection(section, animated: true)
				}
			}
		}
	}

	func changePermissions(enabled: Bool, permissions : [OCSharePermissionsMask], completionHandler: @escaping (_ error : Error?) -> Void ) {
		guard let share = share else { return }

		if createShare {
			for permissionValue in permissions {
				if enabled {
					permissionMask?.insert(permissionValue)
				} else {
					permissionMask?.remove(permissionValue)
				}
			}
		} else {
			if let core = self.core {
				core.update(share, afterPerformingChanges: {(share) in
					for permissionValue in permissions {
						if enabled {
							share.permissions.insert(permissionValue)
						} else {
							share.permissions.remove(permissionValue)
						}
					}
				}, completionHandler: { (error, share) in
					if error == nil {
						guard let changedShare = share else { return }
						self.share?.permissions = changedShare.permissions
						completionHandler(nil)
					} else {
						if let shareError = error {
							OnMainThread {
								let alertController = UIAlertController(with: "Setting permission failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
								self.present(alertController, animated: true)
								completionHandler(shareError)
							}
						}
					}
				})
			}
		}
	}

	// MARK: - Reshares Section

	func addResharesSection() {
		var shareRows: [StaticTableViewRow] = []

		if let reshares = reshares, reshares.count > 0 {
			for share in reshares {
				shareRows.append( StaticTableViewRow(rowWithAction: { [weak self] (_, _) in
					let editSharingViewController = GroupSharingEditUserGroupsTableViewController(style: .grouped)
					editSharingViewController.share = share
					self?.navigationController?.pushViewController(editSharingViewController, animated: true)
				}, title: share.recipient!.displayName!, subtitle: share.permissionDescription(), accessoryType: .disclosureIndicator) )
			}

			let section = StaticTableViewSection(headerTitle: "Shared to".localized, footerTitle: nil, rows: shareRows)
			self.addSection(section)
		}
	}

	// MARK: - Action Section

	func addActionSection() {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .short
		var footer = ""
		if let date = share?.creationDate {
			footer = String(format: "Shared since: %@".localized, dateFormatter.string(from: date))
		}

		let section = StaticTableViewSection(headerTitle: nil, footerTitle: footer)
		section.add(rows: [
			StaticTableViewRow(buttonWithAction: { [weak self] (row, _) in
				let progressView = UIActivityIndicatorView(style: Theme.shared.activeCollection.activityIndicatorViewStyle)
				progressView.startAnimating()

				row.cell?.accessoryView = progressView
				if let core = self?.core, let share = self?.share {
					core.delete(share, completionHandler: { (error) in
						OnMainThread {
							if error == nil {
								self?.navigationController?.popViewController(animated: true)
							} else {
								if let shareError = error {
									let alertController = UIAlertController(with: "Delete Collaborator failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
									self?.present(alertController, animated: true)
								}
							}
						}
					})
				}
			}, title: "Delete Collaborator".localized, style: StaticTableViewRowButtonStyle.destructive)
			])
		self.addSection(section)
	}

	// MARK: Update Subtitles

	@objc func showInfoSubtitles() {
		showSubtitles.toggle()

		guard let removeSection = self.sectionForIdentifier("permission-section") else { return }
		self.removeSection(removeSection)
		addPermissionSection()

		guard let removeEditSection = self.sectionForIdentifier("permission-edit-section") else { return }
		self.removeSection(removeEditSection)
		addPermissionEditSection(animated: false)
	}

	func updateSubtitles(subtitles : [String], section : StaticTableViewSection) {
		var subtitleIndex = 0
		for row in section.rows {
			if showSubtitles {
				row.cell?.detailTextLabel?.text = subtitles[subtitleIndex]
			} else {
				row.cell?.detailTextLabel?.text = ""
			}
			subtitleIndex += 1
		}
	}
}
