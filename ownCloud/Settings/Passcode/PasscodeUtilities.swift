//
//  PasscodeUtilities.swift
//  ownCloud
//
//  Created by Javier Gonzalez on 06/05/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

let dateHomeButtonPressed = "DateHomeButtonPressed"
let dateHomeButtonPressedPath = "DateHomeButtonPressedPath"

class PasscodeUtilities: NSObject {

    var viewController: UIViewController?

    static var sharedPasscodeUtilities : PasscodeUtilities = {
        let sharedInstance = PasscodeUtilities()

        return (sharedInstance)
    }()

    public override init() {
        super.init()
    }

    func storeDateHomeButtonPressed() {
        if viewController != nil {
            //Only store the date if the PasscodeViewController is not shown
            let archivedTime = NSKeyedArchiver.archivedData(withRootObject: Date())
            UserDefaults.standard.set(archivedTime, forKey: dateHomeButtonPressed)
        }
    }

    // MARK: - Unlock device

    func askPasscodeIfIsActivated(viewController: UIViewController) {
        if OCAppIdentity.shared().keychain.readDataFromKeychainItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath) != nil {

            self.viewController = viewController

            let passcodeViewController:PasscodeViewController = PasscodeViewController(mode: PasscodeInterfaceMode.unlockPasscode, passcodeFromFirstStep: nil)
            viewController.present(passcodeViewController, animated: true, completion: nil)
        }
    }

    func dismissAskedPasscodeIfDateToAskIsLower() {
        
        if self.viewController != nil {
            self.viewController?.dismiss(animated: true, completion: nil)
            self.viewController = nil
        }
    }
}
