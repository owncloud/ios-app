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
	var reshares : [OCShare]?
	var core : OCCore?
	var showSubtitles : Bool = false

	// MARK: - Init

	override func viewDidLoad() {
		super.viewDidLoad()

		self.navigationItem.title = share?.recipient!.displayName!

		let infoButton = UIButton(type: .infoLight)
		infoButton.addTarget(self, action: #selector(showInfoSubtitles), for: .touchUpInside)
		let infoBarButtonItem = UIBarButtonItem(customView: infoButton)
		navigationItem.rightBarButtonItem = infoBarButtonItem

		addPermissionSection()
		addResharesSection()
		addActionSection()
	}

	// MARK: Permission Section

	func addPermissionSection() {
		let section = StaticTableViewSection(headerTitle: "Permissions".localized, footerTitle: nil, identifier: "permission-section")
		guard let share = share else { return }
		var permissions : [[String: Bool]] = []
		var permissionValues : [OCSharePermissionsMask] = []
		var subtitles : [String]?

		if share.itemType == .collection {

			var canEdit = false
			if share.canCreate || share.canUpdate || share.canDelete {
				canEdit = true
			}

			permissions = [
				["Share" : share.canShare],
				["Edit" : canEdit],
				["Create" : share.canCreate],
				["Change" : share.canUpdate],
				["Delete" : share.canDelete]
			]
			permissionValues = [
				.share,
				.read, // Placeholder value, will not be used
				.create,
				.update,
				.delete
			]
			if showSubtitles {
				subtitles = [
					"Allows the users you share with to re-share".localized,
					"Allows the users you share with to edit your shared files, and to collaborate".localized,
					"Allows the users you share with to create new files and add them to the share".localized,
					"Allows uploading a new version of a shared file and replacing it".localized,
					"Allows the users you share with to delete shared files".localized
				]
			}
		} else {
			permissions = [
				["Share" : share.canShare],
				["Edit and Change" : share.canUpdate]
			]
			permissionValues = [
				.share,
				.update
			]
			if showSubtitles {
				subtitles = [
					"Allows the users you share with to re-share".localized,
					"Allows the users you share with to edit your shared files, and to collaborate".localized,
					"Allows uploading a new version of a shared file and replacing it".localized
				]
			}
		}

		section.add(toggleGroupWithArrayOfLabelValueDictionaries: permissions, toggleAction: { (row, _) in
			guard let selected = row.value as? Bool, let rowIndex = row.index else { return }

			var neededPermissions : [Int] = []
			if rowIndex == 1 {
				neededPermissions = [2, 3, 4]
			} else {
				neededPermissions = [rowIndex]
			}

			if let core = self.core {
				core.update(share, afterPerformingChanges: {(share) in

					for currentRowIndex in neededPermissions {
						guard permissionValues.indices.contains(currentRowIndex), let labelKey = permissions[currentRowIndex].keys.first else { return }

						let permissionValue = permissionValues[currentRowIndex]
						let newRow = section.row(withIdentifier: String(format: "preferences-section-%@", labelKey))
						if selected {
							share.permissions.insert(permissionValue)
							newRow?.cell?.accessoryType = .checkmark
							newRow?.value = true
						} else {
							newRow?.cell?.accessoryType = .none
							newRow?.value = false
							share.permissions.remove(permissionValue)
						}
					}

					let newRow = section.row(withIdentifier: "preferences-section-Edit")
					if share.canDelete || share.canCreate || share.canUpdate {
						newRow?.cell?.accessoryType = .checkmark
						newRow?.value = true
					} else {
						newRow?.cell?.accessoryType = .none
						newRow?.value = false
					}
				}, completionHandler: { (error, share) in
					if error == nil {
						guard let changedShare = share else { return }
						self.share?.permissions = changedShare.permissions
					} else {
						if let shareError = error {
							OnMainThread {
								let alertController = UIAlertController(with: "Setting permission failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
								self.present(alertController, animated: true)
							}
						}
					}
				})
			}
		}, subtitles: subtitles, groupIdentifier: "preferences-section", selectedValue:true)
		self.insertSection(section, at: 0, animated: false)
	}

	// MARK: - Reshares Section

	func addResharesSection() {
		var shareRows: [StaticTableViewRow] = []

		if let reshares = reshares, reshares.count > 0 {
			for share in reshares {
				shareRows.append( StaticTableViewRow(rowWithAction: { (_, _) in
					let editSharingViewController = GroupSharingEditUserGroupsTableViewController(style: .grouped)
					editSharingViewController.share = share
					self.navigationController?.pushViewController(editSharingViewController, animated: true)
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
			StaticTableViewRow(buttonWithAction: { (row, _) in
				let progressView = UIActivityIndicatorView(style: Theme.shared.activeCollection.activityIndicatorViewStyle)
				progressView.startAnimating()

				row.cell?.accessoryView = progressView
				if let core = self.core, let share = self.share {
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
			}, title: "Delete Recipient".localized, style: StaticTableViewRowButtonStyle.destructive)
			])

		self.addSection(section)
	}

	// MARK: Actions

	@objc func showInfoSubtitles() {
		showSubtitles.toggle()
		guard let removeSection = self.sectionForIdentifier("permission-section") else { return }
		self.removeSection(removeSection)
		addPermissionSection()
	}
}
