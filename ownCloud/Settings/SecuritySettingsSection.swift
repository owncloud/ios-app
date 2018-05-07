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
public let SecuritySettingsfrequencyKey: String =  "security-settings-frequency"
public let SecuritySettingsPasscodeKey: String = "security-settings-usePasscode"
public let SecuritySettingsBiometricalKey: String = "security-settings-useBiometrical"

// MARK: - Section identifier
private let SecuritySectionIdentifier: String = "settings-security-section"

// MARK: - SecurityAskfrequency
enum SecurityAskfrequency: Int {
    case allways = 0
    case oneMinute = 60
    case fiveMinutes = 300
    case thirtyMinutes = 1800

    static let all = [allways, oneMinute, fiveMinutes, thirtyMinutes]

    func toString() -> String {
        switch self {
        case .allways:
            return "Allways".localized
        case .oneMinute:
            return "1 minute".localized
        case .fiveMinutes:
            return "5 minutes".localized
        case .thirtyMinutes:
            return "30 minutes".localized
        }
    }
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

    // MARK: - Upload Settings Cells

    private var frequencyRow: StaticTableViewRow?
    private var passcodeRow: StaticTableViewRow?
    private var biometricalRow: StaticTableViewRow?

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults

        if let frequencyValue = SecurityAskfrequency(rawValue: userDefaults.integer(forKey: SecuritySettingsfrequencyKey)) {
            self.frequency = frequencyValue
        } else {
            self.frequency = .allways
        }
        self.passcodeEnabled = userDefaults.bool(forKey: SecuritySettingsPasscodeKey)
        self.biometricalSecurityEnabled = userDefaults.bool(forKey: SecuritySettingsBiometricalKey)

        super.init()
        self.headerTitle = "Security".localized
        self.identifier = SecuritySectionIdentifier

        createRows()

        updateUI()
    }

    // MARK: - Creation of the rows.
    private func createRows() {
        frequencyRow = StaticTableViewRow(subtitleRowWithAction: { (row, _) in

            if let vc: StaticTableViewController = self.viewController {
                let alert: UIAlertController =
                    UIAlertController(title: "Select the frequency that security should be showed".localized,
                                      message: nil,
                                      preferredStyle: UIAlertControllerStyle.actionSheet)

                for frequency in SecurityAskfrequency.all {
                    let action: UIAlertAction = UIAlertAction(title: frequency.toString(), style: UIAlertActionStyle.default, handler: { (_) in
                        self.frequency = frequency
                        self.userDefaults.set(frequency.rawValue, forKey: SecuritySettingsfrequencyKey)
                        row.cell?.detailTextLabel?.text = frequency.toString()
                    })
                    alert.addAction(action)
                }

                let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel".localized, style: UIAlertActionStyle.cancel, handler: nil)
                alert.addAction(cancelAction)

                vc.present(alert, animated: true)
            }

        }, title: "Frequency".localized, subtitle:frequency.toString(), accessoryType: .disclosureIndicator)

        passcodeRow = StaticTableViewRow(switchWithAction: { (row, _) in
            if let value = row.value as? Bool {
                self.passcodeEnabled = value
                self.userDefaults.set(self.passcodeEnabled, forKey: SecuritySettingsPasscodeKey)
                self.updateUI()
            }
        }, title: "Passcode Lock".localized, value: self.passcodeEnabled)

        let context = LAContext()

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) {

            var biometricalSecurityName = ""
            switch context.biometryType {
            case .touchID:
                biometricalSecurityName = "TouchID".localized
            case .faceID:
                biometricalSecurityName = "FaceID".localized
            default:
                break
            }

            biometricalRow = StaticTableViewRow(switchWithAction: { (row, _) in
                if let value = row.value as? Bool {
                    self.biometricalSecurityEnabled = value
                    self.userDefaults.set(self.biometricalSecurityEnabled, forKey: SecuritySettingsBiometricalKey)
                }
            }, title: biometricalSecurityName, value: self.biometricalSecurityEnabled)
        }
    }

    // MARK: - Update UI
    func updateUI() {

        if !rows.contains(frequencyRow!) {
            add(row: frequencyRow!)
        }

        if !rows.contains(passcodeRow!) {
            add(row: passcodeRow!)
        }

        if self.passcodeEnabled == true {
            if !rows.contains(biometricalRow!) {
                add(row: biometricalRow!)
            }
        } else {
            self.biometricalRow?.value = false
            self.biometricalSecurityEnabled = false
            self.remove(biometricalRow!)
        }
    }
}
