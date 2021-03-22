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
import ownCloudAppShared

@testable import ownCloud

class SettingsTests: XCTestCase {

	override func setUp() {
		EarlGrey.waitForElement(withMatcher: grey_text("Settings".localized), label: "Settings")
		EarlGrey.selectElement(with: grey_text("Settings".localized)).perform(grey_tap())
		EarlGrey.waitForElement(accessibilityID: "theme")
	}

	override func tearDown() {
		//Reset status
		EarlGrey.selectElement(with: grey_text(VendorServices.shared.appName)).perform(grey_tap())
		EarlGrey.waitForElement(accessibilityID: "addServer")
	}

	/*
	* PASSED if: Theme and Logging are displayed as part of the "User Interface" section of Settings
	*/
	func testCheckUserInterfaceItems () {
		EarlGrey.waitForElement(accessibilityID: "theme")

		//Assert
		EarlGrey.selectElement(with: grey_accessibilityID("theme")).assert(grey_sufficientlyVisible())
		EarlGrey.selectElement(with: grey_accessibilityID("logging")).assert(grey_sufficientlyVisible())
	}

	/*
	* PASSED if: Show hidden files and folders, Drag Files are displayed as part of the "Advanced Settings" section of Settings
	*/
	func testCheckDisplaySettings () {

		//Assert
		EarlGrey.selectElement(with: grey_accessibilityID("show-hidden-files-switch")).assert(grey_sufficientlyVisible())
		EarlGrey.selectElement(with: grey_accessibilityID("sort-folders-first")).assert(grey_sufficientlyVisible())
		EarlGrey.selectElement(with: grey_accessibilityID("prevent-dragging-files-switch")).assert(grey_sufficientlyVisible())
	}
	
	/*
	* PASSED if: Media upload options are displayed as part of the "Media Upload" section of Settings
	*/
	func testCheckMediaUploadSettings () {
		// Open media upload settings section
		EarlGrey.selectElement(with:grey_accessibilityID("media-upload")).using(searchAction: grey_scrollInDirection(GREYDirection.down, 350), onElementWithMatcher: grey_kindOfClass(UITableView.self)).perform(grey_tap())

		// Scroll into view and apply assertions
		EarlGrey.selectElement(with:grey_accessibilityID("convert_heic_to_jpeg")).assert(grey_sufficientlyVisible())
		EarlGrey.selectElement(with:grey_accessibilityID("convert_to_mp4")).assert(grey_sufficientlyVisible())
		EarlGrey.selectElement(with:grey_accessibilityID("preserve_media_file_names")).assert(grey_sufficientlyVisible())

		// Make sure instant uploads section is not visible if no bookmark is configured
		EarlGrey.selectElement(with: grey_text("Auto Upload".localized)).assert(grey_notVisible())
		EarlGrey.selectElement(with: grey_text("Background uploads".localized)).assert(grey_notVisible())

		//Reset status
		EarlGrey.selectElement(with: grey_text("Settings".localized)).perform(grey_tap())
	}

	func testMediaBackgroundUploadsSettings() {
		if let bookmark: OCBookmark = UtilsTests.getBookmark() {
			OCBookmarkManager.shared.addBookmark(bookmark)
			// Open media upload settings section
			EarlGrey.selectElement(with:grey_accessibilityID("media-upload")).using(searchAction: grey_scrollInDirection(GREYDirection.down, 350), onElementWithMatcher: grey_kindOfClass(UITableView.self)).perform(grey_tap())

			EarlGrey.selectElement(with:grey_accessibilityID("auto-upload-photos")).assert(grey_sufficientlyVisible())
			EarlGrey.selectElement(with:grey_accessibilityID("auto-upload-videos")).assert(grey_sufficientlyVisible())

			//Reset status
			EarlGrey.selectElement(with: grey_text("Settings".localized)).perform(grey_tap())
			OCBookmarkManager.shared.removeBookmark(bookmark)
		}
	}

	/*
	* PASSED if: "More" options "are displayed
	*/
	func testCheckMoreItems () {
		EarlGrey.selectElement(with: grey_kindOfClass(UITableView.self)).perform(grey_scrollToContentEdge(.bottom))

		//Assert
		EarlGrey.selectElement(with:grey_accessibilityID("help")).assert(grey_sufficientlyVisible())
		EarlGrey.selectElement(with:grey_accessibilityID("send-feedback")).assert(grey_sufficientlyVisible())
		EarlGrey.selectElement(with:grey_accessibilityID("recommend-friend")).assert(grey_sufficientlyVisible())
		EarlGrey.selectElement(with:grey_accessibilityID("privacy-policy")).assert(grey_sufficientlyVisible())
		EarlGrey.selectElement(with:grey_accessibilityID("acknowledgements")).assert(grey_sufficientlyVisible())
	}

