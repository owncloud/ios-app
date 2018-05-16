//
//  UnlockPasscodeManager.swift
//  ownCloud
//
//  Created by Javier Gonzalez on 06/05/2018.
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
import ownCloudSDK

class UnlockPasscodeManager: NSObject {

    // MARK: - Utils

    private var isPasscodeActivated: Bool {
        return (OCAppIdentity.shared().keychain.readDataFromKeychainItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath) != nil)
    }

    private var shouldBeLocke: Bool {
        var output: Bool = true

        if isPasscodeActivated {
            if let date = self.datePressedHomeButton {

                let elapsedSeconds = Date().timeIntervalSince(date)
                let minSecondsToAsk = self.userDefaults?.integer(forKey: SecuritySettingsFrequencyKey)

                if Int(elapsedSeconds) < minSecondsToAsk! {
                    output = false
                }
            }
        } else {
            output = false
        }

        return output
    }

    // MARK: Global vars

    private var passcodeViewController: PasscodeViewController?
    private var datePressedHomeButton: Date?
    private var userDefaults: UserDefaults?

    // MARK: - Init

    static var sharedUnlockPasscodeManager = UnlockPasscodeManager()

    public override init() {
        self.userDefaults = UserDefaults.standard

        super.init()
    }

    // MARK: - Unlock device

    func showPasscodeIfNeeded(viewController: UIViewController, hiddenOverlay:Bool) {

        if isPasscodeActivated() {
            if self.passcodeViewController == nil {
                self.passcodeViewController = PasscodeViewController(mode: PasscodeInterfaceMode.unlockPasscode, hiddenOverlay:hiddenOverlay, completionHandler: {
                    self.passcodeViewController?.dismiss(animated: true, completion: nil)
                    self.passcodeViewController = nil
                    self.datePressedHomeButton = nil
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
                self.datePressedHomeButton = nil
            }
        }
    }

    // MARK: - Utils

    func storeDateHomeButtonPressed() {
        if self.isPasscodeActivated(), self.datePressedHomeButton == nil {
            self.datePressedHomeButton = Date()
        }
    }
}
