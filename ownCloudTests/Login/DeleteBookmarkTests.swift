//
//  DeleteBookmarkTests.swift
//  ownCloudTests
//
//  Created by Jesus Recio (@jesmrec) on 11/12/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2019, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import XCTest
import EarlGrey
import ownCloudSDK
import ownCloudMocking

@testable import ownCloud

class DeleteBookmarkTests: XCTestCase {

	override func setUp() {
		super.setUp()
	}

	override func tearDown() {
		super.tearDown()
		OCMockManager.shared.removeAllMockingBlocks()
	}

	/*
	* PASSED if: If the bookmark is deleted, and initial View displayed
	*/
	func testDeleteTheOnlyBookmark () {

		let bookmarkName: String = "BookmarkA"

		if let bookmark: OCBookmark = UtilsTests.getBookmark(bookmarkName: bookmarkName) {

			OCBookmarkManager.shared.addBookmark(bookmark)
			EarlGrey.waitForElementMissing(accessibilityID: "addServer")

			//Actions
			EarlGrey.select(elementWithMatcher: grey_text(bookmarkName)).perform(grey_swipeFastInDirection(.left))
			EarlGrey.select(elementWithMatcher: grey_text("Delete".localized)).perform(grey_tap())
			EarlGrey.select(elementWithMatcher: grey_text("Delete".localized)).perform(grey_tap())

			let isBookmarkDeleted = GREYCondition(name: "Waiting for bookmark removal", block: {
				var error: NSError?

				//Assert
				EarlGrey.select(elementWithMatcher: grey_text(bookmarkName)).assert(grey_notVisible(), error: &error)
				EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).assert(grey_sufficientlyVisible(), error: &error)

				return error == nil
			}).wait(withTimeout: 2.0, pollInterval: 0.5)

			GREYAssertTrue(isBookmarkDeleted, reason: "Failed bookmark removal")

			//Reset status
			OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
		}
	}

	/*
	* PASSED if: Deleted bookmark not displayed, other bookmark displayed
	*/
	func testDeleteOneBookmarkAndOtherRemains () {

		let bookmarkName1: String = "Bookmark1"
		let bookmarkName2: String = "Bookmark2"

		if let bookmark1: OCBookmark = UtilsTests.getBookmark(bookmarkName: bookmarkName1) {
			if let bookmark2: OCBookmark = UtilsTests.getBookmark(bookmarkName: bookmarkName2) {

				OCBookmarkManager.shared.addBookmark(bookmark1)
				OCBookmarkManager.shared.addBookmark(bookmark2)
				EarlGrey.waitForElementMissing(accessibilityID: "addServer")

				//Actions
				EarlGrey.select(elementWithMatcher: grey_text(bookmarkName1)).perform(grey_swipeFastInDirection(.left))
				EarlGrey.select(elementWithMatcher: grey_text("Delete".localized)).perform(grey_tap())
				EarlGrey.select(elementWithMatcher: grey_text("Delete".localized)).perform(grey_tap())

				let isBookmarkDeleted = GREYCondition(name: "Waiting for bookmark removal", block: {
					var error: NSError?

					//Assert
					EarlGrey.select(elementWithMatcher: grey_text(bookmarkName1)).assert(grey_notVisible(), error: &error)
					EarlGrey.select(elementWithMatcher: grey_text(bookmarkName2)).assert(grey_sufficientlyVisible(), error: &error)

					return error == nil
				}).wait(withTimeout: 2.0, pollInterval: 0.5)

				GREYAssertTrue(isBookmarkDeleted, reason: "Failed bookmark removal")

				//Reset status
				OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
			}
		}
	}
}
