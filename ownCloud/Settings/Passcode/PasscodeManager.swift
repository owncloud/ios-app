//
//  PasscodeUtilities.swift
//  ownCloud
//
//  Created by Javier Gonzalez on 06/05/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

let DateHomeButtonPressedKey = "date-home-button-pressed"

class PasscodeManager: NSObject {

    private var passcodeViewController: PasscodeViewController?
    private var userDefaults: UserDefaults?

    static var sharedPasscodeManager : PasscodeManager = {
        let sharedInstance = PasscodeManager()
        return (sharedInstance)
    }()

    public override init() {
        super.init()
    }

    func storeDateHomeButtonPressed() {
        if OCAppIdentity.shared().keychain.readDataFromKeychainItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath) != nil,
            UserDefaults.standard.data(forKey: DateHomeButtonPressedKey) == nil {
            UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: Date()), forKey: DateHomeButtonPressedKey)
        }
    }

    func hideOverlay() {
        if self.passcodeViewController != nil {
            self.passcodeViewController?.hideOverlay()
        }
    }

    // MARK: - Unlock device

    func showPasscodeIfNeededOpenApp(viewController: UIViewController, window: UIWindow?, hiddenOverlay:Bool) {
        if self.isNeccesaryShowPasscode() {
            self.passcodeViewController = PasscodeViewController(mode: PasscodeInterfaceMode.unlockPasscode, hiddenOverlay:hiddenOverlay, handler: {
                DispatchQueue.main.async {
                    UserDefaults.standard.removeObject(forKey: DateHomeButtonPressedKey)
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

    func showPasscodeIfNeededComeFromBackground(viewController: UIViewController, hiddenOverlay:Bool) {

        PasscodeManager.sharedPasscodeManager.storeDateHomeButtonPressed()

        if self.isNeccesaryShowPasscode() {
            if self.passcodeViewController == nil {
                self.passcodeViewController = PasscodeViewController(mode: PasscodeInterfaceMode.unlockPasscode, hiddenOverlay:false, handler: {
                    DispatchQueue.main.async {
                        UserDefaults.standard.removeObject(forKey: DateHomeButtonPressedKey)
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

    func isNeccesaryShowPasscode() -> Bool {

        var output: Bool = true

        if OCAppIdentity.shared().keychain.readDataFromKeychainItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath) != nil {
            if let dateData = UserDefaults.standard.data(forKey: DateHomeButtonPressedKey) {
                if let date = NSKeyedUnarchiver.unarchiveObject(with: dateData) as? Date {

                    let elapsedSeconds = Date().timeIntervalSince(date)
                    let secondsPassedMinToAsk = UserDefaults.standard.integer(forKey: SecuritySettingsfrequencyKey)

                    if Int(elapsedSeconds) < secondsPassedMinToAsk {
                        output = true
                    }
                }
            }
        } else {
            output = false
        }

        return output
    }

    func dismissAskedPasscodeIfDateToAskIsLower() {

        let secondsPassedMinToAsk = UserDefaults.standard.integer(forKey: SecuritySettingsfrequencyKey)

        if let dateData = UserDefaults.standard.data(forKey: DateHomeButtonPressedKey) {
            if let date = NSKeyedUnarchiver.unarchiveObject(with: dateData) as? Date {
                let elapsed = Date().timeIntervalSince(date)

                if Int(elapsed) < secondsPassedMinToAsk {
                    if self.passcodeViewController != nil {
                        self.passcodeViewController?.dismiss(animated: true, completion: nil)
                        self.passcodeViewController = nil
                        UserDefaults.standard.removeObject(forKey: DateHomeButtonPressedKey)
                    }
                }
            }
        }

        self.passcodeViewController?.hideOverlay()
    }
}
