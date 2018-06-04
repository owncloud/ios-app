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
public let SecuritySettingsBiometricalKey: String = "security-settings-useBiometrical"

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
            return SecurityAskFrequency.init(rawValue: AppLockManager.shared.lockDelay) ?? .always
	}
        set(newValue) {
            AppLockManager.shared.lockDelay = newValue.rawValue
        }
    }

    var isPasscodeSecurityEnabled: Bool {
        get {
            return AppLockManager.shared.lockEnabled
        }
        set(newValue) {
            AppLockManager.shared.lockEnabled = newValue
            updateUI()
        }
    }
    var isBiometricalSecurityEnabled: Bool {
        willSet {
            self.userDefaults.set(newValue, forKey: SecuritySettingsBiometricalKey)
        }
    }

    private var window: AppLockWindow?
    private var passcodeFromFirstStep: String?

    // MARK: - Upload Settings Cells

    private var frequencyRow: StaticTableViewRow?
    private var passcodeRow: StaticTableViewRow?
    private var biometricalRow: StaticTableViewRow?

    override init(userDefaults: UserDefaults) {
        isBiometricalSecurityEnabled = userDefaults.bool(forKey: SecuritySettingsBiometricalKey)

        super.init(userDefaults: userDefaults)

        self.headerTitle = "Security".localized
        self.identifier = "settings-security-section"

        createRows()
        updateUI()
    }

    // MARK: - Creation of the rows.
    func createRows() {

        // Creation of the frequency row.
        frequencyRow = StaticTableViewRow(subtitleRowWithAction: { (row, _) in
            if let vc = self.viewController {

                let newVC = StaticTableViewController(style: .grouped)
                let frequencySection = StaticTableViewSection(headerTitle: "Lock application".localized, footerTitle: nil)

                var radioButtons: [[String : Any]] = []

                for frequency in SecurityAskFrequency.all {
                    radioButtons.append([frequency.toString() : frequency.rawValue])
                }

                frequencySection.add(radioGroupWithArrayOfLabelValueDictionaries: radioButtons, radioAction: { (row, _) in
                    if let rawFrequency = row.value! as? Int, let frequency = SecurityAskFrequency.init(rawValue: rawFrequency) {
                        self.frequency = frequency
                        self.frequencyRow?.cell?.detailTextLabel?.text = frequency.toString()
                    }
                }, groupIdentifier: "frequency-group-identifier", selectedValue: self.frequency.rawValue, animated: true)

                newVC.addSection(frequencySection)
                vc.navigationController?.pushViewController(newVC, animated: true)
            }

        }, title: "Lock application".localized, subtitle: frequency.toString(), accessoryType: .disclosureIndicator)

        // Creation of the passcode row.
        passcodeRow = StaticTableViewRow(switchWithAction: { (_, sender) in
            if let passcodeSwitch = sender as? UISwitch {

                self.window = AppLockWindow(frame: UIScreen.main.bounds)
                var passcodeViewController: PasscodeViewController?
                var defaultMessage : String?

                //Handlers
                let cancelHandler:PasscodeViewControllerCancelHandler = {
                    self.window?.hideWindowAnimation(completion: {
                        self.isPasscodeSecurityEnabled = !passcodeSwitch.isOn
                        self.window = nil
                    })
                    self.passcodeFromFirstStep = nil
                }

                if passcodeSwitch.isOn {
                    defaultMessage = "Enter code".localized
                } else {
                    defaultMessage = "Delete code".localized
                }

                passcodeViewController = PasscodeViewController(cancelHandler: cancelHandler, passcodeCompleteHandler: { (passcode: String) in
                    if !passcodeSwitch.isOn {
                        //Delete
                        if passcode == AppLockManager.shared.passcode {
                            //Success
                            AppLockManager.shared.passcode = nil
                            self.window?.hideWindowAnimation(completion: {
                                self.isPasscodeSecurityEnabled = passcodeSwitch.isOn
                                self.updateUI()
                                self.window = nil
                            })
                        } else {
                            //Error
                            passcodeViewController?.message = defaultMessage
                            passcodeViewController?.errorMessage = "Incorrect code".localized
                            passcodeViewController?.passcode = nil
                        }
                    } else {
                        //Add
                        if self.passcodeFromFirstStep == nil {
                            //First step
                            self.passcodeFromFirstStep = passcode
                            passcodeViewController?.message = "Repeat code".localized
                            passcodeViewController?.passcode = nil
                        } else {
                            //Second step
                            if self.passcodeFromFirstStep == passcode {
                                //Passcode righ
                                //Save to keychain
                                AppLockManager.shared.passcode = passcode
                                self.window?.hideWindowAnimation(completion: {
                                    self.isPasscodeSecurityEnabled = passcodeSwitch.isOn
                                    self.updateUI()
                                    self.window = nil
                                })
                            } else {
                                //Passcode is not the same
                                passcodeViewController?.message = defaultMessage
                                passcodeViewController?.errorMessage = "The entered codes are different".localized
                                passcodeViewController?.passcode = nil
                            }
                            self.passcodeFromFirstStep = nil
                        }
                    }
                })

                passcodeViewController?.message = defaultMessage

                self.window?.rootViewController = passcodeViewController!
                self.window?.makeKeyAndVisible()
                self.window?.showWindowAnimation()
            }
        }, title: "Passcode lock".localized, value: isPasscodeSecurityEnabled)

        // Creation of the biometrical row.
        if let biometricalSecurityName = LAContext().supportedBiometricsAuthenticationName() {
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
            frequency = .always

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
