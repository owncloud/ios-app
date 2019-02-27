//
//  CreateBookmarkTests.swift
//  ownCloudTests
//
//  Created by Javier Gonzalez on 23/10/2018.
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

class FileListTests: XCTestCase {

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
	* PASSED if: Disconnect button appears in the view
	*/
	func testShowFileList() {
		if let bookmark: OCBookmark = UtilsTests.getBookmark() {
			//Mocks
			OCMockSwizzlingFileList.mockOCoreForBookmark(mockBookmark: bookmark)
			self.showFileList(bookmark: bookmark)

			//Asserts
			EarlGrey.select(elementWithMatcher: grey_allOf([grey_accessibilityLabel("Back"), grey_accessibilityTrait(UIAccessibilityTraits.staticText)])).assert(grey_sufficientlyVisible())

			//Reset status
			EarlGrey.select(elementWithMatcher: grey_allOf([grey_accessibilityLabel("Back"), grey_accessibilityTrait(UIAccessibilityTraits.staticText)])).perform(grey_tap())

		} else {
			assertionFailure("File list not loaded because Bookmark is nil")
		}
	}

	/*
	* PASSED if: The expected files/folders appear in the list
	*/
	func testShowFileListWithItems() {
		let expectedCells: Int = 3

		if let bookmark: OCBookmark = UtilsTests.getBookmark() {
			//Mocks
			OCMockSwizzlingFileList.mockOCoreForBookmark(mockBookmark: bookmark)
			OCMockSwizzlingFileList.mockQueryPropfindResults(resourceName: "PropfindResponse", basePath: "/remote.php/dav/files/admin", state: .contentsFromCache)
			self.showFileList(bookmark: bookmark)
			
			//Asserts
			EarlGrey.select(elementWithMatcher: grey_allOf([grey_accessibilityLabel("Back"), grey_accessibilityTrait(UIAccessibilityTraits.staticText)])).assert(grey_sufficientlyVisible())

			var error:NSError?
			var index: UInt = 0
			while true {
				EarlGrey.select(elementWithMatcher: grey_kindOfClass(ClientItemCell.self)).atIndex(index).assert(with: grey_notNil(), error: &error)
				if error != nil {
					break
				} else {
					index += 1
				}
			}
			GREYAssertEqual(index as AnyObject, expectedCells as AnyObject, reason: "Founded \(index) cells when expected \(expectedCells)")
			
			//Asserts
			EarlGrey.select(elementWithMatcher: grey_allOf([grey_accessibilityLabel("Back"), grey_accessibilityTrait(UIAccessibilityTraits.staticText)])).assert(grey_sufficientlyVisible())

			//Reset status
			EarlGrey.select(elementWithMatcher: grey_allOf([grey_accessibilityLabel("Back"), grey_accessibilityTrait(UIAccessibilityTraits.staticText)])).perform(grey_tap())
		} else {
			assertionFailure("File list not loaded because Bookmark is nil")
		}
	}

	func showFileList(bookmark: OCBookmark) {
		if let appDelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate {
			let clientRootViewController = ClientRootViewController(bookmark: bookmark)

			appDelegate.serverListTableViewController?.navigationController?.navigationBar.prefersLargeTitles = false
			appDelegate.serverListTableViewController?.navigationController?.navigationItem.largeTitleDisplayMode = .never
			appDelegate.serverListTableViewController?.navigationController?.pushViewController(viewController: clientRootViewController, animated: true, completion: {
				appDelegate.serverListTableViewController?.navigationController?.setNavigationBarHidden(true, animated: false)
			})
		}
	}
}
