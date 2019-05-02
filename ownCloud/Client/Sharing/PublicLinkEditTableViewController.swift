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
	var showSubtitles : Bool = false

	override func viewDidLoad() {
		super.viewDidLoad()

		self.navigationItem.title = share?.name!

		let infoButton = UIButton(type: .infoLight)
		infoButton.addTarget(self, action: #selector(showInfoSubtitles), for: .touchUpInside)
		let infoBarButtonItem = UIBarButtonItem(customView: infoButton)
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
							let alertController = UIAlertController(with: "Setting name failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
							self.present(alertController, animated: true)
						}
					}
				})
			}
		}, placeholder: "Public Link".localized, value: (share?.name!)!, secureTextEntry: false, keyboardType: .default, autocorrectionType: .default, enablesReturnKeyAutomatically: true, returnKeyType: .default, identifier: "Name")

		section.add(row: nameRow)


		self.addSection(section)

		loadPermissionRow()


		var hasPassword = false
		if share?.password != nil {
			hasPassword = true
		}

		let passwordSection = StaticTableViewSection(headerTitle: "Password", footerTitle: nil, identifier: "permission-section")
		let passwordRow = StaticTableViewRow(switchWithAction: { (row, _) in

		}, title: "Protect with password".localized, value: hasPassword, identifier: "PasswordRow")
		passwordSection.add(row: passwordRow)
		if hasPassword {
			let expireDateRow = StaticTableViewRow(secureTextFieldWithAction: { (row, value) in

			}, placeholder: "Password".localized, value: (share?.password!)!, keyboardType: .default, enablesReturnKeyAutomatically: true, returnKeyType: .default, identifier: "Identifier")
			passwordSection.add(row: expireDateRow)
		}
		self.addSection(passwordSection)

		var hasExpireDate = false
		if let expirationDate = share?.expirationDate {
			hasExpireDate = true
		}

		let expireSection = StaticTableViewSection(headerTitle: "Expire Date", footerTitle: nil, identifier: "expire-section")
		let expireDateRow = StaticTableViewRow(switchWithAction: { (_, sender) in
			if let expireDateSwitch = sender as? UISwitch {
				if expireDateSwitch.isEnabled, let expireDateRow = expireSection.row(withIdentifier: "expireDateRow") {
					expireSection.remove(rows: [expireDateRow], animated: true)
				} else if expireDateSwitch.isEnabled {

					if let row = self.expireDateRow(expireSection) {
						expireSection.add(row: row)
					}

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
								let alertController = UIAlertController(with: "Setting expiration date failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
								self.present(alertController, animated: true)
							}
						}
					})
				}



			}



		}, title: "Link has expire date".localized, value: hasExpireDate, identifier: "ExpireRow")
		expireSection.add(row: expireDateRow)

		if hasExpireDate {
			if let row = self.expireDateRow(expireSection) {
				expireSection.add(row: row)
			}

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

	func expireDateRow(_ expireSection : StaticTableViewSection) -> StaticTableViewRow? {

		if let date = share?.expirationDate {
			let dateFormatter = DateFormatter()
			dateFormatter.dateStyle = .long
			dateFormatter.timeStyle = .none
			let expireDateRow = StaticTableViewRow(buttonWithAction: { (row, value) in

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
										let alertController = UIAlertController(with: "Setting expiration date failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
										self.present(alertController, animated: true)
									}
								}
							})
						}



					}, date: date, identifier: "datePickerRow")
					expireSection.add(row: datePickerRow, animated: true)
				} else {
					if let datePickerRow = expireSection.row(withIdentifier: "datePickerRow") {
						expireSection.remove(rows: [datePickerRow], animated: true)
					}
				}
			}, title: dateFormatter.string(from: date), style: .plain, alignment: .left, identifier: "expireDateRow")


			return expireDateRow
		}

		return nil
	}

	func loadPermissionRow() {

		let section = StaticTableViewSection(headerTitle: "Permissions".localized, footerTitle: nil, identifier: "permission-section")
		guard let share = share else { return }
		var permissions : [[String: Bool]] = []
		var permissionValues : [OCSharePermissionsMask] = []
		var subtitles : [String]?

		if share.itemType == .collection {
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
			/*
			section.add(toogleGroupWithArrayOfLabelValueDictionaries: permissions, toggleAction: { (row, _) in
			guard let selected = row.value as? Bool else { return }
			if let core = self.core {
			core.update(share, afterPerformingChanges: {(share) in
			if let rowIndex = row.index {
			guard permissionValues.indices.contains(rowIndex) else { return }
			let permissionValue = permissionValues[rowIndex]

			if selected {
			share.permissions.insert(permissionValue)
			} else {
			share.permissions.remove(permissionValue)
			}
			}
			}, completionHandler: { (error, share) in
			if error == nil {
			guard let changedShare = share else { return }
			self.share?.permissions = changedShare.permissions
			} else {
			if let shareError = error {
			let alertController = UIAlertController(with: "Setting permission failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
			self.present(alertController, animated: true)
			}
			}
			})
			}
			}, subtitles: subtitles, groupIdentifier: "preferences-section", selectedValue:true)
			*/

			section.add(radioGroupWithArrayOfLabelValueDictionaries: [
				["Download / View" : "value-of-line-1"],
				["Download / View / Upload" : "value-of-line-2"],
				["Upload only (File Drop)" : "value-of-line-3"]
				], radioAction: { (row, _) in
					let selectedValueFromSection = row.section?.selectedValue(forGroupIdentifier: "radioExample")

					Log.log("Radio value for \(row.groupIdentifier!) changed to \(row.value!)")
					Log.log("Values can also be read from the section object: \(selectedValueFromSection!)")
			}, groupIdentifier: "radioExample", selectedValue: "value-of-line-2")


			self.addSection(section)

		}
	}

	@objc func showInfoSubtitles() {
		showSubtitles.toggle()
		guard let removeSection = self.sectionForIdentifier("permission-section") else { return }
		self.removeSection(removeSection)
		loadPermissionRow()
	}
}
