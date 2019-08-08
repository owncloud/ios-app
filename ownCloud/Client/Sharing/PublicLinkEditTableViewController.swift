//
//  PublicLinkEditTableViewController.swift
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

class PublicLinkEditTableViewController: StaticTableViewController {

	// MARK: - Instance Variables
	var share : OCShare
	var core : OCCore
	var item : OCItem
	var defaultLinkName : String

	var showSubtitles : Bool = false
	var createLink : Bool = false
	var permissionMask : OCSharePermissionsMask?
	var activeTextField: UITextField?
	var currentPermissionIndex: Int {
		if createLink {
			return 0
		} else {
			if share.canUpdate {
				return 1
			} else if share.canCreate, share.canUpdate == false {
				return 2
			}
			return 0
		}
	}

	lazy var inputToolbar: UIToolbar = {
		var toolbar = UIToolbar()
		toolbar.barStyle = .default
		toolbar.isTranslucent = true
		toolbar.sizeToFit()
		let doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(resignTextField))
		let flexibleSpaceBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
		toolbar.setItems([flexibleSpaceBarButtonItem, doneBarButtonItem], animated: false)
		toolbar.isUserInteractionEnabled = true
		return toolbar
	}()

	// MARK: - Init

	internal init(share: OCShare, core: OCCore, item: OCItem, defaultLinkName: String) {
		self.share = share
		self.core = core
		self.item = item
		self.defaultLinkName = defaultLinkName
		super.init(style: .grouped)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		if let linkName = share.name {
			self.navigationItem.title = linkName
		}

		let shareBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareLinkURL))
		if item.type == .collection {
			let infoButton = UIButton(type: .infoLight)
			infoButton.addTarget(self, action: #selector(showInfoSubtitles), for: .touchUpInside)
			let infoBarButtonItem = UIBarButtonItem(customView: infoButton)
			let flexibleSpaceBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
			if createLink {
				self.toolbarItems = [flexibleSpaceBarButtonItem, infoBarButtonItem]
			} else {
				self.toolbarItems = [shareBarButtonItem, flexibleSpaceBarButtonItem, infoBarButtonItem]
			}
		} else if !createLink {
			self.toolbarItems = [shareBarButtonItem]
		}

		self.navigationController?.toolbar.isTranslucent = false
		self.navigationController?.isToolbarHidden = false

		addNameSection()
		addPermissionsSection()
		preparePasswordSection(for: currentPermissionIndex)
		addExpireDateSection()

		if createLink {
			let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissAnimated))
			self.navigationItem.leftBarButtonItem = cancel

			let create = UIBarButtonItem(title: "Create".localized, style: .done, target: self, action: #selector(createPublicLink))
			self.navigationItem.rightBarButtonItem = create

			permissionMask = .read
		} else {
			addActionSection()
		}
	}

	// MARK: - Name Section

	func addNameSection() {
		let section = StaticTableViewSection(headerTitle: "Name".localized, footerTitle: nil, identifier: "name-section")

		var linkName = ""
		if let savedLinkName = share.name {
			linkName = savedLinkName
		}

		let nameRow = StaticTableViewRow(textFieldWithAction: { [weak self] (row, sender, action) in
			if let self = self, !self.createLink, action == .changed {
				guard let newName = row.textField?.text else { return }
				var linkName = newName
				if linkName.count == 0 {
					linkName = self.defaultLinkName
					row.textField?.text = linkName
				}
				self.core.update(self.share, afterPerformingChanges: {(share) in
					share.name = linkName
				}, completionHandler: { (error, share) in
					if error == nil {
						guard let changedShare = share else { return }
						self.share.name = changedShare.name
						self.title = changedShare.name
					} else {
						if let shareError = error {
							OnMainThread {
								let alertController = UIAlertController(with: "Setting name failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
								self.present(alertController, animated: true)
							}
						}
					}
				})
			} else if action == .didBegin {
				if let textField = sender as? UITextField {
					self?.activeTextField = textField
				}
			}
			}, placeholder: "Public Link".localized, value: linkName, secureTextEntry: false, keyboardType: .default, autocorrectionType: .default, enablesReturnKeyAutomatically: true, returnKeyType: .done, inputAccessoryView: inputToolbar, identifier: "name-text-row", actionEvent: UIControl.Event.editingDidEnd)

		section.add(row: nameRow)
		self.addSection(section)
	}

	// MARK: - Permission Section

	func addPermissionsSection() {
		let section = StaticTableViewSection(headerTitle: "Permissions".localized, footerTitle: nil, identifier: "permission-section")

		if item.type == .collection {

			let values = [
				["Download / View".localized : 0],
				["Download / View / Upload".localized : 1],
				["Upload only (File Drop)".localized : 2]
			]

			section.add(radioGroupWithArrayOfLabelValueDictionaries: values, radioAction: { [weak self] (row, _) in
				if let self = self {
					guard let selectedValueFromSection = row.section?.selectedValue(forGroupIdentifier: "permission-group") as? Int else { return }

					var newPermissions : OCSharePermissionsMask = OCSharePermissionsMask(rawValue: 0)
					switch selectedValueFromSection {
					case 0:
						newPermissions = .read
					case 1:
						newPermissions = [.read, .update, .create, .delete]
					case 2:
						newPermissions = .create
					default:
						break
					}

					if self.createLink {
						self.permissionMask = newPermissions
						self.preparePasswordSection(for: selectedValueFromSection)
					} else {
						if self.canPerformPermissionChange(for: selectedValueFromSection) {

							self.preparePasswordSection(for: selectedValueFromSection)

							self.core.update(self.share, afterPerformingChanges: {(share) in
								share.permissions = newPermissions
							}, completionHandler: { [weak self] (error, share) in
								guard let self = self else { return }
								if error == nil {
									guard let changedShare = share else { return }
									self.share.permissions = changedShare.permissions
								} else {
									if let shareError = error {
										OnMainThread {
											let alertController = UIAlertController(with: "Setting permission failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
											self.present(alertController, animated: true)
										}
									}
								}
							})
						} else {
							// set selection back to previous selected value
							row.section?.setSelected(self.currentPermissionIndex, groupIdentifier: "permission-group")
							let permissionName = Array(values[selectedValueFromSection])[0].key

							let alertController = UIAlertController(with: "Cannot change permission".localized, message: String(format: "Before you can set the permission\n%@,\n you must enter a password.".localized, permissionName), okLabel: "OK".localized, action: nil)
							self.present(alertController, animated: true)
						}
					}
				}
				}, groupIdentifier: "permission-group", selectedValue: currentPermissionIndex)

			let subtitles = [
				"Recipients can view or download contents.".localized,
				"Recipients can view, download, edit, delete and upload contents.".localized,
				"Receive files from multiple recipients without revealing the contents of the folder.".localized
			]

			var subtitleIndex = 0
			for row in section.rows {
				if showSubtitles {
					row.cell?.detailTextLabel?.text = subtitles[subtitleIndex]
				} else {
					row.cell?.detailTextLabel?.text = ""
				}
				subtitleIndex += 1
			}

			self.insertSection(section, at: 1)
		}
	}

	// MARK: - Password Section

	func preparePasswordSection(for selectionIndex : Int) {
		let needsPassword = passwordRequired(for: selectionIndex)
		var hasPassword = false
		if share.protectedByPassword {
			hasPassword = true
		}

		if self.sectionForIdentifier("password-section") == nil {
			let passwordSection = StaticTableViewSection(headerTitle: "Options".localized, footerTitle: nil, identifier: "password-section")
			self.addSection(passwordSection)
		}

		if let passwordSection = self.sectionForIdentifier("password-section") {
			if needsPassword {
				if let passwordSwitchRow = passwordSection.row(withIdentifier: "password-switch-row") {
					passwordSection.remove(rows: [passwordSwitchRow], animated: false)
				}

				if passwordSection.row(withIdentifier: "password-field-row") == nil {
					self.passwordRow(passwordSection)
				}
			} else {
				if let passwordSwitchRow = passwordSection.row(withIdentifier: "password-switch-row") {
					if let switchView = passwordSwitchRow.cell?.accessoryView as? UISwitch {
						switchView.isOn = hasPassword
					}
				} else {
					self.passwordSwitchRow(hasPassword, passwordSection)
				}

				if hasPassword == false, let passwordFieldRow = passwordSection.row(withIdentifier: "password-field-row") {
					passwordSection.remove(rows: [passwordFieldRow], animated: false)
				} else if hasPassword, passwordSection.row(withIdentifier: "password-field-row") == nil {
					self.passwordRow(passwordSection)
				}
			}
		}
	}

	func passwordSwitchRow(_ hasPassword : Bool, _ passwordSection : StaticTableViewSection) {
		let passwordRow = StaticTableViewRow(switchWithAction: { [weak self, weak passwordSection] (_, sender) in
			if let self = self, let passwordSwitch = sender as? UISwitch {
				if passwordSwitch.isOn == false, let passwordSection = passwordSection, let passwordFieldRow = passwordSection.row(withIdentifier: "password-field-row") {
					passwordSection.remove(rows: [passwordFieldRow], animated: true)

					// delete password
					if !self.createLink {
						self.core.update(self.share, afterPerformingChanges: { (share) in
							share.protectedByPassword = false
						}, completionHandler: { (error, share) in
							if error == nil {
								guard let changedShare = share else { return }
								self.share.protectedByPassword = changedShare.protectedByPassword
							} else {
								if let shareError = error {
									OnMainThread {
										let alertController = UIAlertController(with: "Deleting password failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
										self.present(alertController, animated: true)
									}
								}
							}
						})
					}
				} else if passwordSwitch.isOn, let passwordSection = passwordSection {
					self.passwordRow(passwordSection)
				}
			}
		}, title: "Password".localized, value: hasPassword, identifier: "password-switch-row")
		passwordSection.insert(row: passwordRow, at: 0, animated: true)
	}

	func passwordRow(_ passwordSection : StaticTableViewSection) {
		var passwordValue = ""
		if let password = share.password {
			passwordValue = password
		}

		let expireDateRow = StaticTableViewRow(secureTextFieldWithAction: { [weak self] (_, sender, action) in
			if action == .changed, let self = self {
				guard let textField = sender as? UITextField else { return }
				if !self.createLink {
					self.core.update(self.share, afterPerformingChanges: {(share) in
						share.password = textField.text
						share.protectedByPassword = true
					}, completionHandler: { [weak self] (error, share) in
						guard let self = self else { return }
						if error == nil {
							guard let changedShare = share else { return }
							self.share.password = changedShare.password
							self.share.protectedByPassword = changedShare.protectedByPassword
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
			} else if action == .didBegin {
				if let textField = sender as? UITextField {
					self?.activeTextField = textField
				}
			}

		}, placeholder: "Type to update password".localized, value: passwordValue, keyboardType: .default, enablesReturnKeyAutomatically: true, returnKeyType: .done, inputAccessoryView: inputToolbar, identifier: "password-field-row", actionEvent: UIControl.Event.editingDidEnd)
		passwordSection.add(row: expireDateRow)
	}

	// MARK: - Expire Date Section

	func addExpireDateSection() {
		var hasExpireDate = false
		if share.expirationDate != nil || core.connection.capabilities?.publicSharingExpireDateEnforced == true {
			hasExpireDate = true
		}

		if self.createLink && self.core.connection.capabilities?.publicSharingDefaultExpireDateDays != nil {
			hasExpireDate = true
		}

		var needsExpireDate = false
		if self.core.connection.capabilities?.publicSharingExpireDateEnforced == true {
			needsExpireDate = true
		}

		let expireSection = StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: "expire-section")

		if needsExpireDate == false {
			let expireDateRow = StaticTableViewRow(switchWithAction: { [weak self, weak expireSection] (_, sender) in
				if let self = self, let expireSection = expireSection, let expireDateSwitch = sender as? UISwitch {
					if expireDateSwitch.isOn == false, let expireDateRow = expireSection.row(withIdentifier: "expire-date-row") {
						var rows : [StaticTableViewRow] = [expireDateRow]
						if let expireDatePickerRow = expireSection.row(withIdentifier: "date-picker-row") {
							rows.append(expireDatePickerRow)
						}
						expireSection.remove(rows: rows, animated: true)
					} else if expireDateSwitch.isOn, expireSection.row(withIdentifier: "expire-date-row") == nil {
						self.expireDateRow(expireSection)
					}

					if !self.createLink {
						self.core.update(self.share, afterPerformingChanges: {(share) in
							if expireDateSwitch.isOn {
								if let datePicker = sender as? UIDatePicker {
									share.expirationDate = datePicker.date
								} else {
									share.expirationDate = self.defaultExpireDate
								}
							} else {
								share.expirationDate = nil
							}
						}, completionHandler: { [weak self] (error, share) in
							guard let self = self else { return }
							if error == nil {
								guard let changedShare = share else { return }
								self.share.expirationDate = changedShare.expirationDate

								if let expireDateRow = expireSection.row(withIdentifier: "expire-date-row"), let expirationDate = changedShare.expirationDate {
									OnMainThread {
										let dateFormatter = DateFormatter()
										dateFormatter.dateStyle = .medium
										dateFormatter.timeStyle = .none
										expireDateRow.cell?.textLabel?.text = dateFormatter.string(from: expirationDate)
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
					} else if self.createLink {
						if let row = self.rowInSection(expireSection, rowIdentifier: "expire-date-row") {
							row.representedObject = self.defaultExpireDate
						}
					}
				}
			}, title: "Expiration date".localized, value: hasExpireDate, identifier: "expire-row")
			expireSection.add(row: expireDateRow)
		}

		if hasExpireDate || needsExpireDate {
			self.expireDateRow(expireSection)
		}
		self.addSection(expireSection)
	}

	func expireDateRow(_ expireSection : StaticTableViewSection) {
		let expireDate = defaultExpireDate

		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .long
		dateFormatter.timeStyle = .none
		let expireDateRow = StaticTableViewRow(buttonWithAction: { [weak self, weak expireSection] (_, _) in
			guard let expireSection = expireSection else { return }

			if expireSection.row(withIdentifier: "date-picker-row") == nil {

				let datePickerRow = StaticTableViewRow(datePickerWithAction: { [weak self] (row, sender) in

					guard let datePicker = sender as? UIDatePicker else { return }
					if let expireDateRow = expireSection.row(withIdentifier: "expire-date-row") {
						OnMainThread {
							expireDateRow.cell?.textLabel?.text = dateFormatter.string(from: datePicker.date)
							expireDateRow.representedObject = datePicker.date
						}
					}

					if let self = self, !self.createLink {
						self.core.update(self.share, afterPerformingChanges: { (share) in
							share.expirationDate = datePicker.date
						}, completionHandler: { [weak self] (error, share) in
							guard let self = self else { return }
							if error == nil {
								guard let changedShare = share else { return }
								self.share.expirationDate = changedShare.expirationDate

								if let expireDateRow = expireSection.row(withIdentifier: "expire-date-row") {
									OnMainThread {
										expireDateRow.cell?.textLabel?.text = dateFormatter.string(from: datePicker.date)
										expireDateRow.representedObject = datePicker.date
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
				}, date: expireDate, identifier: "date-picker-row")
				expireSection.add(row: datePickerRow, animated: true)
				if let indexPath = datePickerRow.indexPath {
					self?.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
				}
			} else {
				if let datePickerRow = expireSection.row(withIdentifier: "date-picker-row") {
					expireSection.remove(rows: [datePickerRow], animated: true)
				}
			}
		}, title: dateFormatter.string(from: expireDate), style: .plain, alignment: .left, identifier: "expire-date-row")

		expireDateRow.representedObject = expireDate
		expireSection.add(row: expireDateRow)
	}

	// MARK: - Action Section

	func addActionSection() {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .short
		var footer = ""
		if let date = share.creationDate {
			footer = String(format: "Created: %@".localized, dateFormatter.string(from: date))
		}

		let deleteSection = StaticTableViewSection(headerTitle: "Public Link".localized, footerTitle: footer)

		if let shareURL = share.url {
			deleteSection.add(rows: [
				StaticTableViewRow(buttonWithAction: { (row, _) in
					UIPasteboard.general.url = shareURL
					row.cell?.textLabel?.text = shareURL.absoluteString
					row.cell?.textLabel?.font = UIFont.systemFont(ofSize: 15.0)
					row.cell?.textLabel?.textColor = Theme.shared.activeCollection.tableRowColors.secondaryLabelColor
					row.cell?.textLabel?.numberOfLines = 0
					DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
						row.cell?.textLabel?.text = "Copy Public Link".localized
						row.cell?.textLabel?.font = UIFont.systemFont(ofSize: 17.0)
						row.cell?.textLabel?.textColor = Theme.shared.activeCollection.tintColor
						row.cell?.textLabel?.numberOfLines = 1
					}
				}, title: "Copy Public Link".localized, style: .plain)
				])
		}

		deleteSection.add(rows: [
			StaticTableViewRow(buttonWithAction: { [weak self] (row, _) in
				let progressView = UIActivityIndicatorView(style: Theme.shared.activeCollection.activityIndicatorViewStyle)
				progressView.startAnimating()

				row.cell?.accessoryView = progressView
				if let self = self {
					self.core.delete(self.share, completionHandler: { [weak self] (error) in
						guard let self = self else { return }
						OnMainThread {
							if error == nil {
								self.navigationController?.popViewController(animated: true)
							} else {
								if let shareError = error {
									let alertController = UIAlertController(with: "Deleting Public Link failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
									self.present(alertController, animated: true)
								}
							}
						}
					})
				}
			}, title: "Delete".localized, style: StaticTableViewRowButtonStyle.destructive)
			])

		self.addSection(deleteSection)
	}

	// MARK: - Actions

	@objc func showInfoSubtitles() {
		showSubtitles.toggle()
		guard let removeSection = self.sectionForIdentifier("permission-section") else { return }
		self.removeSection(removeSection)
		addPermissionsSection()
	}

	@objc func shareLinkURL() {
		guard let shareURL = share.url, let capabilities = self.core.connection.capabilities else { return }

		let activityViewController = UIActivityViewController(activityItems: [shareURL], applicationActivities: nil)
		if capabilities.publicSharingSocialShare == false {
			activityViewController.excludedActivityTypes = [
				UIActivity.ActivityType.postToTwitter,
				UIActivity.ActivityType.postToVimeo,
				UIActivity.ActivityType.postToWeibo,
				UIActivity.ActivityType.postToFlickr,
				UIActivity.ActivityType.postToFacebook,
				UIActivity.ActivityType.postToTencentWeibo,
				UIActivity.ActivityType("com.facebook.Facebook")
			]
		}
		activityViewController.popoverPresentationController?.sourceView = self.view
		self.present(activityViewController, animated: true, completion: nil)
	}

	// MARK: - Permission Helper

	func canPerformPermissionChange(for selectionIndex : Int) -> Bool {
		if share.protectedByPassword == false, passwordRequired(for: selectionIndex) {
			return false
		}

		return true
	}

	// MARK: - Password Helper

	func passwordRequired(for selectionIndex: Int) -> Bool {
		guard let capabilities = self.core.connection.capabilities else { return false }

		if selectionIndex == 0, capabilities.publicSharingPasswordEnforcedForReadOnly == true {
			return true
		} else if selectionIndex == 1, capabilities.publicSharingPasswordEnforcedForReadWrite == true {
			return true
		} else if selectionIndex == 2, capabilities.publicSharingPasswordEnforcedForUploadOnly == true {
			return true
		}

		return false
	}

	// MARK: Add New Link Share

	@objc func createPublicLink() {
		let nameRow = rowInSection(sectionForIdentifier("name-section"), rowIdentifier: "name-text-row")
		let shareName = nameRow?.textField?.text
		let passwordRow = rowInSection(sectionForIdentifier("password-section"), rowIdentifier: "password-field-row")
		let password = passwordRow?.textField?.text
		let dateRow = rowInSection(sectionForIdentifier("expire-section"), rowIdentifier: "expire-date-row")
		var expiration : Date?
		if let date = dateRow?.representedObject as? Date {
			expiration = date
		}

		if let permissionMask = permissionMask {
			let share = OCShare(publicLinkToPath: self.share.itemPath, linkName: shareName, permissions: permissionMask, password: password, expiration: expiration)
			self.core.createShare(share, options: nil, completionHandler: { (error, _) in
				if error == nil {
					OnMainThread {
						self.dismissAnimated()
					}
				} else {
					if let shareError = error {
						OnMainThread {
							let alertController = UIAlertController(with: "Creating public link failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
							self.present(alertController, animated: true)
						}
					}
				}
			})
		}
	}

	@objc func resignTextField (_ sender: UIBarButtonItem) {
		activeTextField?.resignFirstResponder()
	}

	var defaultExpireDate : Date {
		var expireDate = Date()
		if let newDate = Calendar.current.date(byAdding: .day, value: 7, to: expireDate) {
			expireDate = newDate
		}
		if let date = share.expirationDate {
			expireDate = date
		} else if self.core.connection.capabilities?.publicSharingExpireDateEnabled == true, let defaultDays = self.core.connection.capabilities?.publicSharingDefaultExpireDateDays {
			if let newDate = Calendar.current.date(byAdding: .day, value: defaultDays.intValue, to: Date()) {
				expireDate = newDate
			}
		}

		return expireDate
	}
}
