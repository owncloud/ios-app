//
//  AppLockManager.swift
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

class AppLockManager: NSObject {

    // MARK: - UI
    private var window: AppLockWindow?
    private var passcodeViewController: PasscodeViewController?

    private var userDefaults: UserDefaults

    // MARK: - State
    var lastApplicationBackgroundedDate : Date?

    private var failedPasscodeAttempts: Int {
        get {
            return userDefaults.integer(forKey: "applock-failed-passcode-attempts")
        }
        set(newValue) {
            self.userDefaults.set(newValue, forKey: "applock-failed-passcode-attempts")
        }
    }
    private var lockedUntilDate: Date? {
        get {
            return userDefaults.object(forKey: "applock-locked-until-date") as? Date
        }
        set(newValue) {
            self.userDefaults.set(newValue, forKey: "applock-locked-until-date")
        }
    }

    private let maximumPasscodeAttempts: Int = 3
    private let powBaseDelay: Double = 1.5
    private var lockTimer: Timer?

    // MARK: - Passcode
    private let keychainAccount = "app.passcode"
    private let keychainPasscodePath = "passcode"

    private var keychain : OCKeychain? {
        return OCAppIdentity.shared().keychain
    }

    var passcode: String? {
        get {
            if let passcodeData = self.keychain?.readDataFromKeychainItem(forAccount: keychainAccount, path: keychainPasscodePath) {
                return String(data: passcodeData, encoding: .utf8)
            }

            return nil
        }

        set(newPasscode) {
            if let passcode = newPasscode {
                _ = self.keychain?.write(passcode.data(using: .utf8), toKeychainItemForAccount: keychainAccount, path: keychainPasscodePath)
            } else {
                _ = self.keychain?.removeItem(forAccount: keychainAccount, path: keychainPasscodePath)
            }
        }
    }

    // MARK: - Settings
    var lockEnabled: Bool {
        get {
            return userDefaults.bool(forKey: "applock-lock-enabled")
        }
        set(newValue) {
            self.userDefaults.set(newValue, forKey: "applock-lock-enabled")
        }
    }

    var lockDelay: Int {
        get {
            return userDefaults.integer(forKey: "applock-lock-delay")
        }

        set(newValue) {
            self.userDefaults.set(newValue, forKey: "applock-lock-delay")
        }
    }

    var biometricalSecurityEnabled: Bool {
        return self.userDefaults.bool(forKey: SecuritySettingsBiometricalKey)
    }

    // MARK: - Init
    static var shared = AppLockManager()

