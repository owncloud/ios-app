//
//  SharingEditUserGroupsTableViewController.swift
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

class SharingEditUserGroupsTableViewController: StaticTableViewController {

	// MARK: - Instance Variables
	var share : OCShare?
	var reshares : [OCShare]?
	var core : OCCore?
	var showSubtitles : Bool = false

	override func viewDidLoad() {
		super.viewDidLoad()

		self.navigationItem.title = share?.recipient!.displayName!

		let infoButton = UIButton(type: .infoLight)
		infoButton.addTarget(self, action: #selector(showInfoSubtitles), for: .touchUpInside)
		let infoBarButtonItem = UIBarButtonItem(customView: infoButton)
		navigationItem.rightBarButtonItem = infoBarButtonItem

		loadPermissionRow()
		loadReshares()
	}

	func loadPermissionRow() {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .short
		var footer = ""
		if let date = share?.creationDate {
			footer = String(format: "Shared since: %@".localized, dateFormatter.string(from: date))
		}

		let section = StaticTableViewSection(headerTitle: "Permissions".localized, footerTitle: footer, identifier: "permission-section")
		guard let share = share else { return }
		var permissions : [[String: Bool]] = []
		var permissionValues : [OCSharePermissionsMask] = []
		var subtitles : [String]?

		if share.itemType == .collection {
			permissions = [
				["Share" : share.canShare],
				["Edit" : share.canUpdate],
				["Create" : share.canCreate],
				["Change" : share.canReadWrite],
				["Delete" : share.canDelete]
			]
			permissionValues = [
				.share,
				.update,
				.update,
				.create,
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

		section.add(toogleGroupWithArrayOfLabelValueDictionaries: permissions, toggleAction: { (row, _) in
			guard let selected = row.value as? Bool else { return }
			if let core = self.core {
				core.connection.update(share, afterPerformingChanges: { (share) in
					if let rowIndex = row.index {
						guard permissionValues.indices.contains(rowIndex) else { return }
						let permissionValue = permissionValues[rowIndex]

						if selected {
							share.permissions.insert(permissionValue)
						} else {
							share.permissions.remove(permissionValue)
						}
					}
				}, resultTarget: OCEventTarget(ephermalEventHandlerBlock: { (event, _) in
					if event.error == nil {
						guard let changedShare = event.result as? OCShare else { return }
						self.share?.permissions = changedShare.permissions
					} else {
						let alertController = UIAlertController(with: "Setting permission failed".localized, message: event.description, okLabel: "OK".localized, action: nil)
						self.present(alertController, animated: true)
					}
				}, userInfo: nil, ephermalUserInfo: nil))
			}

		}, subtitles: subtitles, groupIdentifier: "preferences-section", selectedValue:true)
		self.insertSection(section, at: 0, animated: false)
	}

	func loadReshares() {
		var shareRows: [StaticTableViewRow] = []

		if let reshares = reshares, reshares.count > 0 {
			for share in reshares {
				shareRows.append( StaticTableViewRow(rowWithAction: { (_, _) in
					let editSharingViewController = SharingEditUserGroupsTableViewController(style: .grouped)
					editSharingViewController.share = share
					self.navigationController?.pushViewController(editSharingViewController, animated: true)
				}, title: share.recipient!.displayName!, subtitle: share.permissionDescription(), accessoryType: .disclosureIndicator) )
			}

			let section = StaticTableViewSection(headerTitle: "Shared to".localized, footerTitle: nil, rows: shareRows)
			self.addSection(section)
		}

		let section = StaticTableViewSection(headerTitle: nil, footerTitle: nil)
		section.add(rows: [
			StaticTableViewRow(buttonWithAction: { (row, _) in
				let progressView = UIActivityIndicatorView(style: Theme.shared.activeCollection.activityIndicatorViewStyle)
				progressView.startAnimating()

				row.cell?.accessoryView = progressView
				if let core = self.core, let share = self.share {
					core.connection.delete(share, resultTarget: OCEventTarget(ephermalEventHandlerBlock: { (event, _) in
						OnMainThread {
							if event.error == nil {
								self.navigationController?.popViewController(animated: true)
							} else {
								let alertController = UIAlertController(with: "Delete Recipient failed".localized, message: event.description, okLabel: "OK".localized, action: nil)
								self.present(alertController, animated: true)
							}
						}
					}))
				}
			}, title: "Delete Recipient".localized, style: StaticTableViewRowButtonStyle.destructive)
			])

		self.addSection(section)
	}

	@objc func showInfoSubtitles() {
		showSubtitles.toggle()
		guard let removeSection = self.sectionForIdentifier("permission-section") else { return }
		self.removeSection(removeSection)
		loadPermissionRow()
	}
}
