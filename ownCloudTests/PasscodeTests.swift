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

@testable import ownCloud

class PasscodeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // MARK: - Passcode

    func testUnlockRightPasccode() {

        //Prepare the simulator show the passcode
        AppLockManager.shared.writePasscodeInKeychain(passcode: "1111")
        let userDefaults = OCAppIdentity.shared().userDefaults
        userDefaults.set(true, forKey: SecuritySettingsPasscodeKey)

        //Show the passcode
        AppLockManager.shared.showLockscreenIfNeeded()

        //Tap the number buttons
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())

        //Asserts
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).assert(grey_sufficientlyVisible())

        //Set the simulator on the initial state
        userDefaults.set(false, forKey: SecuritySettingsPasscodeKey)
        AppLockManager.shared.removePasscodeFromKeychain()
    }

    func testUnlockWrongPasscode() {

        //Prepare the simulator show the passcode
        AppLockManager.shared.writePasscodeInKeychain(passcode: "2222")
        let userDefaults = OCAppIdentity.shared().userDefaults
        userDefaults.set(true, forKey: SecuritySettingsPasscodeKey)

        //Show the passcode
        AppLockManager.shared.showLockscreenIfNeeded()

        //Tap the number buttons
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("number1Button")).perform(grey_tap())

        //Asserts
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("messageLabel")).assert(grey_sufficientlyVisible())

        //Set the simulator on the initial state
        userDefaults.set(false, forKey: SecuritySettingsPasscodeKey)
        AppLockManager.shared.removePasscodeFromKeychain()
    }
}
