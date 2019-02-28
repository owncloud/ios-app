//
//  MoreViewTests.swift
//  ownCloudTests
//
//  Created by Javier Gonzalez on 21/02/2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
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

class MoreViewTests: XCTestCase {

	override func setUp() {
		super.setUp()
		OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
		OCMockManager.shared.removeAllMockingBlocks()
	}

	override func tearDown() {
		super.tearDown()
		OCMockManager.shared.removeAllMockingBlocks()
	}

	/*
	* PASSED if: MoreView is shown with file options
	*/
	func testShowMoreViewForFile() {

		if let bookmark: OCBookmark = UtilsTests.getBookmark() {
			//Mocks
			OCMockSwizzlingFileList.mockOCoreForBookmark(mockBookmark: bookmark)
			OCMockSwizzlingFileList.mockQueryPropfindResults(resourceName: "PropfindResponse", basePath: "/remote.php/dav/files/admin", state: .contentsFromCache)
			UtilsTests.showFileList(bookmark: bookmark)

			//Actions
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("ownCloud Manual.pdf-actions")).perform(grey_tap())

			//Asserts
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("com.owncloud.action.openin")).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("com.owncloud.action.move")).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("com.owncloud.action.rename")).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("com.owncloud.action.duplicate")).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("com.owncloud.action.copy")).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("com.owncloud.action.delete")).assert(grey_sufficientlyVisible())

			//Reset status
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("dimming-view")).perform(grey_tap())
			EarlGrey.select(elementWithMatcher: grey_allOf([grey_accessibilityLabel("Back"), grey_accessibilityTrait(UIAccessibilityTraits.staticText)])).perform(grey_tap())
		} else {
			assertionFailure("File list not loaded because Bookmark is nil")
		}
	}

	/*
	* PASSED PASSED if: MoreView is shown with folder options
	*/
	func testShowMoreViewForFolder() {

		if let bookmark: OCBookmark = UtilsTests.getBookmark() {
			//Mocks
			OCMockSwizzlingFileList.mockOCoreForBookmark(mockBookmark: bookmark)
			OCMockSwizzlingFileList.mockQueryPropfindResults(resourceName: "PropfindResponse", basePath: "/remote.php/dav/files/admin", state: .contentsFromCache)
			UtilsTests.showFileList(bookmark: bookmark)

			//Actions
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("Documents-actions")).perform(grey_tap())

			//Asserts
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("com.owncloud.action.openin")).assert(grey_notVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("com.owncloud.action.move")).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("com.owncloud.action.rename")).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("com.owncloud.action.duplicate")).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("com.owncloud.action.copy")).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("com.owncloud.action.delete")).assert(grey_sufficientlyVisible())

			//Reset status
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("dimming-view")).perform(grey_tap())
			EarlGrey.select(elementWithMatcher: grey_allOf([grey_accessibilityLabel("Back"), grey_accessibilityTrait(UIAccessibilityTraits.staticText)])).perform(grey_tap())
		} else {
			assertionFailure("File list not loaded because Bookmark is nil")
		}
	}
}
