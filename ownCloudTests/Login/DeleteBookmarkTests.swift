//
//  DeleteBookmarkTests.swift
//  ownCloudTests
//
//  Created by Jesus Recio (@jesmrec) on 11/12/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import XCTest
import EarlGrey
import ownCloudSDK
import ownCloudMocking

@testable import ownCloud

class DeleteBookmarkTests: XCTestCase {

	override func setUp() {
		super.setUp()
		OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
	}

	override func tearDown() {
		super.tearDown()
		OCMockManager.shared.removeAllMockingBlocks()
		OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
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
			EarlGrey.selectElement(with: grey_text(bookmarkName)).perform(grey_swipeSlowInDirection(.left))

			EarlGrey.selectElement(with: grey_text("Delete".localized)).perform(grey_tap())
			if !EarlGrey.waitForElementMissing(withMatcher: grey_text("Delete".localized), label: "Wait for deletion", timeout: 2.0) {
				EarlGrey.selectElement(with: grey_text("Delete".localized)).perform(grey_tap())
			}

			let isBookmarkDeleted = GREYCondition(name: "Waiting for bookmark removal", block: {
				var error: NSError?

				//Assert
				EarlGrey.selectElement(with: grey_text(bookmarkName)).assert(grey_notVisible(), error: &error)
				EarlGrey.selectElement(with: grey_accessibilityID("addServer")).assert(grey_sufficientlyVisible(), error: &error)

				return error == nil
			}).wait(withTimeout: 10.0, pollInterval: 0.5)

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
				EarlGrey.selectElement(with: grey_text(bookmarkName1)).perform(grey_swipeSlowInDirection(.left))

				EarlGrey.selectElement(with: grey_text("Delete".localized)).perform(grey_tap())
				if !EarlGrey.waitForElementMissing(withMatcher: grey_text("Delete".localized), label: "Wait for deletion", timeout: 2.0) {
					EarlGrey.selectElement(with: grey_text("Delete".localized)).perform(grey_tap())
				}

				let isBookmarkDeleted = GREYCondition(name: "Waiting for bookmark removal", block: {
					var error: NSError?

					//Assert
					EarlGrey.selectElement(with: grey_text(bookmarkName1)).assert(grey_notVisible(), error: &error)
					EarlGrey.selectElement(with: grey_text(bookmarkName2)).assert(grey_sufficientlyVisible(), error: &error)

					return error == nil
				}).wait(withTimeout: 10.0, pollInterval: 0.5)

				GREYAssertTrue(isBookmarkDeleted, reason: "Failed bookmark removal")

				//Reset status
				OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
			}
		}
	}
}
