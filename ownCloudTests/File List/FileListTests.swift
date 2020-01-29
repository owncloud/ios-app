//
//  CreateBookmarkTests.swift
//  ownCloudTests
//
//  Created by Javier Gonzalez on 23/10/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import XCTest
import EarlGrey
import ownCloudSDK
import ownCloudMocking

@testable import ownCloud

class FileListTests: FileTests {

	override func setUp() {
		super.setUp()
		OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
		OCMockManager.shared.removeAllMockingBlocks()
	}

	/*
	* PASSED if: Disconnect button appears in the view
	*/
	func testShowFileList() {
		if let bookmark: OCBookmark = UtilsTests.getBookmark() {
			//Mocks
			self.showFileList(bookmark: bookmark)

			EarlGrey.select(elementWithMatcher: grey_accessibilityID("client.file-add")).assert(grey_sufficientlyVisible())

			self.dismissFileList()
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
			self.mockQueryPropfindResults(resourceName: "PropfindResponse", basePath: "/remote.php/dav/files/admin", state: .contentsFromCache)
			self.showFileList(bookmark: bookmark)

			var error:NSError?
			var index: UInt = 0
			while true {
				EarlGrey.select(elementWithMatcher: grey_kindOfClass(ClientItemCell.self)).atIndex(index).assert( grey_notNil(), error: &error)
				if error != nil {
					break
				} else {
					index += 1
				}
			}
			GREYAssertEqual(index as AnyObject, expectedCells as AnyObject, reason: "Founded \(index) cells when expected \(expectedCells)")

			self.dismissFileList()
		} else {
			assertionFailure("File list not loaded because Bookmark is nil")
		}
	}

}
