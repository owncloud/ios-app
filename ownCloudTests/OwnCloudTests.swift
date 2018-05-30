//
//  ownCloudTests.swift
//  ownCloudTests
//
//  Created by Pablo Carrascal on 07/03/2018.
//  Copyright © 2018 ownCloud. All rights reserved.
//

import XCTest
import EarlGrey
import ownCloudSDK

@testable import ownCloud

class OwnCloudTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    /*
     * Passed if: "Add Server" button is enabled
     */
    func testAddServerButtonIsEnabled() {
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).assert(with: grey_enabled())
    }

    func testClickOnTheButtonAndNothingHappens() {
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testUnlockPasscodeCorrect() {

        //Prepare the simulator show the passcode
        AppLockManager.shared.writePasscodeInKeychain(passcode: "1111")
        let userDefaults = UserDefaults(suiteName: OCAppIdentity.shared().appGroupIdentifier) ?? UserDefaults.standard
        userDefaults.set(true, forKey: SecuritySettingsPasscodeKey)

        //Show the passcode
        AppLockManager.shared.showPasscodeIfNeeded()

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

    func testUnlockPasscodeWrong() {

        //Prepare the simulator show the passcode
        AppLockManager.shared.writePasscodeInKeychain(passcode: "2222")
        let userDefaults = UserDefaults(suiteName: OCAppIdentity.shared().appGroupIdentifier) ?? UserDefaults.standard
        userDefaults.set(true, forKey: SecuritySettingsPasscodeKey)

        //Show the passcode
        AppLockManager.shared.showPasscodeIfNeeded()

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
