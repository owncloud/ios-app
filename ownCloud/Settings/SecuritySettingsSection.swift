//
//  SecuritySettingsSection.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 30/04/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2018, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import LocalAuthentication
import ownCloudSDK
import ownCloudAppShared

// MARK: - SecurityAskfrequency
@objc enum SecurityAskFrequency: Int, CaseIterable {
	case always = 0
	case oneMinute = 60
	case fiveMinutes = 300
	case thirtyMinutes = 1800

	func toString() -> String {
		switch self {
		case .always:
			return "Immediately".localized
		case .oneMinute:
			return "After 1 minute".localized
		case .fiveMinutes:
			return "After 5 minutes".localized
		case .thirtyMinutes:
			return "After 30 minutes".localized
		}
	}
}

class SecuritySettingsSection: SettingsSection {

	var frequency: SecurityAskFrequency {
		get {
			if ProcessInfo.processInfo.arguments.contains("UI-Testing") {
				return .always
			} else {
				return SecurityAskFrequency.init(rawValue: AppLockManager.shared.lockDelay) ?? .always
			}
		}
		set(newValue) {
			AppLockManager.shared.lockDelay = newValue.rawValue
		}
	}

	var isBiometricalSecurityEnabled: Bool {
		get {
			if ProcessInfo.processInfo.arguments.contains("UI-Testing") {
				return true
			} else {
				return AppLockManager.shared.biometricalSecurityEnabled
			}
		}
		set(newValue) {
			AppLockManager.shared.biometricalSecurityEnabled = newValue
		}
	}

	private var passcodeFromFirstStep: String?

	// MARK: - Passcode Settings Cells

	private var frequencyRow: StaticTableViewRow?
	private var passcodeRow: StaticTableViewRow?
	private var biometricalRow: StaticTableViewRow?
	private var certificateManagementRow: StaticTableViewRow?

