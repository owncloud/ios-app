//
//  PasscodeTests.swift
//  ownCloudTests
//
//  Created by Javier Gonzalez on 31/05/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import XCTest
import EarlGrey
import ownCloudSDK
import LocalAuthentication

@testable import ownCloud

class PasscodeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        AppLockManager.shared.passcode = nil
        AppLockManager.shared.lockEnabled = false
        super.tearDown()
    }

    // MARK: - Passcode

    func testUnlockRightPasccode() {

        // Prepare the simulator show the passcode
        AppLockManager.shared.passcode = "1111"
        AppLockManager.shared.lockEnabled = true

        // Show the passcode
        AppLockManager.shared.showLockscreenIfNeeded()

        // Tap the number buttons
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())

        // Asserts
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).assert(grey_sufficientlyVisible())

    }

    func testUnlockWrongPasscode() {

        // Prepare the simulator show the passcode
        AppLockManager.shared.passcode = "2222"
        AppLockManager.shared.lockEnabled = true

        // Show the passcode
        AppLockManager.shared.showLockscreenIfNeeded()

        // Tap the number buttons
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())

        // Asserts
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("messageLabel")).assert(grey_sufficientlyVisible())
    }

    func testCancelPasscode() {

        // Assure that the passcode is disabled
        AppLockManager.shared.lockEnabled = false
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("settingsBarButtonItem")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("passcodeSwitchIdentifier")).perform(grey_turnSwitchOn(true))

        // Tap the number buttons
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_text("Cancel")).perform(grey_tap())

        // Asserts
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("passcodeSwitchIdentifier")).assert(grey_switchWithOnState(false))

        //Reset status
        EarlGrey.select(elementWithMatcher: grey_text("ownCloud")).perform(grey_tap())
    }

    func testCancelSecondTryPasscode() {

        // Assure that the passcode is disabled
        AppLockManager.shared.lockEnabled = false
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("settingsBarButtonItem")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("passcodeSwitchIdentifier")).perform(grey_turnSwitchOn(true))

        // Tap the number buttons first time
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())

        // Tap the number buttons second time & cancel
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_text("Cancel")).perform(grey_tap())

        // Asserts
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("passcodeSwitchIdentifier")).assert(grey_switchWithOnState(false))

        //Reset status
        EarlGrey.select(elementWithMatcher: grey_text("ownCloud")).perform(grey_tap())
    }

    func testEnterDifferentPasscodes() {

        // Assure that the passcode is disabled
        AppLockManager.shared.lockEnabled = false
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("settingsBarButtonItem")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("passcodeSwitchIdentifier")).perform(grey_turnSwitchOn(true))

        // Tap the number buttons
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())

        // Tap the number buttons again
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number3Button")).perform(grey_tap())

        // Asserts
        EarlGrey.select(elementWithMatcher: grey_text("The entered codes are different")).assert(grey_sufficientlyVisible())
        EarlGrey.select(elementWithMatcher: grey_text("Cancel")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("passcodeSwitchIdentifier")).assert(grey_switchWithOnState(false))

        //Reset status
        EarlGrey.select(elementWithMatcher: grey_text("ownCloud")).perform(grey_tap())
    }

    func testDisablePasscode() {

        // Prepare the simulator show the passcode
        AppLockManager.shared.passcode = "1111"
        AppLockManager.shared.lockEnabled = true

        EarlGrey.select(elementWithMatcher: grey_accessibilityID("settingsBarButtonItem")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("passcodeSwitchIdentifier")).perform(grey_turnSwitchOn(false))

        // Tap the number buttons first time
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())

        // Asserts
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("passcodeSwitchIdentifier")).assert(grey_switchWithOnState(false))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("lockFrequency")).assert(grey_notVisible())

        //Reset status
        EarlGrey.select(elementWithMatcher: grey_text("ownCloud")).perform(grey_tap())
    }

    func testCancelDisablePasscode() {

        // Prepare the simulator show the passcode
        AppLockManager.shared.passcode = "1111"
        AppLockManager.shared.lockEnabled = true

        EarlGrey.select(elementWithMatcher: grey_accessibilityID("settingsBarButtonItem")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("passcodeSwitchIdentifier")).perform(grey_turnSwitchOn(false))

        // Tap the number buttons first time
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_text("Cancel")).perform(grey_tap())

        // Asserts
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("passcodeSwitchIdentifier")).assert(grey_switchWithOnState(true))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("lockFrequency")).assert(grey_sufficientlyVisible())

        //Reset status
        EarlGrey.select(elementWithMatcher: grey_text("ownCloud")).perform(grey_tap())
    }

    func testChangeFrequency() {

        // Prepare the simulator show the passcode
        AppLockManager.shared.passcode = "1111"
        AppLockManager.shared.lockEnabled = true

        EarlGrey.select(elementWithMatcher: grey_accessibilityID("settingsBarButtonItem")).perform(grey_tap())

        // Tap the number buttons first time
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("lockFrequency")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_text("After 1 minute")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_text("Settings")).perform(grey_tap())

        //Asserts
        EarlGrey.select(elementWithMatcher: grey_text("After 1 minute")).assert(grey_sufficientlyVisible())

        //Reset status
        EarlGrey.select(elementWithMatcher: grey_text("ownCloud")).perform(grey_tap())
        AppLockManager.shared.lockEnabled = false
    }
}
