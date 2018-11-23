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
		OCMockManager.shared.removeAllMockingBlocks()
		UtilsTests.deleteAllBookmarks()
		UtilsTests.showNoServerMessageServerList()
	}

	override func tearDown() {
		super.tearDown()
	}

	func testCheckInitialViewAuth () {

		if let bookmark: OCBookmark = UtilsTests.getBookmark() {

			OCBookmarkManager.shared.addBookmark(bookmark)
			UtilsTests.showNoServerMessageServerList()

			EarlGrey.select(elementWithMatcher: grey_accessibilityID("server-bookmark-cell")).perform(grey_swipeFastInDirection(.left))
			EarlGrey.select(elementWithMatcher: grey_text("Edit".localized)).perform(grey_tap())
//
			//Assert
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-auth-data-delete")).assert(grey_sufficientlyVisible())
//
//			//Reset status
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
			UtilsTests.deleteAllBookmarks()
		}
	}
}
