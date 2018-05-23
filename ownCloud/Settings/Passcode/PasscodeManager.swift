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
import LocalAuthentication

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

    // MARK: - Biometrical status
    enum BiometricalStatus {
        case notShown
        case shown
        case success
        case error
    }

    // MARK: Global vars

    // Common
    private var window: LockWindow?
    private let passcodeLength = 4
    private let passcodeKeychainAccount = "passcode-keychain-account"
    private let passcodeKeychainPath = "passcode-keychain-path"
    private var passcodeMode: PasscodeInterfaceMode?
    private var passcodeViewController: PasscodeViewController?
    private var biometricalStatus:BiometricalStatus

    // Add/Delete
    private var passcodeFromFirstStep: String?
    private var completionHandler: CompletionHandler?

    // Unlock
    private var dateApplicationWillResignActive: Date?
    private var userDefaults: UserDefaults

    // Brute force protection
    public let TimesPasscodeFailedKey: String =  "times-passcode-failed"
    public let DateAllowTryPasscodeAgainKey: String =  "date-allow-try-passcode-again"
    private var timesPasscodeFailed: Int {
        didSet {
            self.userDefaults.set(timesPasscodeFailed, forKey: TimesPasscodeFailedKey)
        }
    }
    private var dateAllowTryAgain: Date? {
        didSet {
            self.userDefaults.set(NSKeyedArchiver.archivedData(withRootObject: dateAllowTryAgain as Any), forKey: DateAllowTryPasscodeAgainKey)
        }
    }
    private let timesAllowPasscodeFail: Int = 3
    private let multiplierBruteForce: Int = 10
    private var timerBruteForce: Timer?

    // Utils
    var isPasscodeActivated: Bool {
        return (self.userDefaults.bool(forKey: SecuritySettingsPasscodeKey) && isPasscodeStoredOnKeychain)
    }

    var isPasscodeStoredOnKeychain: Bool {
        return (OCAppIdentity.shared().keychain.readDataFromKeychainItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath) != nil)
    }

    private var passcodeFromKeychain: String? {
        if let passcodeData = OCAppIdentity.shared().keychain.readDataFromKeychainItem(
            forAccount: passcodeKeychainAccount, path: passcodeKeychainPath) {
            return NSKeyedUnarchiver.unarchiveObject(with: passcodeData) as? String
        } else {
            return nil
        }
    }

    private var shouldBeLocked: Bool {
        var output: Bool = true

        if isPasscodeActivated {
            if let date = self.dateApplicationWillResignActive {

                let elapsedSeconds = Date().timeIntervalSince(date)
                let minSecondsToAsk = self.userDefaults.integer(forKey: SecuritySettingsFrequencyKey)

                if Int(elapsedSeconds) < minSecondsToAsk {
                    output = false
                }
            }
        } else {
            output = false
        }

        return output
    }

    // MARK: - Init

    static var shared = PasscodeManager()

    public override init() {
        // TODO: Use OCAppIdentity-provided user defaults in the future
        self.userDefaults = UserDefaults(suiteName: OCAppIdentity.shared().appGroupIdentifier) ?? UserDefaults.standard

        // Brute Force protection
        self.timesPasscodeFailed = self.userDefaults.integer(forKey: TimesPasscodeFailedKey)
        if let data = self.userDefaults.data(forKey: DateAllowTryPasscodeAgainKey) {
            self.dateAllowTryAgain = NSKeyedUnarchiver.unarchiveObject(with: data) as? Date
        }

        // Biometrical
        self.biometricalStatus = BiometricalStatus.notShown

        super.init()
    }

    // MARK: - Show Passcode View

    func showPasscodeIfNeeded(hiddenOverlay:Bool) {

        if isPasscodeActivated {
            if self.passcodeViewController == nil {

                self.completionHandler = {
                    self.dateApplicationWillResignActive = nil
                    self.timesPasscodeFailed = 0
                }

                self.biometricalStatus = BiometricalStatus.notShown
                self.passcodeViewController = PasscodeViewController(hiddenOverlay:hiddenOverlay)
                self.createLockWindow()

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
                if self.biometricalStatus != BiometricalStatus.shown,
                    self.biometricalStatus != BiometricalStatus.success {
                    self.passcodeViewController?.overlayPasscodeView.show()
                }
            }
        }
    }

    func showAddOrDeletePasscode(completionHandler: @escaping CompletionHandler) {

        if isPasscodeActivated {
            self.passcodeMode = PasscodeInterfaceMode.deletePasscode
        } else {
            self.passcodeMode = PasscodeInterfaceMode.addPasscodeFirstStep
        }

        self.completionHandler = completionHandler

        self.passcodeViewController = PasscodeViewController(hiddenOverlay:true)
        self.createLockWindow()

        self.updateUI()

        self.window?.showWindowAnimation()
    }

    func createLockWindow() {
        self.window = LockWindow(frame: UIScreen.main.bounds)
        self.window?.windowLevel = UIWindowLevelStatusBar
        self.window?.rootViewController = self.passcodeViewController!
        self.window?.makeKeyAndVisible()
    }

    func applicationWillResignActive() {

        //Protection to hide the PasscodeViewController if is on Delete modes to show the Unlock
        if self.passcodeViewController != nil {
            if self.passcodeMode == .deletePasscode ||
                self.passcodeMode == .deletePasscodeError {
                self.dismissPasscode(animated: false)
            }
        }

        //Store the date when the user pressed home button
        if self.isPasscodeActivated,
            self.dateApplicationWillResignActive == nil,
            self.passcodeViewController == nil || self.passcodeMode != .unlockPasscode,
            self.passcodeViewController == nil || self.passcodeMode != .unlockPasscodeError {
            self.dateApplicationWillResignActive = Date()
        }

        //Show the passcode
        self.showPasscodeIfNeeded(hiddenOverlay: false)
    }

    // MARK: - Interface updates

    private func updateUI() {

        var messageText : String?
        var errorText : String! = ""

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
            self.passcodeViewController?.overlayPasscodeView.hide()
            PasscodeManager.shared.showBiometricalIfNeeded()
        } else {
            if self.passcodeViewController != nil {
                //Protection to hide the PasscodeViewController only if is in unlock mode
                if self.passcodeMode == .unlockPasscode ||
                    self.passcodeMode == .unlockPasscodeError {
                    self.dismissPasscode(animated: true)
                    self.dateApplicationWillResignActive = nil
                }
            }
        }
    }

    func dismissPasscode(animated:Bool) {

        let hideWindow = {
            self.window?.isHidden = true
            self.passcodeViewController = nil
        }

        self.completionHandler?()
        if animated {
            self.window?.hideWindowAnimation {
                hideWindow()
            }
        } else {
            hideWindow()
        }
    }

    // MARK: - Brute force protection

    private func scheduledTimerToUpdateInterfaceTime() {

        DispatchQueue.main.async {
            self.updatePasscodeInterfaceTime()
        }

        self.timerBruteForce = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updatePasscodeInterfaceTime), userInfo: nil, repeats: true)
    }

    @objc private func updatePasscodeInterfaceTime() {

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
            self.timerBruteForce?.invalidate()
            self.passcodeViewController?.setEnableNumberButtons(isEnable: true)
            self.updateUI()
            self.showBiometricalIfNeeded()
        }
    }

    private func getSecondsToTryAgain() -> Int {
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
                    self.dismissPasscode(animated: true)
                } else {
                    self.passcodeViewController?.errorMessageLabel?.shakeHorizontally()
                    self.passcodeMode = .addPasscodeFirstStepAfterErrorOnSecond
                    self.passcodeFromFirstStep = nil
                    self.updateUI()
                }

            case .unlockPasscode?, .unlockPasscodeError?:
                if passcodeValue == self.passcodeFromKeychain {
                    self.dismissPasscode(animated: true)
                } else {
                    self.passcodeViewController?.errorMessageLabel?.shakeHorizontally()
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
                if passcodeValue == self.passcodeFromKeychain {
                    OCAppIdentity.shared().keychain.removeItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath)
                    self.dismissPasscode(animated: true)
                } else {
                    self.passcodeViewController?.errorMessageLabel?.shakeHorizontally()
                    self.passcodeMode = .deletePasscodeError
                    self.updateUI()
                }
            default:
                break
            }
        }
    }

    // MARK: - Biometrical

    func showBiometricalIfNeeded() {

        print(self.userDefaults.bool(forKey: SecuritySettingsBiometricalKey))

        if  self.biometricalStatus == BiometricalStatus.notShown,
            self.dateAllowTryAgain! <= Date(),
            self.userDefaults.bool(forKey: SecuritySettingsBiometricalKey) {
            self.authenticateUserWithBiometrical()
        }
    }

    private func authenticateUserWithBiometrical() {
        // Get the local authentication context.
        let context = LAContext()

        // Set the reason string that will appear on the authentication alert.
        let reasonString = "Unlock".localized

        // Declare a NSError variable.
        var error: NSError?

        // Check if the device can evaluate the policy.
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            self.biometricalStatus = BiometricalStatus.shown
            context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString) { (success, error) in
                if success {
                    self.biometricalStatus = BiometricalStatus.success
                    DispatchQueue.main.async {
                        self.dismissPasscode(animated: true)
                    }
                } else {
                    self.biometricalStatus = BiometricalStatus.error
                    if let error = error {
                        Log.log("Biometrical login error: \(String(error.localizedDescription))")
                    }
                }
            }
        }
    }
}
