//
//  Settings.swift
//  ownCloudTests
//
//  Created by Jesús Recio on 27/02/2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import XCTest
import EarlGrey
import ownCloudSDK
import ownCloudMocking

@testable import ownCloud

class SettingsTests: XCTestCase {

	override func setUp() {
		EarlGrey.waitForElement(withMatcher: grey_text("Settings".localized), label: "Settings")
		EarlGrey.select(elementWithMatcher: grey_text("Settings".localized)).perform(grey_tap())
		EarlGrey.waitForElement(accessibilityID: "theme")
	}

	override func tearDown() {
		//Reset status
		EarlGrey.select(elementWithMatcher: grey_text(OCAppIdentity.shared.appName!)).perform(grey_tap())
		EarlGrey.waitForElement(accessibilityID: "addServer")
	}

	/*
	* PASSED if: Theme and Logging are displayed as part of the "User Interface" section of Settings
	*/
	func testCheckUserInterfaceItems () {
		EarlGrey.waitForElement(accessibilityID: "theme")

		//Assert
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("theme")).assert(grey_sufficientlyVisible())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("logging")).assert(grey_sufficientlyVisible())
	}
	
	/*
	* PASSED if: Show hidden files and folders are displayed as part of the "Display Settings" section of Settings
	*/
	func testCheckDisplaySettings () {
		
		//Assert
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("show-hidden-files-switch")).assert(grey_sufficientlyVisible())
	}
	
	/*
	* PASSED if: Media upload options are displayed as part of the "Media Upload" section of Settings
	*/
	func testCheckMediaUploadSettings () {
		// Scroll into view and apply assertions
		EarlGrey.select(elementWithMatcher:grey_accessibilityID("convert_heic_to_jpeg")).using(searchAction: grey_scrollInDirection(GREYDirection.down, 350), onElementWithMatcher: grey_kindOfClass(UITableView.self)).assert(grey_sufficientlyVisible())
	/*	EarlGrey.select(elementWithMatcher:grey_accessibilityID("convert_to_mp4")).using(searchAction: grey_scrollInDirection(GREYDirection.down, 300), onElementWithMatcher: grey_kindOfClass(UITableView.self)).assert(grey_sufficientlyVisible())
*/
	}


	/*
	* PASSED if: "More" options "are displayed
	*/
	func testCheckMoreItems () {
		EarlGrey.select(elementWithMatcher: grey_kindOfClass(UITableView.self)).perform(grey_scrollToContentEdge(.bottom))

		//Assert
		EarlGrey.select(elementWithMatcher:grey_accessibilityID("help")).assert(grey_sufficientlyVisible())
		EarlGrey.select(elementWithMatcher:grey_accessibilityID("send-feedback")).assert(grey_sufficientlyVisible())
		EarlGrey.select(elementWithMatcher:grey_accessibilityID("recommend-friend")).assert(grey_sufficientlyVisible())
		EarlGrey.select(elementWithMatcher:grey_accessibilityID("privacy-policy")).assert(grey_sufficientlyVisible())
		EarlGrey.select(elementWithMatcher:grey_accessibilityID("acknowledgements")).assert(grey_sufficientlyVisible())
	}

	/*
	* PASSED if: All UI components in Logging view are displayed and correctly visible when option is enabled.
	*/
	func testCheckLoggingInterfaceLoggingEnabled () {

		//Actions
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("logging")).perform(grey_tap())

		//Assert
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("enable-logging")).assert(grey_switchWithOnState(true))
		EarlGrey.select(elementWithMatcher: grey_text("Debug".localized)).assert(grey_sufficientlyVisible())
		EarlGrey.select(elementWithMatcher: grey_text("Info".localized)).assert(grey_sufficientlyVisible())
		EarlGrey.select(elementWithMatcher: grey_text("Warning".localized)).assert(grey_sufficientlyVisible())
		EarlGrey.select(elementWithMatcher: grey_text("Error".localized)).assert(grey_sufficientlyVisible())

		EarlGrey.select(elementWithMatcher: grey_accessibilityID("Logging"))
			.usingSearch(grey_scrollInDirection(GREYDirection.down, 100), onElementWith: grey_text("Log HTTP requests and responses"))
			.assert(grey_sufficientlyVisible())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("Logging"))
			.usingSearch(grey_scrollInDirection(GREYDirection.down, 100), onElementWith: grey_text("Standard error output".localized))
			.assert(grey_sufficientlyVisible())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("Logging"))
			.usingSearch(grey_scrollInDirection(GREYDirection.down, 100), onElementWith: grey_text("Log file".localized))
			.assert(grey_sufficientlyVisible())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("Logging"))
			.usingSearch(grey_scrollInDirection(GREYDirection.down, 100), onElementWith: grey_text("Browse".localized))
			.assert(grey_sufficientlyVisible())

		//Reset status
		EarlGrey.select(elementWithMatcher: grey_text("Settings".localized)).perform(grey_tap())
	}

	/*
	* PASSED if: Log level is changed to "Warning".
	*/
	func testSwitchLogLevel () {
		EarlGrey.waitForElement(accessibilityID: "logging")

		//Actions
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("logging")).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_text("Warning".localized)).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_text("Settings".localized)).perform(grey_tap())

		//Assert
		EarlGrey.select(elementWithMatcher: grey_text("Warning".localized)).assert(grey_sufficientlyVisible())
	}

	/*
	* PASSED if: All UI components in Logging view are not displayed when option is disabled.
	*/
	func testCheckLoggingInterfaceLoggingDisabled () {

		//Actions
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("logging")).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("enable-logging")).perform(grey_turnSwitchOn(false))

		//Assert
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("enable-logging")).assert(grey_switchWithOnState(false))
		EarlGrey.select(elementWithMatcher: grey_text("Debug".localized)).assert(grey_notVisible())
		EarlGrey.select(elementWithMatcher: grey_text("Info".localized)).assert(grey_notVisible())
		EarlGrey.select(elementWithMatcher: grey_text("Warning".localized)).assert(grey_notVisible())
		EarlGrey.select(elementWithMatcher: grey_text("Error".localized)).assert(grey_notVisible())

		EarlGrey.select(elementWithMatcher: grey_text("Log HTTP requests and responses".localized)).assert(grey_notVisible())
		EarlGrey.select(elementWithMatcher: grey_text("Standard error output".localized)).assert(grey_notVisible())
		EarlGrey.select(elementWithMatcher: grey_text("Log file".localized)).assert(grey_notVisible())

		//Reset status
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("enable-logging")).perform(grey_turnSwitchOn(true))
		EarlGrey.select(elementWithMatcher: grey_text("Settings".localized)).perform(grey_tap())
	}

	/*
	* PASSED if: All themes available are displayed
	*/
	func testCheckThemesAvailable () {
		EarlGrey.waitForElement(accessibilityID: "theme")

		//Actions
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("theme")).perform(grey_tap())

		//Assert
		EarlGrey.select(elementWithMatcher: grey_text("Dark".localized)).assert(grey_sufficientlyVisible())
		EarlGrey.select(elementWithMatcher: grey_text("Light".localized)).assert(grey_sufficientlyVisible())
		EarlGrey.select(elementWithMatcher: grey_text("Classic".localized)).assert(grey_sufficientlyVisible())

		//Reset status
		EarlGrey.select(elementWithMatcher: grey_text("Settings".localized)).perform(grey_tap())
	}

}
