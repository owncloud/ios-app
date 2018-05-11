//
//  UnlockPasscodeManager.swift
//  ownCloud
//
//  Created by Javier Gonzalez on 06/05/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK
import LocalAuthentication

let DateHomeButtonPressedKey = "date-home-button-pressed"

class UnlockPasscodeManager: NSObject {

    // MARK: - Biometrical status
    enum BiometricalStatus {
        case notShown
        case shown
        case error
    }

    private var passcodeViewController: PasscodeViewController?
    private var userDefaults: UserDefaults?
    private var biometricalStatus:BiometricalStatus?

    var hanlder:PasscodeHandler?

    static var sharedUnlockPasscodeManager : UnlockPasscodeManager = {
        let sharedInstance = UnlockPasscodeManager()
        let biometricalStatus = BiometricalStatus.notShown
        return (sharedInstance)
    }()

    public override init() {
        self.userDefaults = UserDefaults.standard

        super.init()
    }

    // MARK: - Unlock device

    func showPasscodeIfNeeded(viewController: UIViewController, hiddenOverlay:Bool) {
        if isPasscodeActivated() {

            storeDateHomeButtonPressed()

            if self.passcodeViewController == nil {

                hanlder = {
                    DispatchQueue.main.async {
                        self.userDefaults?.removeObject(forKey: DateHomeButtonPressedKey)
                        self.passcodeViewController?.dismiss(animated: true, completion: nil)
                        self.passcodeViewController = nil
                    }
                }

                self.passcodeViewController = PasscodeViewController(mode: PasscodeInterfaceMode.unlockPasscode, hiddenOverlay:false, handler: hanlder)
                viewController.present(self.passcodeViewController!, animated: true, completion: nil)
            } else {
                self.passcodeViewController?.showOverlay()
            }
        }
    }

    // MARK: - Interface updates

    private func hideOverlay() {
        if self.passcodeViewController != nil {
            self.passcodeViewController?.hideOverlay()
        }
    }

    func dismissAskedPasscodeIfDateToAskIsLower() {

        if !isNeccesaryShowPasscode() {
            if self.passcodeViewController != nil {
                self.passcodeViewController?.dismiss(animated: true, completion: nil)
                self.passcodeViewController = nil
                self.userDefaults?.removeObject(forKey: DateHomeButtonPressedKey)
            }
        } else {
            hideOverlay()
            self.authenticateUser(hanlder: self.hanlder!)
        }
    }

    // MARK: - Utils

    private func isPasscodeActivated() -> Bool {

        var output: Bool = true

        if OCAppIdentity.shared().keychain.readDataFromKeychainItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath) == nil {

            output = false
        }

        return output
    }

    private func isNeccesaryShowPasscode() -> Bool {

        var output: Bool = true

        if isPasscodeActivated() {
            if let dateData = self.userDefaults?.data(forKey: DateHomeButtonPressedKey) {
                if let date = NSKeyedUnarchiver.unarchiveObject(with: dateData) as? Date {

                    let elapsedSeconds = Date().timeIntervalSince(date)
                    let minSecondsToAsk = self.userDefaults?.integer(forKey: SecuritySettingsFrequencyKey)

                    if Int(elapsedSeconds) < minSecondsToAsk! {
                        output = false
                    }
                }
            }
        } else {
            output = false
        }

        return output
    }
    
    func storeDateHomeButtonPressed() {
        if OCAppIdentity.shared().keychain.readDataFromKeychainItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath) != nil,
            self.userDefaults?.data(forKey: DateHomeButtonPressedKey) == nil {
            self.userDefaults?.set(NSKeyedArchiver.archivedData(withRootObject: Date()), forKey: DateHomeButtonPressedKey)
        }
    }

    // MARK: - Biometrical

    public func authenticateUser(hanlder: @escaping PasscodeHandler) {
        // Get the local authentication context.
        let context = LAContext()

        // Set the reason string that will appear on the authentication alert.
        let reasonString = "Unlock".localized

        // Declare a NSError variable.
        var error: NSError?

        // Check if the device can evaluate the policy.
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString) { (success, error) in
                if success {
                    hanlder()
                } else {
                    
                    if let error = error {
                        switch error {
                        case LAError.authenticationFailed:  // iOS 8.0+
                            print("Authentication failed")
                        case LAError.passcodeNotSet:        // iOS 8.0+
                            print("Passcode not set")
                        case LAError.systemCancel:          // iOS 8.0+
                            print("Authentication was canceled by system")
                        case LAError.userCancel:            // iOS 9.0+
                            print("Authentication was canceled by the user")
                        case LAError.biometryNotEnrolled:   // iOS 11.0+
                            print("Authentication could not start because you haven't enrolled either Touch ID or Face ID on your device.")
                        case LAError.biometryNotAvailable:  // iOS 11.0+
                            print("Authentication could not start because Touch ID / Face ID is not available.")
                        case LAError.userFallback:          // iOS 8.0+
                            print("User tapped the fallback button (Enter Password).")
                        default:
                            print(error.localizedDescription)
                        }
                    }
                }
            }
        }
    }
}
