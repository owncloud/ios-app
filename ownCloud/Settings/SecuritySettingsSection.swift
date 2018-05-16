//
//  SecurityGlobalSettings.swift
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

// MARK: - Security UserDefaults keys
public let SecuritySettingsKey: String = "security-settings"
public let SecuritySettingsFrequencyKey: String =  "security-settings-frequency"
public let SecuritySettingsPasscodeKey: String = "security-settings-usePasscode"
public let SecuritySettingsBiometricalKey: String = "security-settings-useBiometrical"

// MARK: - Section identifier
private let SecuritySectionIdentifier: String = "settings-security-section"

// MARK: - SecurityAskfrequency
@objc enum SecurityAskFrequency: Int {
    case always = 0
    case oneMinute = 60
    case fiveMinutes = 300
    case thirtyMinutes = 1800

    static let all = [always, oneMinute, fiveMinutes, thirtyMinutes]

    func toString() -> String {
        switch self {
        case .always:
            return "Always".localized
        case .oneMinute:
            return "1 minute".localized
        case .fiveMinutes:
            return "5 minutes".localized
        case .thirtyMinutes:
            return "30 minutes".localized
        }
    }
}

class SecuritySettingsSection: SettingsSection {

    var frequency: SecurityAskFrequency {
        willSet {
            self.userDefaults.set(newValue.rawValue, forKey: SecuritySettingsFrequencyKey)
        }
    }

    var isPasscodeSecurityEnabled: Bool {
        willSet {
            self.userDefaults.set(newValue, forKey: SecuritySettingsPasscodeKey)
        }

        didSet {
            updateUI()
        }
    }
    var isBiometricalSecurityEnabled: Bool {
        willSet {
            self.userDefaults.set(newValue, forKey: SecuritySettingsBiometricalKey)
        }
    }

    // MARK: - Upload Settings Cells

    private var frequencyRow: StaticTableViewRow?
    private var passcodeRow: StaticTableViewRow?
    private var biometricalRow: StaticTableViewRow?

    override init(userDefaults: UserDefaults) {

        frequency = SecurityAskFrequency.init(rawValue: userDefaults.integer(forKey: SecuritySettingsFrequencyKey))!
        isPasscodeSecurityEnabled = userDefaults.bool(forKey: SecuritySettingsPasscodeKey)
        isBiometricalSecurityEnabled = userDefaults.bool(forKey: SecuritySettingsBiometricalKey)

        super.init(userDefaults: userDefaults)

        self.headerTitle = "Security".localized
        self.identifier = SecuritySectionIdentifier

        createRows()
        updateUI()
    }

    // MARK: - Creation of the rows.
    func createRows() {

        // Creation of the frequency row.
        frequencyRow = StaticTableViewRow(subtitleRowWithAction: { (row, _) in
            if let vc = self.viewController {

                let newVC = StaticTableViewController(style: .grouped)
                let frequencySection = StaticTableViewSection(headerTitle: "Select the frequency that security should be showed".localized, footerTitle: nil)

                var radioButtons: [[String : Any]] = []

                for frequency in SecurityAskFrequency.all {
                    radioButtons.append([frequency.toString() : frequency.rawValue])
                }

                frequencySection.add(radioGroupWithArrayOfLabelValueDictionaries: radioButtons, radioAction: { (row, _) in
                    if let rawFrequency = row.value! as? Int, let frequency = SecurityAskFrequency.init(rawValue: rawFrequency) {
                        self.frequency = frequency
                        self.frequencyRow?.cell?.detailTextLabel?.text = frequency.toString()
                    }
                }, groupIdentifier: "frequency-group-identifier", selectedValue: SecurityAskFrequency.always.rawValue, animated: true)

                newVC.addSection(frequencySection)
                vc.navigationController?.pushViewController(newVC, animated: true)
            }

        }, title: "Frequency".localized, subtitle: frequency.toString(), accessoryType: .disclosureIndicator)

        // Creation of the passcode row.
        passcodeRow = StaticTableViewRow(switchWithAction: { (_, sender) in
            if let passcodeSwitch = sender as? UISwitch {

                //Show the passcode UI
                UnlockPasscodeManager.sharedUnlockPasscodeManager.showAddOrEditPasscode(
                    viewController: self.viewController?.navigationController?.visibleViewController,
                    completionHandler: {
                        if UnlockPasscodeManager.sharedUnlockPasscodeManager.isPasscodeActivated {
                            //Activated
                            self.isPasscodeSecurityEnabled = true
                        } else {
                            //Cancelled
                            self.isPasscodeSecurityEnabled = false
                        }
                })

                self.isPasscodeSecurityEnabled = passcodeSwitch.isOn
                self.updateUI()
            }
        }, title: "Passcode lock".localized, value: isPasscodeSecurityEnabled)

        // Creation of the biometrical row.
        if let biometricalSecurityName = LAContext().supportedBiometricsAuthenticationNAme() {
            // Creation of the biometrical row.
            biometricalRow = StaticTableViewRow(switchWithAction: { (_, sender) in
                if let biometricalSwitch = sender as? UISwitch {
                    self.isBiometricalSecurityEnabled = biometricalSwitch.isOn
                }
            }, title: biometricalSecurityName, value: isBiometricalSecurityEnabled)
        }
    }

    // MARK: - Update UI
    func updateUI() {

        if !rows.contains(passcodeRow!) {
            add(row: passcodeRow!)
        }

        if isPasscodeSecurityEnabled {

            var rowsToAdd: [StaticTableViewRow] = []

            if !rows.contains(frequencyRow!) {
                rowsToAdd.append(frequencyRow!)
            }

            if biometricalRow != nil, !rows.contains(biometricalRow!) {
                rowsToAdd.append(biometricalRow!)
            }

            add(rows: rowsToAdd, animated: true)
        } else {

            var rowsToRemove: [StaticTableViewRow] = []
            frequencyRow?.cell?.detailTextLabel?.text = SecurityAskFrequency.always.toString()
            rowsToRemove.append(frequencyRow!)

            if biometricalRow != nil {
                biometricalRow?.value = false
                rowsToRemove.append(biometricalRow!)
            }

            remove(rows: rowsToRemove, animated: true)
        }

        passcodeRow?.value = isPasscodeSecurityEnabled
    }
}
