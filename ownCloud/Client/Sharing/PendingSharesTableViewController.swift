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

	var shares : [OCShare]?
	weak var core : OCCore?
	var messageView : MessageView?
	private let imageWidth : CGFloat = 50
	private let imageHeight : CGFloat = 50
	var itemTracker : OCCoreItemTracking?

	deinit {
		itemTracker = nil
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.navigationController?.navigationBar.prefersLargeTitles = false
		self.tableView.backgroundColor = Theme.shared.activeCollection.tableBackgroundColor
		prepareItems()
	}

	func prepareItems() {
		if self.sectionForIdentifier("pending-section") == nil {
			let section = StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: "pending-section")
			self.insertSection(section, at: 0, animated: false)

			let dateFormatter = DateFormatter()
			dateFormatter.dateStyle = .medium
			dateFormatter.timeStyle = .short

			if let shares = shares {
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

							let alertController = UIAlertController(title: self.title,
																	message: nil,
																	preferredStyle: presentationStyle)
							alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))

							alertController.addAction(UIAlertAction(title: "Accept".localized, style: .default, handler: { [weak self] (_) in
								if let self = self, let core = self.core {
									core.makeDecision(on: share, accept: true, completionHandler: { [weak self] (error) in
										guard let self = self else { return }
										OnMainThread {
											if error == nil {
												self.navigationController?.popViewController(animated: true)
											} else {
												if let shareError = error {
													let alertController = UIAlertController(with: "Accept Share failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
													self.present(alertController, animated: true)
												}
											}
										}
									})
								}
							}))

							alertController.addAction(UIAlertAction(title: "Decline".localized, style: .destructive, handler: { [weak self] (_) in
								if let self = self, let core = self.core {
									core.makeDecision(on: share, accept: false, completionHandler: { [weak self] (error) in
										guard let self = self else { return }
										OnMainThread {
											if error == nil {
												self.navigationController?.popViewController(animated: true)
											} else {
												if let shareError = error {
													let alertController = UIAlertController(with: "Decline Share failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
													self.present(alertController, animated: true)
												}
											}
										}
									})
								}
							}))

							self.present(alertController, animated: true, completion: nil)

						}, title: itemName ?? "Share".localized, subtitle: footer, image: Theme.shared.image(for: itemImageType, size: CGSize(width: imageWidth, height: imageHeight)), identifier: "row")
						section.add(row: row)

						if share.itemPath.count > 0 {
							itemTracker = core?.trackItem(atPath: share.itemPath, trackingHandler: { (error, item, isInitial) in
								if error == nil, isInitial {
									OnMainThread {
										row.cell?.imageView?.image = item?.icon(fitInSize: CGSize(width: self.imageWidth, height: self.imageHeight))
									}
								}
							})
						}
					}
				}
			}
		}

	}

	// MARK: TableView Delegate

	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		if let shares = shares {
			let share = shares[indexPath.row]
			return [

				UITableViewRowAction(style: .normal, title: "Accept".localized, handler: { [weak self] (_, _) in
					if let self = self, let core = self.core {
						core.makeDecision(on: share, accept: true, completionHandler: { [weak self] (error) in
							guard let self = self else { return }
							OnMainThread {
								if error == nil {
									self.navigationController?.popViewController(animated: true)
								} else {
									if let shareError = error {
										let alertController = UIAlertController(with: "Accept Share failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
										self.present(alertController, animated: true)
									}
								}
							}
						})
					}
				}),
				UITableViewRowAction(style: .destructive, title: "Decline".localized, handler: { [weak self] (_, _) in
					guard let self = self else { return }
					var presentationStyle: UIAlertController.Style = .actionSheet
					if UIDevice.current.isIpad() {
						presentationStyle = .alert
					}

					let alertController = UIAlertController(title: "Decline Share".localized,
															message: nil,
															preferredStyle: presentationStyle)
					alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))

					alertController.addAction(UIAlertAction(title: "Decline".localized, style: .destructive, handler: { [weak self] (_) in
						if let self = self, let core = self.core {
							core.makeDecision(on: share, accept: false, completionHandler: { [weak self] (error) in
								guard let self = self else { return }
								OnMainThread {
									if error == nil {
										self.navigationController?.popViewController(animated: true)
									} else {
										if let shareError = error {
											let alertController = UIAlertController(with: "Decline Share failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
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
