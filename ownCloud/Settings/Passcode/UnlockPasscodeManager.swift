//
//  UnlockPasscodeManager.swift
//  ownCloud
//
//  Created by Javier Gonzalez on 06/05/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

let DateHomeButtonPressedKey = "date-home-button-pressed"

class UnlockPasscodeManager: NSObject {

    private func isPasscodeActivated() -> Bool {
        return (OCAppIdentity.shared().keychain.readDataFromKeychainItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath) != nil)
    }

    private func shouldBeLocked() -> Bool {
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

    private var passcodeViewController: PasscodeViewController?
    private var userDefaults: UserDefaults?

    static var sharedUnlockPasscodeManager : UnlockPasscodeManager = {
        let sharedInstance = UnlockPasscodeManager()
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
                self.passcodeViewController = PasscodeViewController(mode: PasscodeInterfaceMode.unlockPasscode, hiddenOverlay:false, completionHandler: {
                    DispatchQueue.main.async {
                        self.userDefaults?.removeObject(forKey: DateHomeButtonPressedKey)
                        viewController.dismiss(animated: true, completion: nil)
                        self.passcodeViewController = nil
                    }
                })

                viewController.present(self.passcodeViewController!, animated: false, completion: nil)
            } else {
                self.passcodeViewController?.showOverlay()
            }
        }
    }

    // MARK: - Interface updates

    func dismissAskedPasscodeIfDateToAskIsLower() {

        if shouldBeLocked() {
            self.passcodeViewController?.hideOverlay()
        } else {
            if self.passcodeViewController != nil {
                self.passcodeViewController?.dismiss(animated: true, completion: nil)
                self.passcodeViewController = nil
                self.userDefaults?.removeObject(forKey: DateHomeButtonPressedKey)
            }
        }
    }

    // MARK: - Utils

    func storeDateHomeButtonPressed() {
        if OCAppIdentity.shared().keychain.readDataFromKeychainItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath) != nil,
            self.userDefaults?.data(forKey: DateHomeButtonPressedKey) == nil {
            self.userDefaults?.set(NSKeyedArchiver.archivedData(withRootObject: Date()), forKey: DateHomeButtonPressedKey)
        }
    }
}
