//
//  EditBookmarkTests.swift
//  ownCloudTests
//
//  Created by Javier Gonzalez on 23/11/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import XCTest
import EarlGrey
import ownCloudSDK
import ownCloudMocking

@testable import ownCloud

class EditBookmarkTests: XCTestCase {

	override func setUp() {
		super.setUp()
		OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
	}

	override func tearDown() {
		super.tearDown()
		OCMockManager.shared.removeAllMockingBlocks()
	}

	/*
	 * PASSED if: URL and Delete Auth Data displayed
	 */
	func testCheckInitialViewEditBasicAuth () {

		if let bookmark: OCBookmark = UtilsTests.getBookmark() {

			OCBookmarkManager.shared.addBookmark(bookmark)
			EarlGrey.waitForElementMissing(accessibilityID: "addServer")

			//Actions
			EarlGrey.select(elementWithMatcher: grey_allOf([grey_accessibilityID("server-bookmark-cell"), grey_sufficientlyVisible()])).perform(grey_swipeFastInDirection(.left))
			EarlGrey.select(elementWithMatcher: grey_text("Edit".localized)).perform(grey_tap())

			//Assert
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-auth-data-delete")).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).assert(grey_sufficientlyVisible())

			//Reset status
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
			OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
		}
	}

	/*
	 * PASSED if: URL, Delete Auth Data and Authentication message displayed if OAuth2
	 */
	func testCheckInitialViewEditOAuth2 () {

		if let bookmark: OCBookmark = UtilsTests.getBookmark(authenticationMethod: OCAuthenticationMethodIdentifier.oAuth2) {

			OCBookmarkManager.shared.addBookmark(bookmark)
			EarlGrey.waitForElementMissing(accessibilityID: "addServer")

			//Actions
			EarlGrey.select(elementWithMatcher: grey_allOf([grey_accessibilityID("server-bookmark-cell"), grey_sufficientlyVisible()])).perform(grey_swipeFastInDirection(.left))
			EarlGrey.select(elementWithMatcher: grey_text("Edit".localized)).perform(grey_tap())

			//Assert
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).assert(grey_notVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).assert(grey_notVisible())
			EarlGrey.select(elementWithMatcher: grey_text("Authenticated via OAuth2".localized)).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-auth-data-delete")).assert(grey_sufficientlyVisible())

			//Reset status
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
			OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
		}
	}

	/*
	* PASSED if: View cancelled, credentials' fields are not displayed. Server Bookmark cell displayed
	*/
	func testCheckCancelEditView () {

		if let bookmark: OCBookmark = UtilsTests.getBookmark() {

			OCBookmarkManager.shared.addBookmark(bookmark)
			EarlGrey.waitForElementMissing(accessibilityID: "addServer")

			//Actions
			EarlGrey.select(elementWithMatcher: grey_allOf([grey_accessibilityID("server-bookmark-cell"), grey_sufficientlyVisible()])).perform(grey_swipeFastInDirection(.left))
			EarlGrey.select(elementWithMatcher: grey_text("Edit".localized)).perform(grey_tap())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())

			//Assert
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("server-bookmark-cell")).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).assert(grey_notVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-auth-data-delete")).assert(grey_notVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).assert(grey_notVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).assert(grey_notVisible())

			//Reset status
			OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
		}
	}

	 /*
	 * PASSED if: Server name has change to "New name"
	 */
	func testCheckEditServerName () {

		let expectedServerName = "New name"

		if let bookmark: OCBookmark = UtilsTests.getBookmark() {

			OCBookmarkManager.shared.addBookmark(bookmark)
			EarlGrey.waitForElementMissing(accessibilityID: "addServer")

			//Actions
			EarlGrey.select(elementWithMatcher: grey_allOf([grey_accessibilityID("server-bookmark-cell"), grey_sufficientlyVisible()])).perform(grey_swipeFastInDirection(.left))
			EarlGrey.select(elementWithMatcher: grey_text("Edit".localized)).perform(grey_tap())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-name-name")).perform(grey_replaceText(expectedServerName))
			EarlGrey.select(elementWithMatcher: grey_text("Save".localized)).perform(grey_tap())

			//Assert
			EarlGrey.select(elementWithMatcher: grey_text(expectedServerName)).assert(grey_sufficientlyVisible())

			//Reset status
			OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
		}
	}

	/*
	* PASSED if: After removing the password, Delete Authentication is hidden and Continue is displayed
	*/
	func testCheckEditRemovingPasswordBasicAuth () {

		if let bookmark: OCBookmark = UtilsTests.getBookmark() {

			OCBookmarkManager.shared.addBookmark(bookmark)
			EarlGrey.waitForElementMissing(accessibilityID: "addServer")

			//Actions
			EarlGrey.select(elementWithMatcher: grey_allOf([grey_accessibilityID("server-bookmark-cell"), grey_sufficientlyVisible()])).perform(grey_swipeFastInDirection(.left))
			EarlGrey.select(elementWithMatcher: grey_text("Edit".localized)).perform(grey_tap())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).perform(grey_replaceText(""))
			//EarlGrey.select(elementWithMatcher: grey_text("Save".localized)).perform(grey_tap())

			//Assert
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("server-bookmark-cell")).assert(grey_notVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-auth-data-delete")).assert(grey_notVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-continue-continue")).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).assert(grey_sufficientlyVisible())

			//Reset status
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
			OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
		}
	}

	/*
	 * PASSED if: Credential fields not displayed after clicking in "Delete Authentication Data"
	 */
	func testCheckEditDeleteAuthenticationDataBasicAuth () {

		if let bookmark: OCBookmark = UtilsTests.getBookmark() {

			OCBookmarkManager.shared.addBookmark(bookmark)
			EarlGrey.waitForElementMissing(accessibilityID: "addServer")

			//Actions
			EarlGrey.select(elementWithMatcher: grey_allOf([grey_accessibilityID("server-bookmark-cell"), grey_sufficientlyVisible()])).perform(grey_swipeFastInDirection(.left))
			EarlGrey.select(elementWithMatcher: grey_text("Edit".localized)).perform(grey_tap())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-auth-data-delete")).perform(grey_tap())

			//Assert
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).assert(grey_notVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).assert(grey_notVisible())

			//Reset status
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
			OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
		}
	}

	/*
	 * PASSED if: Credential fields not displayed after clicking in "Delete Authentication Data"
	 */
	func testCheckEditDeleteAuthenticationDataOAuth2 () {

		if let bookmark: OCBookmark = UtilsTests.getBookmark(authenticationMethod: OCAuthenticationMethodIdentifier.oAuth2) {

			OCBookmarkManager.shared.addBookmark(bookmark)
			EarlGrey.waitForElementMissing(accessibilityID: "addServer")

			//Actions
			EarlGrey.select(elementWithMatcher: grey_allOf([grey_accessibilityID("server-bookmark-cell"), grey_sufficientlyVisible()])).perform(grey_swipeFastInDirection(.left))
			EarlGrey.select(elementWithMatcher: grey_text("Edit".localized)).perform(grey_tap())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-auth-data-delete")).perform(grey_tap())

			//Assert
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).assert(grey_notVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).assert(grey_notVisible())

			//Reset status
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
			OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
		}
	}
}
