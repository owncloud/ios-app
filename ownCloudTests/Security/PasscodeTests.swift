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
		OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
	}

	override func tearDown() {
		AppLockManager.shared.passcode = nil
		AppLockManager.shared.lockEnabled = false
		super.tearDown()
	}

	// MARK: - Passcode

	/*
	* PASSED if: Passcode correct. "Add Server" view displayed
	*/
	func testUnlockRightPasccode() {

		// Prepare the simulator show the passcode
		AppLockManager.shared.passcode = "1111"
		AppLockManager.shared.lockEnabled = true

		// Show the passcode
		AppLockManager.shared.showLockscreenIfNeeded()
		EarlGrey.waitForElement(accessibilityID: "number1Button")

		// Tap the number buttons
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())

		EarlGrey.waitForElement(accessibilityID: "addServer")

		// Asserts
		EarlGrey.selectElement(with: grey_accessibilityID("addServer")).assert(grey_sufficientlyVisible())

		//Reset Status
		AppLockManager.shared.dismissLockscreen(animated: false)
	}

	/*
	* PASSED if: Passcode incorrect. Passcode view displays with error
	*/
	func testUnlockWrongPasscode() {

		// Prepare the simulator show the passcode
		AppLockManager.shared.passcode = "2222"
		AppLockManager.shared.lockEnabled = true

		// Show the passcode
		AppLockManager.shared.showLockscreenIfNeeded()
		EarlGrey.waitForElement(accessibilityID: "number1Button")

		// Tap the number buttons
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())

		// Asserts
		EarlGrey.selectElement(with: grey_accessibilityID("messageLabel")).assert(grey_sufficientlyVisible())

		//Reset Status
		AppLockManager.shared.dismissLockscreen(animated: false)
	}

	/*
	* PASSED if: Passcode Lock disabled in Settings view after cancelling
	*/
	func testCancelPasscode() {

		// Assure that the passcode is disabled
		AppLockManager.shared.lockEnabled = false

		EarlGrey.waitForElementMissing(accessibilityID: "settingsBarButtonItem")

		EarlGrey.selectElement(with: grey_accessibilityID("settingsBarButtonItem")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("passcodeSwitchIdentifier")).perform(grey_turnSwitchOn(true))

		// Tap the number buttons
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_text("Cancel".localized)).perform(grey_tap())

		EarlGrey.waitForElementMissing(accessibilityID: "number1Button")

		// Asserts
		EarlGrey.selectElement(with: grey_accessibilityID("passcodeSwitchIdentifier")).assert(grey_switchWithOnState(false))

		// Reset status
		EarlGrey.selectElement(with: grey_text("ownCloud")).perform(grey_tap())
	}

	/*
	* PASSED if: Passcode Lock disabled in Settings view after cancelling in the second typing
	*/
	func testCancelSecondTryPasscode() {

		// Assure that the passcode is disabled
		AppLockManager.shared.lockEnabled = false

		EarlGrey.waitForElementMissing(accessibilityID: "settingsBarButtonItem")

		EarlGrey.selectElement(with: grey_accessibilityID("settingsBarButtonItem")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("passcodeSwitchIdentifier")).perform(grey_turnSwitchOn(true))

		// Tap the number buttons first time
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())

		// Tap the number buttons second time & cancel
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_text("Cancel".localized)).perform(grey_tap())

		EarlGrey.waitForElementMissing(accessibilityID: "number1Button")

		// Asserts
		EarlGrey.selectElement(with: grey_accessibilityID("passcodeSwitchIdentifier")).assert(grey_switchWithOnState(false))

		//Reset status
		EarlGrey.selectElement(with: grey_text("ownCloud")).perform(grey_tap())
	}

	/*
	* PASSED if: Correct error when second typing is different than the first one
	*/
	func testEnterDifferentPasscodes() {

		// Assure that the passcode is disabled
		AppLockManager.shared.lockEnabled = false

		EarlGrey.waitForElementMissing(accessibilityID: "settingsBarButtonItem")

		EarlGrey.selectElement(with: grey_accessibilityID("settingsBarButtonItem")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("passcodeSwitchIdentifier")).perform(grey_turnSwitchOn(true))

		// Tap the number buttons
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())

		// Tap the number buttons again
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("number3Button")).perform(grey_tap())

		// Asserts
		EarlGrey.selectElement(with: grey_text("The entered codes are different".localized)).assert(grey_sufficientlyVisible())
		EarlGrey.selectElement(with: grey_text("Cancel".localized)).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("passcodeSwitchIdentifier")).assert(grey_switchWithOnState(false))

		//Reset status
		EarlGrey.selectElement(with: grey_text("ownCloud")).perform(grey_tap())
	}

	/*
	* PASSED if: Passcode lock is correctly disabled in Settings view
	*/
	func testDisablePasscode() {

		// Prepare the simulator show the passcode
		AppLockManager.shared.passcode = "1111"
		AppLockManager.shared.lockEnabled = true

		EarlGrey.waitForElementMissing(accessibilityID: "settingsBarButtonItem")

		EarlGrey.selectElement(with: grey_accessibilityID("settingsBarButtonItem")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("passcodeSwitchIdentifier")).perform(grey_turnSwitchOn(false))

		// Tap the number buttons first time
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())

		EarlGrey.waitForElementMissing(accessibilityID: "number1Button")

		// Asserts
		EarlGrey.selectElement(with: grey_accessibilityID("passcodeSwitchIdentifier")).assert(grey_switchWithOnState(false))
		EarlGrey.selectElement(with: grey_accessibilityID("lockFrequency")).assert(grey_notVisible())

		//Reset status
		EarlGrey.selectElement(with: grey_text("ownCloud")).perform(grey_tap())
	}

	/*
	* PASSED if: Passcode lock keeps enabled in Settings view after cancelling
	*/
	func testCancelDisablePasscode() {

		// Prepare the simulator show the passcode
		AppLockManager.shared.passcode = "1111"
		AppLockManager.shared.lockEnabled = true

		EarlGrey.waitForElementMissing(accessibilityID: "settingsBarButtonItem")

		EarlGrey.selectElement(with: grey_accessibilityID("settingsBarButtonItem")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("passcodeSwitchIdentifier")).perform(grey_turnSwitchOn(false))

		// Tap the number buttons first time
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("number1Button")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_text("Cancel".localized)).perform(grey_tap())

		EarlGrey.waitForElementMissing(accessibilityID: "number1Button")

		// Asserts
		EarlGrey.selectElement(with: grey_accessibilityID("passcodeSwitchIdentifier")).assert(grey_switchWithOnState(true))
		EarlGrey.selectElement(with: grey_accessibilityID("lockFrequency")).assert(grey_sufficientlyVisible())

		//Reset status
		EarlGrey.selectElement(with: grey_text("ownCloud")).perform(grey_tap())
	}

	/*
	* PASSED if: 1 minute frequency covered
	*/
	func testChangeFrequency() {

		// Prepare the simulator show the passcode
		AppLockManager.shared.passcode = "1111"
		AppLockManager.shared.lockEnabled = true

		EarlGrey.waitForElementMissing(accessibilityID: "settingsBarButtonItem")

		EarlGrey.selectElement(with: grey_accessibilityID("settingsBarButtonItem")).perform(grey_tap())

		// Tap the number buttons first time
		EarlGrey.selectElement(with: grey_accessibilityID("lockFrequency")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_text("After 1 minute".localized)).perform(grey_tap())
		EarlGrey.selectElement(with: grey_text("Settings".localized)).perform(grey_tap())

		//Asserts
		EarlGrey.selectElement(with: grey_text("After 1 minute".localized)).assert(grey_sufficientlyVisible())

		//Reset status
		EarlGrey.selectElement(with: grey_text("ownCloud")).perform(grey_tap())
		AppLockManager.shared.lockEnabled = false
	}
}
