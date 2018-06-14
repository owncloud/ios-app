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
        AppLockManager.shared.biometricalSecurityEnabled = false
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

    func testBiometricalSuccessAuthentication() {

        // Prepare the simulator show the passcode
        AppLockManager.shared.passcode = "1111"
        AppLockManager.shared.lockEnabled = true
        AppLockManager.shared.biometricalSecurityEnabled = true

        AppLockManager.shared.showLockscreenIfNeeded(context: TestLAContext(success: true, error: nil))

        let isPasscodeUnlocked = GREYCondition(name: "Wait for passcode is unlocked by biometrical", block: {
			var error: NSError?

            EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).assert(grey_sufficientlyVisible(), error: &error)

            return error == nil
        }).wait(withTimeout: 5.0, pollInterval: 0.5)

		//Assert
		GREYAssertTrue(isPasscodeUnlocked, reason: "Failed to unlock the passcode with biometrical")
    }

	//Class to mock the LAContext to test the biometrical unlock
	class TestLAContext: LAContext {

		var success:Bool
		var error:NSError?

		init(success: Bool = true, error: NSError?) {
			self.success = success
			self.error = error
			super.init()
		}

		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}

		override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
			return true
		}

		override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, Error?) -> Void) {
			reply(success, error)
		}
	}
}
