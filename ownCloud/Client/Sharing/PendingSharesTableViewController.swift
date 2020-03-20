//
//  PendingSharesTableViewController.swift
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

class PendingSharesTableViewController: StaticTableViewController {

	var shares : [OCShare]? {
		didSet {
			OnMainThread {
				self.handleSharesUpdate()
			}
		}
	}
	weak var core : OCCore?
	weak var libraryViewController : LibraryTableViewController?
	var messageView : MessageView?
	private static let imageWidth : CGFloat = 50
	private static let imageHeight : CGFloat = 50

	private var didLoad : Bool = false

	let dateFormatter = DateFormatter()

	override func viewDidLoad() {
		super.viewDidLoad()

		self.navigationController?.navigationBar.prefersLargeTitles = false
		self.tableView.backgroundColor = Theme.shared.activeCollection.tableBackgroundColor

		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .short

		didLoad = true
		handleSharesUpdate()
	}

	func handleSharesUpdate() {
		guard let shares = shares, didLoad else { return }
		let pendingShares = shares.filter { (share) -> Bool in
			return  ((share.type == .remote) && (share.accepted == false)) ||	// Federated share (pending)
				((share.type != .remote) && (share.state == .pending))		// Local share (pending)
		}

		let rejectedShares = shares.filter { (share) -> Bool in
			return	((share.type != .remote) && (share.state == .rejected))		// Local share (rejected)
		}

		updateSection(for: pendingShares, title: "Pending".localized, sectionID: "pending", placeAtTop: true)
		updateSection(for: rejectedShares, title: "Declined".localized, sectionID: "declined", placeAtTop: false)

		if (pendingShares.count == 0) && (rejectedShares.count == 0) && self.presentedViewController == nil {
			// Pop back to the Library when there are no longer any shares to present and no alert is active
			self.navigationController?.popViewController(animated: true)
		}
	}

	func updateSection(for shares: [OCShare], title: String, sectionID: String, placeAtTop: Bool) {
		var section : StaticTableViewSection? = sectionForIdentifier(sectionID)

		if shares.count == 0 {
			if let section = section {
				removeSection(section, animated: true)
			}
			return
		}

		if section == nil {
			section = StaticTableViewSection(headerTitle: title, footerTitle: nil, identifier: sectionID)
		}

		if let section = section {
			// Clear existing rows
			section.remove(rows: section.rows)

			// Create new rows
			for share in shares {
				var ownerName : String?
				if share.itemOwner?.displayName != nil {
					ownerName = share.itemOwner?.displayName
				} else if share.owner?.userName != nil {
					ownerName = share.owner?.userName
				}

				if let displayName = ownerName {
					var itemImageType = "file"
					if share.itemType == .collection {
						itemImageType = "folder"
					}
					var footer = String(format: "Shared by %@".localized, displayName)
					if let date = share.creationDate {
						footer = footer.appendingFormat("\n%@", dateFormatter.string(from: date))
					}

					var itemName = share.name
					if share.itemPath.count > 0 {
						itemName = (share.itemPath as NSString).lastPathComponent
					}

					let row = StaticTableViewRow(rowWithAction: { [weak self] (_, _) in
						guard let self = self else { return }
						var presentationStyle: UIAlertController.Style = .actionSheet
						if UIDevice.current.isIpad() {
							presentationStyle = .alert
						}

						let alertController = ThemedAlertController(title: String(format: "Accept Invite %@".localized, itemName ?? ""),
											message: nil,
											preferredStyle: presentationStyle)
						alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))

						alertController.addAction(UIAlertAction(title: "Accept".localized, style: .default, handler: { [weak self] (_) in
							self?.handleDecision(on: share, accept: true)
						}))

						if share.state != .rejected {
							alertController.addAction(UIAlertAction(title: "Decline".localized, style: .destructive, handler: { [weak self] (_) in
								self?.handleDecision(on: share, accept: false)
							}))
						}

						self.present(alertController, animated: true, completion: nil)
					}, title: itemName ?? "Share".localized, subtitle: footer, image: Theme.shared.image(for: itemImageType, size: CGSize(width: PendingSharesTableViewController.imageWidth, height: PendingSharesTableViewController.imageHeight)), identifier: "row")

					row.representedObject = share

					section.add(row: row)

					if share.itemPath.count > 0 {
						if let itemTracker = core?.trackItem(atPath: share.itemPath, trackingHandler: { (error, item, isInitial) in
							if error == nil, isInitial {
								OnMainThread {
									row.cell?.imageView?.image = item?.icon(fitInSize: CGSize(width: PendingSharesTableViewController.imageWidth, height: PendingSharesTableViewController.imageHeight))
								}
							}
						}) {
							row.representedObject = itemTracker // End tracking when the row is deallocated
						}
					}
				}
			}
		}

		if let section = section, !section.attached {
			if placeAtTop {
				insertSection(section, at: 0)
			} else {
				addSection(section)
			}
		}
	}

	// MARK: - TableView Delegate
	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		let row = self.staticRowForIndexPath(indexPath)
		guard let share = row.representedObject as? OCShare else { return [] }

		let acceptAction = UITableViewRowAction(style: .normal, title: "Accept".localized, handler: { [weak self] (_, _) in
			self?.handleDecision(on: share, accept: true)
		})
		let declineAction = UITableViewRowAction(style: .destructive, title: "Decline".localized, handler: { [weak self] (_, _) in
			self?.handleDecision(on: share, accept: false)
		})

		if share.state != .rejected {
			return [acceptAction, declineAction]
		} else {
			return [acceptAction]
		}
	}

	// MARK: - Decision handling
	func makeDecision(on share: OCShare, accept: Bool) {
		if let core = core {
			core.makeDecision(on: share, accept: accept, completionHandler: { [weak self] (error) in
				guard let strongSelf = self else { return }

				OnMainThread {
					if error != nil {
						if let shareError = error {
							let alertController = ThemedAlertController(with: (accept ? "Accept Share failed".localized : "Decline Share failed".localized), message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
							strongSelf.present(alertController, animated: true)
						}
					} else if let libraryViewController = strongSelf.libraryViewController {
						libraryViewController.reloadQueries()
					}
				}
			})
		}
	}

	func handleDecision(on share: OCShare, accept: Bool) {
		if accept {
			makeDecision(on: share, accept: accept)
		} else {
			if share.type == .remote {
				var itemName = share.name
				if share.itemPath.count > 0 {
					itemName = (share.itemPath as NSString).lastPathComponent
				}

				let alertController = ThemedAlertController(title: String(format: "Decline Invite %@".localized, itemName ?? ""), message: "Decline cannot be undone.", preferredStyle: .alert)
				alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
				alertController.addAction(UIAlertAction(title: "Decline".localized, style: .destructive, handler: { [weak self] (_) in
					self?.makeDecision(on: share, accept: accept)
				}))
				self.present(alertController, animated: true, completion: nil)
			} else {
				makeDecision(on: share, accept: accept)
			}
		}
	}
}

extension PendingSharesTableViewController : LibraryShareList {
	func updateWith(shares: [OCShare]) {
		self.shares = shares
	}
}
