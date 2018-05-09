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

    func showPasscodeIfNeededOpenApp(viewController: UIViewController, window: UIWindow?, hiddenOverlay:Bool) {
        if isNeccesaryShowPasscode() {
            self.passcodeViewController = PasscodeViewController(mode: PasscodeInterfaceMode.unlockPasscode, hiddenOverlay:hiddenOverlay, handler: {
                DispatchQueue.main.async {
                    self.userDefaults?.removeObject(forKey: DateHomeButtonPressedKey)
                    window?.rootViewController = viewController
                    window?.addSubview((viewController.view)!)
                    self.passcodeViewController = nil
                }
            })
            window?.rootViewController = self.passcodeViewController

        } else {
            window?.rootViewController = viewController
            window?.addSubview((viewController.view)!)
        }
    }

    func showPasscodeIfNeededAfterHomeButtonPressed(viewController: UIViewController, hiddenOverlay:Bool) {

        if isPasscodeActivated() {

            storeDateHomeButtonPressed()

            if self.passcodeViewController == nil {
                self.passcodeViewController = PasscodeViewController(mode: PasscodeInterfaceMode.unlockPasscode, hiddenOverlay:false, handler: {
                    DispatchQueue.main.async {
                        self.userDefaults?.removeObject(forKey: DateHomeButtonPressedKey)
                        viewController.dismiss(animated: true, completion: nil)
                        self.passcodeViewController = nil
                    }
                })

                viewController.present(self.passcodeViewController!, animated: true, completion: nil)
            } else {
                self.passcodeViewController?.showOverlay()
            }
        }
    }

    // MARK: - Interface updates

    func hideOverlay() {
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
        }
    }

    // MARK: - Utils

    func isPasscodeActivated() -> Bool {

        var output: Bool = true

        if OCAppIdentity.shared().keychain.readDataFromKeychainItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath) == nil {

            output = false
        }

        return output
    }

    func isNeccesaryShowPasscode() -> Bool {

        var output: Bool = true

        if isPasscodeActivated() {
            if let dateData = self.userDefaults?.data(forKey: DateHomeButtonPressedKey) {
                if let date = NSKeyedUnarchiver.unarchiveObject(with: dateData) as? Date {

                    let elapsedSeconds = Date().timeIntervalSince(date)
                    let minSecondsToAsk = self.userDefaults?.integer(forKey: SecuritySettingsfrequencyKey)

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
}