    public override init() {
        userDefaults = OCAppIdentity.shared().userDefaults

        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(self.appDidEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.appWillEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
    }

    // MARK: - Show / Dismiss Passcode View
    func showLockscreenIfNeeded(forceShow: Bool = false) {
        if self.shouldDisplayLockscreen || forceShow {
            if passcodeViewController == nil {
                passcodeViewController = PasscodeViewController(completionHandler: { (passcode: String) in
                    self.attemptUnlock(with: passcode)
                })

                passcodeViewController?.message = "Enter code".localized
                passcodeViewController?.cancelButtonHidden = false

                passcodeViewController?.screenBlurringEnabled = forceShow && !self.shouldDisplayLockscreen

                window = AppLockWindow(frame: UIScreen.main.bounds)
                /*
                 Workaround to the lack of status bar animation when returning true for prefersStatusBarHidden in
                 PasscodeViewController.

                 The documentation notes that "The ordering of windows within a given window level is not guaranteed.",
                 so that with a future iOS update this might break and the status bar be displayed regardless. In that
                 case, implement prefersStatusBarHidden in PasscodeViewController to return true and remove the dismiss
                 animation (the re-appearance of the status bar will lead to a jump in the UI otherwise).
                 */
                window?.windowLevel = UIWindowLevelStatusBar
                window?.rootViewController = passcodeViewController!
                window?.makeKeyAndVisible()

                startLockCountdown()
            } else {
                passcodeViewController?.screenBlurringEnabled = forceShow
            }

            // Show biometrical
            if !forceShow {
                authenticateWithBiometrical()
            }
        }
    }

    func dismissLockscreen(animated:Bool) {
        let hideWindow = {
            self.window?.isHidden = true
            self.passcodeViewController = nil
            self.window = nil
        }

        if animated {
            self.window?.hideWindowAnimation {
                hideWindow()
            }
        } else {
            hideWindow()
        }
    }

    // MARK: - App Events
    @objc func appDidEnterBackground() {
        lastApplicationBackgroundedDate = Date()

        showLockscreenIfNeeded(forceShow: true)
    }

    @objc func appWillEnterForeground() {
        if self.shouldDisplayLockscreen {
            showLockscreenIfNeeded()
        } else {
            dismissLockscreen(animated: false)
        }
    }

    // MARK: - Unlock
    func attemptUnlock(with testPasscode: String) {
        if testPasscode == self.passcode {
            lastApplicationBackgroundedDate = nil
            failedPasscodeAttempts = 0
            dismissLockscreen(animated: true)
        } else {
            passcodeViewController?.errorMessage = "Incorrect code".localized

            failedPasscodeAttempts += 1

            if self.failedPasscodeAttempts >= self.maximumPasscodeAttempts {
                let delayUntilNextAttempt = pow(powBaseDelay, Double(failedPasscodeAttempts))

                lockedUntilDate = Date().addingTimeInterval(delayUntilNextAttempt)
                startLockCountdown()
            }

            passcodeViewController?.passcode = nil
        }
    }

    // MARK: - Status
    private var shouldDisplayLockscreen: Bool {
        if !self.lockEnabled {
            return false
        }

        if !self.shouldDisplayCountdown {
            if let date = self.lastApplicationBackgroundedDate {
                if Int(-date.timeIntervalSinceNow) < self.lockDelay {
                    return false
                }
            }
        }

        return true
    }

    private var shouldDisplayCountdown : Bool {
        if let startLockBeforeDate = self.lockedUntilDate {
            return startLockBeforeDate > Date()
        }

        return false
    }

    // MARK: - Countdown display
    private func startLockCountdown() {
        if self.shouldDisplayCountdown {
            passcodeViewController?.keypadButtonsHidden = true
            updateLockCountdown()

            lockTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateLockCountdown), userInfo: nil, repeats: true)
        }
    }

    @objc private func updateLockCountdown() {
        if let date = self.lockedUntilDate {
            let interval = Int(date.timeIntervalSinceNow)
            let seconds = interval % 60
            let minutes = (interval / 60) % 60
            let hours = (interval / 3600)

            let dateFormatted:String?
            if hours > 0 {
                dateFormatted = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            } else {
                dateFormatted = String(format: "%02d:%02d", minutes, seconds)
            }

            let timeoutMessage:String = NSString(format: "Please try again in %@".localized as NSString, dateFormatted!) as String
            self.passcodeViewController?.timeoutMessage = timeoutMessage

            if date <= Date() {
                // Time elapsed, allow entering passcode again
                self.lockTimer?.invalidate()
                self.passcodeViewController?.keypadButtonsHidden = false
                self.passcodeViewController?.timeoutMessage = nil
                self.passcodeViewController?.errorMessage = nil
            }
        }
    }

    // MARK: - Biometrical Unlock

    func authenticateWithBiometrical() {

        if  shouldDisplayLockscreen, biometricalSecurityEnabled {

            let context = LAContext()

            // Check if the device can evaluate the policy.
            if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: nil) {
                context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock passcode".localized) { (success, _) in
                    if success {
                        //Fill the passcode dots
                        DispatchQueue.main.async {
                            self.passcodeViewController?.passcode = self.passcode
                        }
                        //Remove the passcode after small delay to give user feedback after use the biometrical unlock
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.dismissLockscreen(animated: true)
                        }
                    }
                }
            }
        }
    }
}
