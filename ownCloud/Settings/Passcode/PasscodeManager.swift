//
//  PasscodeManager.swift
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

class PasscodeManager: NSObject {

    // MARK: - Interface view mode
    enum PasscodeInterfaceMode {
        case addPasscodeFirstStep
        case addPasscodeSecondStep
        case unlockPasscode
        case unlockPasscodeError
        case deletePasscode
        case deletePasscodeError
        case addPasscodeFirstStepAfterErrorOnSecond
    }

    // MARK: Global vars

    //Common vars
    private let passcodeLength = 4
    private let passcodeKeychainAccount = "passcode-keychain-account"
    private let passcodeKeychainPath = "passcode-keychain-path"
    private var passcodeMode: PasscodeInterfaceMode?
    private var passcodeViewController: PasscodeViewController?

    //Add/Delete vars
    private var passcodeFromFirstStep: String?
    private var completionHandler: CompletionHandler?

    //Unlock vars
    private var datePressedHomeButton: Date?
    private var userDefaults: UserDefaults?

    var isPasscodeActivated: Bool {
        return (self.userDefaults!.bool(forKey: SecuritySettingsPasscodeKey) && isPasscodeStoredOnKeychain)
    }

    var isPasscodeStoredOnKeychain: Bool {
        return (OCAppIdentity.shared().keychain.readDataFromKeychainItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath) != nil)
    }

    private var shouldBeLocked: Bool {
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

    // MARK: - Init

    static var sharedPasscodeManager = PasscodeManager()

    public override init() {
        self.userDefaults = UserDefaults.standard

        super.init()
    }

    // MARK: - Show Passcode View

    func showPasscodeIfNeeded(viewController: UIViewController, hiddenOverlay:Bool) {

        if isPasscodeActivated {
            if self.passcodeViewController == nil {

                self.completionHandler = {
                    self.passcodeViewController?.dismiss(animated: true, completion: nil)
                    self.passcodeViewController = nil
                    self.datePressedHomeButton = nil
                }

                self.passcodeMode = .unlockPasscode

                self.passcodeViewController = PasscodeViewController(hiddenOverlay:hiddenOverlay)
                viewController.present(self.passcodeViewController!, animated: false, completion: nil)
                self.updateUI()

            } else {
                self.passcodeViewController?.showOverlay()
            }
        }
    }

    func showAddOrEditPasscode(viewController: UIViewController?, completionHandler: @escaping CompletionHandler) {

        if isPasscodeActivated {
            self.passcodeMode = PasscodeInterfaceMode.deletePasscode
        } else {
            self.passcodeMode = PasscodeInterfaceMode.addPasscodeFirstStep
        }

        self.completionHandler = completionHandler

        self.passcodeViewController = PasscodeViewController(hiddenOverlay:true)
        viewController?.present(self.passcodeViewController!, animated: true, completion: nil)
        self.updateUI()
    }

    // MARK: - Interface updates

    private func updateUI() {

        var messageText : String?
        var errorText : String? = ""

        switch self.passcodeMode {
        case .addPasscodeFirstStep?:
            messageText = "Enter code".localized

        case .addPasscodeSecondStep?:
            messageText = "Repeat code".localized

        case .unlockPasscode?:
            messageText = "Enter code".localized
            self.passcodeViewController?.cancelButton?.isHidden = true

        case .unlockPasscodeError?:
            messageText = "Enter code".localized
            errorText = "Incorrect code".localized
            self.passcodeViewController?.cancelButton?.isHidden = true

        case .deletePasscode?:
            messageText = "Delete code".localized

        case .deletePasscodeError?:
            messageText = "Delete code".localized
            errorText = "Incorrect code".localized

        case .addPasscodeFirstStepAfterErrorOnSecond?:
            messageText = "Enter code".localized
            errorText = "The entered codes are different".localized

        default:
            break
        }

        self.passcodeViewController?.passcodeValueTextField?.text = nil
        self.passcodeViewController?.messageLabel?.text = messageText
        self.passcodeViewController?.errorMessageLabel?.text = errorText
    }

    func dismissAskedPasscodeIfDateToAskIsLower() {

        if shouldBeLocked {
            self.passcodeViewController?.hideOverlay()
        } else {
            if self.passcodeViewController != nil {
                self.passcodeViewController?.dismiss(animated: true, completion: nil)
                self.passcodeViewController = nil
                self.datePressedHomeButton = nil
            }
        }
    }

    func cancelButtonTaped() {
        self.passcodeViewController?.dismiss(animated: true, completion: self.completionHandler)
        self.passcodeViewController = nil
    }

    // MARK: - Logic

    func passcodeValueHasChange(passcodeValue: String) {

        if passcodeValue.count >= passcodeLength {

            switch self.passcodeMode {
            case .addPasscodeFirstStep?, .addPasscodeFirstStepAfterErrorOnSecond?:
                self.passcodeMode = .addPasscodeSecondStep
                self.passcodeFromFirstStep = passcodeValue
                self.updateUI()

            case .addPasscodeSecondStep?:
                if passcodeFromFirstStep == passcodeValue {
                    //Save to keychain
                    OCAppIdentity.shared().keychain.write(NSKeyedArchiver.archivedData(withRootObject: passcodeValue), toKeychainItemForAccount: passcodeKeychainAccount, path: passcodeKeychainPath)
                    self.passcodeViewController?.dismiss(animated: true, completion: self.completionHandler!)
                    self.passcodeViewController = nil
                } else {
                    self.passcodeMode = .addPasscodeFirstStepAfterErrorOnSecond
                    self.passcodeFromFirstStep = nil
                    self.updateUI()
                }

            case .unlockPasscode?, .unlockPasscodeError?:

                let passcodeData = OCAppIdentity.shared().keychain.readDataFromKeychainItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath)
                let passcodeFromKeychain = NSKeyedUnarchiver.unarchiveObject(with: passcodeData!) as? String

                if passcodeValue == passcodeFromKeychain {
                    self.completionHandler!()
                } else {
                    self.passcodeMode = .unlockPasscodeError
                    self.updateUI()
                }

            case .deletePasscode?, .deletePasscodeError?:

                let passcodeData = OCAppIdentity.shared().keychain.readDataFromKeychainItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath)
                let passcodeFromKeychain = NSKeyedUnarchiver.unarchiveObject(with: passcodeData!) as? String

                if passcodeValue == passcodeFromKeychain {
                    OCAppIdentity.shared().keychain.removeItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath)
                    self.passcodeViewController?.dismiss(animated: true, completion: self.completionHandler!)
                    self.passcodeViewController = nil
                } else {
                    self.passcodeMode = .deletePasscodeError
                    self.updateUI()
                }
            default:
                break
            }
        }
    }

    // MARK: - Utils

    func storeDateHomeButtonPressed() {
        if self.isPasscodeActivated, self.datePressedHomeButton == nil {
            self.datePressedHomeButton = Date()
        }
    }
}
