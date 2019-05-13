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
	var core : OCCore?
	var messageView : MessageView?
	private let imageWidth : CGFloat = 50
	private let imageHeight : CGFloat = 50
	var itemTracker : OCCoreItemTracking?

	deinit {
		itemTracker = nil
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.title = "Pending Shares".localized

		if self.sectionForIdentifier("pending-section") == nil {
			let section = StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: "pending-section")
			self.insertSection(section, at: 0, animated: false)

			let dateFormatter = DateFormatter()
			dateFormatter.dateStyle = .medium
			dateFormatter.timeStyle = .short

			if let shares = shares {
				for share in shares {
					if let displayName = share.itemOwner?.displayName {
						var itemImageType = "file"
						if share.itemType == .collection {
							itemImageType = "folder"
						}
						var footer = ""
						if let date = share.creationDate {
							footer = String(format: "Shared by %@\n%@".localized, displayName, dateFormatter.string(from: date))
						}

						let row = StaticTableViewRow(rowWithAction: { (_, _) in
							var presentationStyle: UIAlertController.Style = .actionSheet
							if UIDevice.current.isIpad() {
								presentationStyle = .alert
							}

							let alertController = UIAlertController(title: "Pending Share".localized,
																	message: nil,
																	preferredStyle: presentationStyle)
							alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))

							alertController.addAction(UIAlertAction(title: "Accept".localized, style: .default, handler: { (_) in
								if let core = self.core {

									core.makeDecision(on: share, accept: true, completionHandler: { (error) in
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

							alertController.addAction(UIAlertAction(title: "Decline".localized, style: .destructive, handler: { (_) in
								if let core = self.core {

									core.makeDecision(on: share, accept: false, completionHandler: { (error) in
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

						}, title: (share.itemPath as NSString).lastPathComponent, subtitle: footer, image: Theme.shared.image(for: itemImageType, size: CGSize(width: imageWidth, height: imageHeight)), identifier: "row")
						section.add(row: row)

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

	// MARK: TableView Delegate

	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		if let shares = shares {
			let share = shares[indexPath.row]
			return [

				UITableViewRowAction(style: .normal, title: "Accept".localized, handler: { (_, _) in
					if let core = self.core {

						core.makeDecision(on: share, accept: true, completionHandler: { (error) in
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
				UITableViewRowAction(style: .destructive, title: "Decline".localized, handler: { (_, _) in
					var presentationStyle: UIAlertController.Style = .actionSheet
					if UIDevice.current.isIpad() {
						presentationStyle = .alert
					}

					let alertController = UIAlertController(title: "Decline Share".localized,
															message: nil,
															preferredStyle: presentationStyle)
					alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))

					alertController.addAction(UIAlertAction(title: "Decline".localized, style: .destructive, handler: { (_) in
						if let core = self.core {

							core.makeDecision(on: share, accept: false, completionHandler: { (error) in
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