	/*
	* PASSED if: All UI components in Logging view are displayed and correctly visible when option is enabled.
	*/
	func testCheckLoggingInterfaceLoggingEnabled () {

		//Actions
		EarlGrey.selectElement(with: grey_accessibilityID("logging")).perform(grey_tap())

		//Assert
		EarlGrey.selectElement(with: grey_accessibilityID("enable-logging")).assert(grey_switchWithOnState(true))
		EarlGrey.selectElement(with: grey_text("Debug".localized)).assert(grey_sufficientlyVisible())
		EarlGrey.selectElement(with: grey_text("Info".localized)).assert(grey_sufficientlyVisible())
		EarlGrey.selectElement(with: grey_text("Warning".localized)).assert(grey_sufficientlyVisible())
		EarlGrey.selectElement(with: grey_text("Error".localized)).assert(grey_sufficientlyVisible())

		EarlGrey.selectElement(with: grey_accessibilityID("Logging"))
			.usingSearch(grey_scrollInDirection(GREYDirection.down, 100), onElementWith: grey_text("Log HTTP requests and responses"))
			.assert(grey_sufficientlyVisible())
		EarlGrey.selectElement(with: grey_accessibilityID("Logging"))
			.usingSearch(grey_scrollInDirection(GREYDirection.down, 100), onElementWith: grey_text("Standard error output".localized))
			.assert(grey_sufficientlyVisible())
		EarlGrey.selectElement(with: grey_accessibilityID("Logging"))
			.usingSearch(grey_scrollInDirection(GREYDirection.down, 100), onElementWith: grey_text("Log file".localized))
			.assert(grey_sufficientlyVisible())
		EarlGrey.selectElement(with: grey_accessibilityID("Logging"))
			.usingSearch(grey_scrollInDirection(GREYDirection.down, 100), onElementWith: grey_text("Browse".localized))
			.assert(grey_sufficientlyVisible())

		//Reset status
		EarlGrey.selectElement(with: grey_text("Settings".localized)).perform(grey_tap())
	}

	/*
	* PASSED if: Log level is changed to "Warning".
	*/
	func testSwitchLogLevel () {
		EarlGrey.waitForElement(accessibilityID: "logging")

		//Actions
		EarlGrey.selectElement(with: grey_accessibilityID("logging")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_text("Warning".localized)).perform(grey_tap())
		EarlGrey.selectElement(with: grey_text("Settings".localized)).perform(grey_tap())

		//Assert
		EarlGrey.selectElement(with: grey_text("Warning".localized)).assert(grey_sufficientlyVisible())
	}

	/*
	* PASSED if: All UI components in Logging view are not displayed when option is disabled.
	*/
	func testCheckLoggingInterfaceLoggingDisabled () {

		//Actions
		EarlGrey.selectElement(with: grey_accessibilityID("logging")).perform(grey_tap())
		EarlGrey.selectElement(with: grey_accessibilityID("enable-logging")).perform(grey_turnSwitchOn(false))

		//Assert
		EarlGrey.selectElement(with: grey_accessibilityID("enable-logging")).assert(grey_switchWithOnState(false))
		EarlGrey.selectElement(with: grey_text("Debug".localized)).assert(grey_notVisible())
		EarlGrey.selectElement(with: grey_text("Info".localized)).assert(grey_notVisible())
		EarlGrey.selectElement(with: grey_text("Warning".localized)).assert(grey_notVisible())
		EarlGrey.selectElement(with: grey_text("Error".localized)).assert(grey_notVisible())

		EarlGrey.selectElement(with: grey_text("Log HTTP requests and responses".localized)).assert(grey_notVisible())
		EarlGrey.selectElement(with: grey_text("Standard error output".localized)).assert(grey_notVisible())
		EarlGrey.selectElement(with: grey_text("Log file".localized)).assert(grey_notVisible())

		//Reset status
		EarlGrey.selectElement(with: grey_accessibilityID("enable-logging")).perform(grey_turnSwitchOn(true))
		EarlGrey.selectElement(with: grey_text("Settings".localized)).perform(grey_tap())
	}

	/*
	* PASSED if: All themes available are displayed
	*/
	func testCheckThemesAvailable () {
		EarlGrey.waitForElement(accessibilityID: "theme")

		//Actions
		EarlGrey.selectElement(with: grey_accessibilityID("theme")).perform(grey_tap())

		//Assert
		EarlGrey.selectElement(with: grey_text("Dark".localized)).assert(grey_sufficientlyVisible())
		EarlGrey.selectElement(with: grey_text("Light".localized)).assert(grey_sufficientlyVisible())
		EarlGrey.selectElement(with: grey_text("Classic".localized)).assert(grey_sufficientlyVisible())

		//Reset status
		EarlGrey.selectElement(with: grey_text("Settings".localized)).perform(grey_tap())
	}

}
