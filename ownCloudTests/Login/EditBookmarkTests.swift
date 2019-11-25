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
			EarlGrey.select(elementWithMatcher: grey_text("If you 'Continue', you will be prompted to allow the 'ownCloud' App to open OAuth2 login where you can enter your credentials.".localized)).assert(grey_sufficientlyVisible())

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
			
			
			let mockUrlServer = "http://mocked.owncloud.server.com"
			let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodIdentifier.oAuth2,
																   OCAuthenticationMethodIdentifier.basicAuth]
			let issue: OCIssue = OCIssue(forError: NSError(domain: "mocked.owncloud.server.com", code: 1033, userInfo: [NSLocalizedDescriptionKey: "Error description"]), level: .informal, issueHandler: nil)
			
			let authenticationMethodIdentifier = OCAuthenticationMethodIdentifier.oAuth2
			let tokenResponse:[String : String] = ["access_token" : "RyFyDu1wH0Wvd8KlCP0Qeo9dlTqWajgvWHNqSdfl9bVD6Wp72CGikmgSkvUaAMML",
												   "expires_in" : "3600",
												   "message_url" : "https://localhost/apps/oauth2/authorization-successful",
												   "refresh_token" : "khA8H18TWC84g1DmB0fzqgDOWvNRNPGJkkzQ1E6AZjq8UrqZ79QTK8UgSsJB6MrW",
												   "token_type" : "Bearer",
												   "user_id" : "admin"]
			let dictionary:[String : Any] = ["bearerString" : "Bearer RyFyDu1wH0Wvd8KlCP0Qeo9dlTqWajgvWHNqSdfl9bVD6Wp72CGikmgSkvUaAMML",
											 "expirationDate" : NSDate.distantPast,
											 "tokenResponse" : tokenResponse]
			let error: NSError?  = nil
			let user: OCUser = OCUser.init()
			user.displayName = "Admin"
			
			//Mock
			UtilsTests.mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)
			UtilsTests.mockOCConnectionGenerateAuthenticationData(authenticationMethodIdentifier: authenticationMethodIdentifier, dictionary: dictionary, error: error)
			UtilsTests.mockOCConnectionConnectWithCompletionHandler(issue: issue, user: user, error: error)
			UtilsTests.mockOCConnectionDisconnectWithCompletionHandler()

			//Actions
			EarlGrey.select(elementWithMatcher: grey_allOf([grey_accessibilityID("server-bookmark-cell"), grey_sufficientlyVisible()])).perform(grey_swipeFastInDirection(.left))
			EarlGrey.select(elementWithMatcher: grey_text("Edit".localized)).perform(grey_tap())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-name-name")).perform(grey_replaceText(expectedServerName))
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("continue-bar-button")).perform(grey_tap())

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

			//Assert
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).assert(grey_sufficientlyVisible())

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

			//Assert
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).assert(grey_notVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).assert(grey_notVisible())

			//Reset status
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
			OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
		}
	}

	/*
	* PASSED if: After deleting authentication data, warning is displayed
	*/
	func testCheckEditWarningOAuth2 () {

		if let bookmark: OCBookmark = UtilsTests.getBookmark(authenticationMethod: OCAuthenticationMethodIdentifier.oAuth2) {

			OCBookmarkManager.shared.addBookmark(bookmark)
			EarlGrey.waitForElementMissing(accessibilityID: "addServer")

			//Actions
			EarlGrey.select(elementWithMatcher: grey_allOf([grey_accessibilityID("server-bookmark-cell"), grey_sufficientlyVisible()])).perform(grey_swipeFastInDirection(.left))
			EarlGrey.select(elementWithMatcher: grey_text("Edit".localized)).perform(grey_tap())

			let isServerChecked = GREYCondition(name: "Wait for server is checked", block: {
				var error: NSError?

				//Assert
				EarlGrey.select(elementWithMatcher: grey_text("If you 'Continue', you will be prompted to allow the ownCloud App to open OAuth2 login where you can enter your credentials.".localized)).assert(grey_sufficientlyVisible(), error: &error)

				return error == nil
			}).wait(withTimeout: 5.0, pollInterval: 0.5)

			GREYAssertTrue(!isServerChecked, reason: "Failed check the server")

			//Reset status
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
			OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
		}
	}

	/*
	* PASSED if: After deleting authentication data, "Warning" level of certificate is displayed
	*/
	func testCheckEditCertificateWarning () {

		if let bookmark: OCBookmark = UtilsTests.getBookmark(authenticationMethod: OCAuthenticationMethodIdentifier.oAuth2, certifUserApproved: false) {

			OCBookmarkManager.shared.addBookmark(bookmark)
			EarlGrey.waitForElementMissing(accessibilityID: "addServer")

			//Actions
			EarlGrey.select(elementWithMatcher: grey_allOf([grey_accessibilityID("server-bookmark-cell"), grey_sufficientlyVisible()])).perform(grey_swipeFastInDirection(.left))
			EarlGrey.select(elementWithMatcher: grey_text("Edit".localized)).perform(grey_tap())

			//Asserts
			EarlGrey.select(elementWithMatcher: grey_text("Warning".localized)).assert(grey_sufficientlyVisible())

			//Reset status
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
			OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
		}
	}

	/*
	* PASSED if: After deleting authentication data, "Accepted" level of certificate is displayed
	*/
	func testCheckEditCertificateAccepted () {

		if let bookmark: OCBookmark = UtilsTests.getBookmark(authenticationMethod: OCAuthenticationMethodIdentifier.oAuth2, certifUserApproved: true) {

			OCBookmarkManager.shared.addBookmark(bookmark)
			EarlGrey.waitForElementMissing(accessibilityID: "addServer")

			//Actions
			EarlGrey.select(elementWithMatcher: grey_allOf([grey_accessibilityID("server-bookmark-cell"), grey_sufficientlyVisible()])).perform(grey_swipeFastInDirection(.left))
			EarlGrey.select(elementWithMatcher: grey_text("Edit".localized)).perform(grey_tap())

			//Asserts
			EarlGrey.select(elementWithMatcher: grey_text("Accepted".localized)).assert(grey_sufficientlyVisible())

			//Reset status
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
			OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
		}
	}
}
