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

    // Common
    private let passcodeLength = 4
    private let passcodeKeychainAccount = "passcode-keychain-account"
    private let passcodeKeychainPath = "passcode-keychain-path"
    private var passcodeMode: PasscodeInterfaceMode?
    private var passcodeViewController: PasscodeViewController?

    // Add/Delete
    private var passcodeFromFirstStep: String?
    private var completionHandler: CompletionHandler?

    // Unlock
    private var datePressedHomeButton: Date?
    private var userDefaults: UserDefaults?

    // Brute force protection
    public let TimesPasscodeFailedKey: String =  "times-passcode-failed"
    public let DateAllowTryPasscodeAgainKey: String =  "date-allow-try-passcode-again"
    private var timesPasscodeFailed: Int {
        didSet {
            self.userDefaults!.set(timesPasscodeFailed, forKey: TimesPasscodeFailedKey)
        }
    }
    private var dateAllowTryAgain: Date? {
        didSet {
            self.userDefaults!.set(NSKeyedArchiver.archivedData(withRootObject: dateAllowTryAgain as Any), forKey: DateAllowTryPasscodeAgainKey)
        }
    }
    private let timesAllowPasscodeFail: Int = 3
    private let multiplierBruteForce: Int = 10
    private var timerBruteForce: Timer?

    // Utils
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

        // Brute Force protection
        self.timesPasscodeFailed = self.userDefaults!.integer(forKey: TimesPasscodeFailedKey)
        if let data = self.userDefaults!.data(forKey: DateAllowTryPasscodeAgainKey) {
            self.dateAllowTryAgain = NSKeyedUnarchiver.unarchiveObject(with: data) as? Date
        }

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
                    self.timesPasscodeFailed = 0
                }

                self.passcodeViewController = PasscodeViewController(hiddenOverlay:hiddenOverlay)
                viewController.present(self.passcodeViewController!, animated: false, completion: nil)

                // Brute force protection
                if let date = self.dateAllowTryAgain, date > Date() {
                    //User killed the app
                    self.passcodeMode = .unlockPasscodeError
                    self.passcodeViewController?.setEnableNumberButtons(isEnable: false)
                    self.scheduledTimerToUpdateInterfaceTime()
                } else {
                    self.passcodeMode = .unlockPasscode
                }

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

        self.passcodeViewController?.passcodeValueTextField?.text = ""
        self.passcodeViewController?.messageLabel?.text = messageText
        self.passcodeViewController?.errorMessageLabel?.text = errorText
        self.passcodeViewController?.timeTryAgainMessageLabel?.text = ""
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

    // MARK: - Brute force protection

    func scheduledTimerToUpdateInterfaceTime() {

        DispatchQueue.main.async {
            self.updatePasscodeInterfaceTime()
        }

        self.timerBruteForce = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updatePasscodeInterfaceTime), userInfo: nil, repeats: true)
    }

    @objc func updatePasscodeInterfaceTime() {

        let interval = Int((self.dateAllowTryAgain?.timeIntervalSinceNow)!)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)

        let dateFormated:String?
        if hours > 0 {
            dateFormated = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            dateFormated = String(format: "%02d:%02d", minutes, seconds)
        }

        let text:String = NSString(format: "Please try again within %@".localized as NSString, dateFormated!) as String
        self.passcodeViewController?.timeTryAgainMessageLabel?.text = text

        if self.dateAllowTryAgain! <= Date() {
            //Time elapsed, allow enter passcode again
            self.timer?.invalidate()
            self.passcodeViewController?.setEnableNumberButtons(isEnable: true)
            self.updateUI()
        }
    }

    func getSecondsToTryAgain() -> Int {
        let powValue = pow(Decimal(multiplierBruteForce), ((timesPasscodeFailed+1) - timesAllowPasscodeFail))
        return Int(truncating: NSDecimalNumber(decimal: powValue))
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
                    // Shake
                    self.passcodeViewController?.view.shakeHorizontally()
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
                    // Shake
                    self.passcodeViewController?.view.shakeHorizontally()
                    self.passcodeMode = .unlockPasscodeError
                    self.updateUI()

                    // Brute force protection
                    self.timesPasscodeFailed += 1
                    if self.timesPasscodeFailed >= self.timesAllowPasscodeFail {
                        self.passcodeViewController?.setEnableNumberButtons(isEnable: false)
                        self.dateAllowTryAgain = Date().addingTimeInterval(TimeInterval(self.getSecondsToTryAgain()))
                        self.scheduledTimerToUpdateInterfaceTime()
                    }
                }

            case .deletePasscode?, .deletePasscodeError?:

                let passcodeData = OCAppIdentity.shared().keychain.readDataFromKeychainItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath)
                let passcodeFromKeychain = NSKeyedUnarchiver.unarchiveObject(with: passcodeData!) as? String

                if passcodeValue == passcodeFromKeychain {
                    OCAppIdentity.shared().keychain.removeItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath)
                    self.passcodeViewController?.dismiss(animated: true, completion: self.completionHandler!)
                    self.passcodeViewController = nil
                } else {
                    // Shake
                    self.passcodeViewController?.view.shakeHorizontally()
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
