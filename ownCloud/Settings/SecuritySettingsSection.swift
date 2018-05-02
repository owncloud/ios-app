//
//  SecurityGlobalSettings.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 30/04/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import LocalAuthentication

private let SecuritySettingsFrecuencyKey: String =  "security-settings-frecuency"
private let SecurityPasscodeKey: String = "security-settings-usePasscode"

enum SecurityAskFrecuency: String {
    case allways = "Allways"
    case oneMinute = "1 minute"
    case fiveMinutes = "5 minutes"
    case thirtyMinutes = "30 minutes"

    static let all = [allways, oneMinute, fiveMinutes, thirtyMinutes]
}

class SecuritySettings: NSObject {

    // MARK: Security settings properties

    /// Time between avery ask for security
    private var frecuency: SecurityAskFrecuency
    /// Passcode protection enabled
    private var passcodeEnabled: Bool
    /// Biometrical protection enabled
    private var biometricalSecurityEnabled: Bool
    /// UserDefaults used to store and retrieve all.
    private var userDefaults: UserDefaults

    var section: StaticTableViewSection

    init(userDefaults: UserDefaults) {

        self.userDefaults = userDefaults

        if let frecuencySetting = userDefaults.string(forKey: SecuritySettingsFrecuencyKey), let frecuencyValue = SecurityAskFrecuency(rawValue: frecuencySetting) {
            self.frecuency = frecuencyValue
        } else {
            self.frecuency = .allways
        }
        self.passcodeEnabled = userDefaults.bool(forKey: SecurityPasscodeKey)
        self.biometricalSecurityEnabled = userDefaults.bool(forKey: "security-settings-useBiometrical")

        section = StaticTableViewSection(headerTitle: "Security".localized, footerTitle: nil)

        super.init()

        updateUI()
    }

    // MARK: Creation of the rows.
    @discardableResult
    private func frecuencyRow() -> StaticTableViewRow {
        let frecuencyRow = StaticTableViewRow(subtitleRowWithAction: { (row, _) in

            if let vc: UIViewController = self.section.viewController {
                let alert: UIAlertController = UIAlertController(title: "Select the frecuency that security should be showed", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)

                for frecuency in SecurityAskFrecuency.all {
                    let action: UIAlertAction = UIAlertAction(title: frecuency.rawValue, style: UIAlertActionStyle.default, handler: { (_) in
                        self.frecuency = frecuency
                        self.userDefaults.set(frecuency.rawValue, forKey: SecuritySettingsFrecuencyKey)
                        row.cell?.detailTextLabel?.text = frecuency.rawValue
                    })
                    alert.addAction(action)
                }

                let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel".localized, style: UIAlertActionStyle.cancel, handler: nil)
                alert.addAction(cancelAction)

                vc.present(alert, animated: true)

            }

        }, title: "Frecuency", subtitle:frecuency.rawValue, accessoryType: .disclosureIndicator, identifier: "security-frecuency-row")

        return frecuencyRow
    }

    @discardableResult
    private func passcodeRow() -> StaticTableViewRow {
        let passcodeRow = StaticTableViewRow(switchWithAction: { (row, _) in
            self.passcodeEnabled = row.value as! Bool
            self.userDefaults.set(self.passcodeEnabled, forKey: SecurityPasscodeKey)
            self.updateUI()
        }, title: "Passcode Lock", value: self.passcodeEnabled, identifier: "security-passcode-row")

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

            let biometricalRow = StaticTableViewRow(switchWithAction: { (_, _) in
                // TODO: do something
            }, title: biometricalSecurityName, value: self.biometricalSecurityEnabled, identifier: "security-biometrical-row")
            section.add(rows: [biometricalRow])

            return biometricalRow
        } else {
            return nil
        }
    }

    func updateUI() {

        if section.row(withIdentifier: "security-frecuency-row") == nil {
            let frecuencyRow = self.frecuencyRow()
            section.add(rows: [frecuencyRow])
        }

        if section.row(withIdentifier: "security-passcode-row") == nil {
            let passcodeRow = self.passcodeRow()
            section.add(rows: [passcodeRow])
        }

        if let biometricalRow = self.biometricalRow() {
            if self.passcodeEnabled == true {
                if section.row(withIdentifier: "security-biometrical-row") == nil {
                    section.add(rows: [biometricalRow])
                }
            } else {
                section.remove(rows: [biometricalRow])
            }
        }


    }
}