	override init(userDefaults: UserDefaults) {
		super.init(userDefaults: userDefaults)

		self.headerTitle = "Security".localized
		self.identifier = "settings-security-section"

		createRows()
		updateUI()

		NotificationCenter.default.addObserver(self, selector: #selector(_updateUI), name: NSNotification.Name.OCCertificateUserAcceptanceDidChange, object: nil)
	}

	deinit {
    		NotificationCenter.default.removeObserver(self, name: NSNotification.Name.OCCertificateUserAcceptanceDidChange, object: nil)
	}

	// MARK: - Creation of the rows.
	func createRows() {

		// Creation of the frequency row.
		frequencyRow = StaticTableViewRow(subtitleRowWithAction: { [weak self] (row, _) in
			if let vc = self?.viewController {

				let newVC = StaticTableViewController(style: .grouped)
				newVC.title = "Lock application".localized
				let frequencySection = StaticTableViewSection(headerTitle: "Lock application".localized, footerTitle: "If you choose \"Immediately\" the App will be locked, when it is no longer in foreground.".localized)

				var radioButtons: [[String : Any]] = []

				for frequency in SecurityAskFrequency.allCases {
					radioButtons.append([frequency.toString() : frequency.rawValue])
				}

				frequencySection.add(radioGroupWithArrayOfLabelValueDictionaries: radioButtons, radioAction: { (row, _) in
					if let rawFrequency = row.value! as? Int, let frequency = SecurityAskFrequency.init(rawValue: rawFrequency) {
						self?.frequency = frequency
						self?.frequencyRow?.cell?.detailTextLabel?.text = frequency.toString()
					}
				}, groupIdentifier: "frequency-group-identifier", selectedValue: self!.frequency.rawValue, animated: true)

				newVC.addSection(frequencySection)
				vc.navigationController?.pushViewController(newVC, animated: true)
			}

		}, title: "Lock application".localized, subtitle: frequency.toString(), accessoryType: .disclosureIndicator, identifier: "lockFrequency")

		// Creation of the passcode row.
		passcodeRow = StaticTableViewRow(switchWithAction: { [weak self] (row, sender) in

			guard let passcodeSwitch = sender as? UISwitch, let viewController = row.viewController  else { return }

			let action: PasscodeAction = passcodeSwitch.isOn ? .setup : .delete
			PasscodeSetupCoordinator(parentViewController: viewController, action: action, completion: { (cancelled) in
				if cancelled {
					passcodeSwitch.isOn = !passcodeSwitch.isOn
				} else {
					self?.updateUI()
				}

			}).start()

			}, title: "Passcode Lock".localized, value: PasscodeSetupCoordinator.isPasscodeSecurityEnabled, identifier: "passcodeSwitchIdentifier")

		// Creation of the biometrical row.
		if let biometricalSecurityName = LAContext().supportedBiometricsAuthenticationName() {
			biometricalRow = StaticTableViewRow(switchWithAction: { (row, sender) in
				guard let biometricalSwitch = sender as? UISwitch, let viewController = row.viewController else { return }

				PasscodeSetupCoordinator(parentViewController: viewController, completion: { (cancelled) in
					if cancelled {
						biometricalSwitch.isOn = !biometricalSwitch.isOn
					} else {
						biometricalSwitch.isOn = PasscodeSetupCoordinator.isBiometricalSecurityEnabled
					}
				}).startBiometricalFlow(biometricalSwitch.isOn)

			}, title: biometricalSecurityName, value: isBiometricalSecurityEnabled, identifier: "BiometricalSwitch")
		}

		// Creation of certificate management row
		certificateManagementRow = StaticTableViewRow(rowWithAction: { (row, _) in
			let certificateManagementViewController = CertificateManagementViewController(style: UITableView.Style.grouped)

			row.viewController?.navigationController?.pushViewController(certificateManagementViewController, animated: true)
		}, title: "Certificates".localized, accessoryType: .disclosureIndicator, identifier: "Certificates")
	}

	// MARK: - Update UI
	@objc func _updateUI() {
		OnMainThread {
			self.updateUI()
		}
	}

	@objc func updateUI() {
		var rowsToAdd: [StaticTableViewRow] = []
		var rowsToRemove: [StaticTableViewRow] = []

		if !AppLockManager.shared.isPasscodeEnforced {
			if !rows.contains(passcodeRow!) {
				rowsToAdd.append(passcodeRow!)
			}
		}

		if PasscodeSetupCoordinator.isPasscodeSecurityEnabled {
			if !rows.contains(frequencyRow!) {
				rowsToAdd.append(frequencyRow!)
			}

			if biometricalRow != nil, !rows.contains(biometricalRow!) {
				rowsToAdd.append(biometricalRow!)
			}
		} else {

			frequencyRow?.cell?.detailTextLabel?.text = SecurityAskFrequency.always.toString()
			frequency = .always

			rowsToRemove.append(frequencyRow!)

			if biometricalRow != nil {
				biometricalRow?.value = false
				rowsToRemove.append(biometricalRow!)
			}
		}

		if (OCCertificate.userAcceptedCertificates?.count ?? 0) > 0 {
			if rows.contains(certificateManagementRow!) {
				if rowsToAdd.count > 0 {
					rowsToRemove.append(certificateManagementRow!)
					rowsToAdd.append(certificateManagementRow!)
				}
			} else {
				rowsToAdd.append(certificateManagementRow!)
			}
		} else {
			if rows.contains(certificateManagementRow!) {
				rowsToRemove.append(certificateManagementRow!)
			}
		}

		if (rowsToAdd.count > 0) || (rowsToRemove.count > 0) {
			if rowsToRemove.count > 0 {
				self.remove(rows: rowsToRemove, animated: true)
			}

			if rowsToAdd.count > 0 {
				self.add(rows: rowsToAdd, animated: true)
			}
		}

		passcodeRow?.value = PasscodeSetupCoordinator.isPasscodeSecurityEnabled
	}
}
