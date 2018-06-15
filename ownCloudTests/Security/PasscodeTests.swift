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
}
