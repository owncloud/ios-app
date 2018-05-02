//
//  SecurityGlobalSettings.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 30/04/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import LocalAuthentication

// MARK: - Security UserDefaults keys
private let SecuritySettingsfrequencyKey: String =  "security-settings-frequency"
private let SecurityPasscodeKey: String = "security-settings-usePasscode"
private let SecurityBiometricalKey: String = "security-settings-useBiometrical"

// MARK: - Section key
private let SecuritySectionIdentifier: String = "settings-security-section"

// MARK: - Row keys
private let SecurityFrequencyRowIdentifier: String = "security-frequency-row"
private let SecurityPasscodeRowIdentifier: String = "security-passcode-row"
private let SecurityBiometricsRowIdentifier: String = "security-biometrical-row"

// MARK: - SecurityAskfrequency
enum SecurityAskfrequency: String {
    case allways = "Allways"
    case oneMinute = "1 minute"
    case fiveMinutes = "5 minutes"
    case thirtyMinutes = "30 minutes"

    static let all = [allways, oneMinute, fiveMinutes, thirtyMinutes]
}

class SecuritySettings: StaticTableViewSection {

    // MARK: - Security settings properties

    /// Time between avery ask for security
    private var frequency: SecurityAskfrequency
    /// Passcode protection enabled
    private var passcodeEnabled: Bool
    /// Biometrical protection enabled
    private var biometricalSecurityEnabled: Bool
    /// UserDefaults used to store and retrieve all.
    private var userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults

        if let frequencySetting = userDefaults.string(forKey: SecuritySettingsfrequencyKey), let frequencyValue = SecurityAskfrequency(rawValue: frequencySetting) {
            self.frequency = frequencyValue
        } else {
            self.frequency = .allways
        }
        self.passcodeEnabled = userDefaults.bool(forKey: SecurityPasscodeKey)
        self.biometricalSecurityEnabled = userDefaults.bool(forKey: SecurityBiometricalKey)

        super.init()
        self.headerTitle = "Security".localized
        self.identifier = SecuritySectionIdentifier

        updateUI()
    }

    // MARK: - Creation of the rows.
    @discardableResult
    private func frequencyRow() -> StaticTableViewRow {
        let frequencyRow = StaticTableViewRow(subtitleRowWithAction: { (row, _) in

            if let vc: StaticTableViewController = self.viewController {
                let alert: UIAlertController =
                    UIAlertController(title: "Select the frequency that security should be showed".localized,
                                      message: nil,
                                      preferredStyle: UIAlertControllerStyle.actionSheet)

                for frequency in SecurityAskfrequency.all {
                    let action: UIAlertAction = UIAlertAction(title: frequency.rawValue, style: UIAlertActionStyle.default, handler: { (_) in
                        self.frequency = frequency
                        self.userDefaults.set(frequency.rawValue, forKey: SecuritySettingsfrequencyKey)
                        row.cell?.detailTextLabel?.text = frequency.rawValue
                    })
                    alert.addAction(action)
                }

                let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel".localized, style: UIAlertActionStyle.cancel, handler: nil)
                alert.addAction(cancelAction)

                alert.view.translatesAutoresizingMaskIntoConstraints = false
                vc.present(alert, animated: true)

            }

        }, title: "Frequency".localized, subtitle:frequency.rawValue, accessoryType: .disclosureIndicator, identifier: SecurityFrequencyRowIdentifier)

        return frequencyRow
    }

    @discardableResult
    private func passcodeRow() -> StaticTableViewRow {
        let passcodeRow = StaticTableViewRow(switchWithAction: { (row, _) in
            self.passcodeEnabled = row.value as! Bool
            self.userDefaults.set(self.passcodeEnabled, forKey: SecurityPasscodeKey)
            self.updateUI()
        }, title: "Passcode Lock".localized, value: self.passcodeEnabled, identifier: SecurityPasscodeRowIdentifier)

        return passcodeRow
    }

    @discardableResult
    private func biometricalRow() -> StaticTableViewRow? {
        let context = LAContext()

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) {

            var biometricalSecurityName = ""
            switch context.biometryType {
            case .touchID:
                biometricalSecurityName = "TouchID".localized
            case .faceID:
                biometricalSecurityName = "FaceID".localized
            default:
                return nil
            }

            let biometricalRow = StaticTableViewRow(switchWithAction: { (row, _) in
                self.biometricalSecurityEnabled = row.value as! Bool
                self.userDefaults.set(self.biometricalSecurityEnabled, forKey: SecurityBiometricalKey)
            }, title: biometricalSecurityName, value: self.biometricalSecurityEnabled, identifier: SecurityBiometricsRowIdentifier)
            return biometricalRow
        } else {
            return nil
        }
    }

    // MARK: - Update UI
    func updateUI() {

        if self.row(withIdentifier: SecurityFrequencyRowIdentifier) == nil {
            let frequencyRow = self.frequencyRow()
            self.add(rows: [frequencyRow])
        }

        if self.row(withIdentifier: SecurityPasscodeRowIdentifier) == nil {
            let passcodeRow = self.passcodeRow()
            self.add(rows: [passcodeRow])
        }

        if self.passcodeEnabled == true {
            if self.row(withIdentifier: SecurityBiometricsRowIdentifier) == nil,
                let biometricalRow = self.biometricalRow() {
                self.add(rows: [biometricalRow])
            }
        } else {
            if let row = self.row(withIdentifier: SecurityBiometricsRowIdentifier) {
                self.remove(rows: [row])
            }
        }

        self.reload()
    }
}
