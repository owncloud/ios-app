//
//  PublicLinkEditTableViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 01.05.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

class PublicLinkEditTableViewController: StaticTableViewController {

	// MARK: - Instance Variables
	var share : OCShare?
	var core : OCCore?
	var item : OCItem?
	var showSubtitles : Bool = false

	override func viewDidLoad() {
		super.viewDidLoad()

		self.navigationItem.title = share?.name!

		let infoBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareLinkURL))
		navigationItem.rightBarButtonItem = infoBarButtonItem

		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .short
		var footer = ""
		if let date = share?.creationDate {
			footer = String(format: "Shared since: %@".localized, dateFormatter.string(from: date))
		}

		let section = StaticTableViewSection(headerTitle: "Name", footerTitle: nil, identifier: "permission-section")
		let nameRow = StaticTableViewRow(textFieldWithAction: { (row, _) in
			if let core = self.core {
				guard let share = self.share, let name = row.textField?.text else { return }
				core.update(share, afterPerformingChanges: {(share) in
					share.name = name
				}, completionHandler: { (error, share) in
					if error == nil {
						guard let changedShare = share else { return }
						self.share?.name = changedShare.name
					} else {
						if let shareError = error {
							OnMainThread {
								let alertController = UIAlertController(with: "Setting name failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
								self.present(alertController, animated: true)
							}
						}
					}
				})
			}
		}, placeholder: "Public Link".localized, value: (share?.name!)!, secureTextEntry: false, keyboardType: .default, autocorrectionType: .default, enablesReturnKeyAutomatically: true, returnKeyType: .default, identifier: "Name")

		section.add(row: nameRow)
		self.addSection(section)

		loadPermissionRow()

		var hasPassword = false
		if share?.protectedByPassword == true {
			hasPassword = true
		}

		let passwordSection = StaticTableViewSection(headerTitle: "Password", footerTitle: nil, identifier: "permission-section")
		let passwordRow = StaticTableViewRow(switchWithAction: { (_, sender) in
			if let passwordSwitch = sender as? UISwitch {
				if passwordSwitch.isOn == false, let passwordFieldRow = passwordSection.row(withIdentifier: "passwordFieldRow") {
					passwordSection.remove(rows: [passwordFieldRow], animated: true)
				} else if passwordSwitch.isOn {
					self.passwordRow(passwordSection)
				}
			}
		}, title: "Protect with password".localized, value: hasPassword, identifier: "PasswordRow")
		passwordSection.add(row: passwordRow)
		if hasPassword {
			self.passwordRow(passwordSection)
		}
		self.addSection(passwordSection)

		var hasExpireDate = false
		if share?.expirationDate != nil {
			hasExpireDate = true
		}

		let expireSection = StaticTableViewSection(headerTitle: "Expire Date", footerTitle: nil, identifier: "expire-section")
		let expireDateRow = StaticTableViewRow(switchWithAction: { (_, sender) in
			if let expireDateSwitch = sender as? UISwitch {
				if expireDateSwitch.isOn == false, let expireDateRow = expireSection.row(withIdentifier: "expireDateRow") {
					var rows : [StaticTableViewRow] = [expireDateRow]
					if let expireDatePickerRow = expireSection.row(withIdentifier: "datePickerRow") {
						rows.append(expireDatePickerRow)
					}
					expireSection.remove(rows: rows, animated: true)
				} else if expireDateSwitch.isOn {
					self.expireDateRow(expireSection)
				}

				if let core = self.core {
					guard let share = self.share, let datePicker = sender as? UIDatePicker else { return }
					core.update(share, afterPerformingChanges: {(share) in
						if expireDateSwitch.isEnabled {
							share.expirationDate = Date()
						} else {
							share.expirationDate = nil
						}

					}, completionHandler: { (error, share) in
						if error == nil {
							guard let changedShare = share else { return }
							self.share?.expirationDate = changedShare.expirationDate

							if let expireDateRow = expireSection.row(withIdentifier: "expireDateRow") {
								OnMainThread {
									expireDateRow.cell?.textLabel?.text = dateFormatter.string(from: datePicker.date)
								}
							}
						} else {
							if let shareError = error {
								OnMainThread {
									let alertController = UIAlertController(with: "Setting expiration date failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
									self.present(alertController, animated: true)
								}
							}
						}
					})
				}
			}
		}, title: "Link has expire date".localized, value: hasExpireDate, identifier: "ExpireRow")
		expireSection.add(row: expireDateRow)

		if hasExpireDate {
			self.expireDateRow(expireSection)
		}
		self.addSection(expireSection)

		let deleteSection = StaticTableViewSection(headerTitle: nil, footerTitle: footer)
		deleteSection.add(rows: [
			StaticTableViewRow(buttonWithAction: { (_, _) in
				guard let share = self.share, let shareURL = share.url else { return }
				UIPasteboard.general.url = shareURL
			}, title: "Copy Public Link URL".localized, style: StaticTableViewRowButtonStyle.plain)
			])

		deleteSection.add(rows: [
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
									let alertController = UIAlertController(with: "Delete Public Link failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
									self.present(alertController, animated: true)
								}
							}
						}
					})
				}
			}, title: "Delete Public Link".localized, style: StaticTableViewRowButtonStyle.destructive)
			])

		self.addSection(deleteSection)
	}

	func passwordRow(_ passwordSection : StaticTableViewSection) {
		var passwordValue = ""
		if let password = share?.password {
			passwordValue = password
		}

		let expireDateRow = StaticTableViewRow(secureTextFieldWithAction: { (_, sender) in

			if let core = self.core {
				guard let share = self.share, let textField = sender as? UITextField else { return }
				core.update(share, afterPerformingChanges: {(share) in
					share.password = textField.text
				}, completionHandler: { (error, share) in
					if error == nil {
						guard let changedShare = share else { return }
						self.share?.password = changedShare.password
					} else {
						if let shareError = error {
							OnMainThread {
								let alertController = UIAlertController(with: "Setting password failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
								self.present(alertController, animated: true)
							}
						}
					}
				})
			}

		}, placeholder: "Type to update password".localized, value: passwordValue, keyboardType: .default, enablesReturnKeyAutomatically: true, returnKeyType: .default, identifier: "passwordFieldRow")
		passwordSection.add(row: expireDateRow)
	}

	func expireDateRow(_ expireSection : StaticTableViewSection) {
		var expireDate = Date()
		if let date = share?.expirationDate {
			expireDate = date
		}

			let dateFormatter = DateFormatter()
			dateFormatter.dateStyle = .long
			dateFormatter.timeStyle = .none
			let expireDateRow = StaticTableViewRow(buttonWithAction: { (_, _) in
				if expireSection.row(withIdentifier: "datePickerRow") == nil {

					let datePickerRow = StaticTableViewRow(datePickerWithAction: { (row, sender) in

						if let core = self.core {
							guard let share = self.share, let datePicker = sender as? UIDatePicker else { return }
							core.update(share, afterPerformingChanges: {(share) in
								share.expirationDate = datePicker.date
							}, completionHandler: { (error, share) in
								if error == nil {
									guard let changedShare = share else { return }
									self.share?.expirationDate = changedShare.expirationDate

									if let expireDateRow = expireSection.row(withIdentifier: "expireDateRow") {
										OnMainThread {
											expireDateRow.cell?.textLabel?.text = dateFormatter.string(from: datePicker.date)
										}
									}
								} else {
									if let shareError = error {
										OnMainThread {
											let alertController = UIAlertController(with: "Setting expiration date failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
											self.present(alertController, animated: true)
										}
									}
								}
							})
						}
					}, date: expireDate, identifier: "datePickerRow")
					expireSection.add(row: datePickerRow, animated: true)
				} else {
					if let datePickerRow = expireSection.row(withIdentifier: "datePickerRow") {
						expireSection.remove(rows: [datePickerRow], animated: true)
					}
				}
			}, title: dateFormatter.string(from: expireDate), style: .plain, alignment: .left, identifier: "expireDateRow")

			expireSection.add(row: expireDateRow)
	}

	func loadPermissionRow() {
		let section = StaticTableViewSection(headerTitle: "Permissions".localized, footerTitle: nil, identifier: "permission-section")
		guard let share = share, let item = item else { return }

		if item.type == .collection {
			var permissions : [[String: Bool]] = []
			var permissionValues : [OCSharePermissionsMask] = []
			var subtitles : [String]?
			permissions = [
				["Download / View" : share.canShare],
				["Download / View / Upload" : share.canUpdate],
				["Upload only (File Drop)" : share.canCreate],
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
					"Recipients can view or download contents.".localized,
					"Recipients can view, download, edit, delete and upload contents.".localized,
					"Receive files from multiple recipients without revealing the contents of the folder.".localized
				]
			}

			var currentPermission = 2
			if share.canUpdate {
				currentPermission = 1
			} else if share.canRead {
				currentPermission = 0
			}

			section.add(radioGroupWithArrayOfLabelValueDictionaries: [
				["Download / View" : 0],
				["Download / View / Upload" : 1],
				["Upload only (File Drop)" : 2]
				], radioAction: { (row, _) in

					if let core = self.core {
						guard let share = self.share, let selectedValueFromSection = row.section?.selectedValue(forGroupIdentifier: "radioExample") as? Int else { return }
						core.update(share, afterPerformingChanges: {(share) in

							switch selectedValueFromSection {
							case 0:
								share.permissions = OCSharePermissionsMask.read
							case 1:
								share.permissions = OCSharePermissionsMask(rawValue: OCSharePermissionsMask.read.rawValue + OCSharePermissionsMask.update.rawValue + OCSharePermissionsMask.create.rawValue + OCSharePermissionsMask.delete.rawValue)
							case 2:
								share.permissions = OCSharePermissionsMask.create
							default:
								break
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

			}, groupIdentifier: "radioExample", selectedValue: currentPermission)

			self.addSection(section)
		}
	}

	@objc func shareLinkURL() {
		guard let share = self.share, let shareURL = share.url else { return }

		let activityViewController = UIActivityViewController(activityItems: [shareURL], applicationActivities: nil)
		activityViewController.popoverPresentationController?.sourceView = self.view
		self.present(activityViewController, animated: true, completion: nil)
	}
}
