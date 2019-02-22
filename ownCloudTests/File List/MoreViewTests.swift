//
//  MoreViewTests.swift
//  ownCloudTests
//
//  Created by Javier Gonzalez on 21/02/2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

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

	public typealias OCMRequestCoreForBookmarkCompletionHandler = @convention(block)
		(_ core: OCCore, _ error: NSError?) -> Void

	public typealias OCMRequestCoreForBookmark = @convention(block)
		(_ bookmark: OCBookmark, _ completionHandler: OCMRequestCoreForBookmarkCompletionHandler) -> OCCore

	public typealias OCMRequestChangeSetWithFlags = @convention(block)
		(_ flags: OCQueryChangeSetRequestFlag, _ completionHandler: OCQueryChangeSetRequestCompletionHandler) -> Void

	/*
	* PASSED if: MoreView is shown with file options
	*/
	func testShowMoreViewForFile() {

		if let bookmark: OCBookmark = UtilsTests.getBookmark() {
			//Mocks
			self.mockOCoreForBookmark(mockBookmark: bookmark)
			self.mockQueryPropfindResults(resourceName: "PropfindResponse", basePath: "/remote.php/dav/files/admin", state: .contentsFromCache)
			self.showFileList(bookmark: bookmark)

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
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("disconnect-button")).perform(grey_tap())
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
			self.mockOCoreForBookmark(mockBookmark: bookmark)
			self.mockQueryPropfindResults(resourceName: "PropfindResponse", basePath: "/remote.php/dav/files/admin", state: .contentsFromCache)
			self.showFileList(bookmark: bookmark)

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
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("disconnect-button")).perform(grey_tap())
		} else {
			assertionFailure("File list not loaded because Bookmark is nil")
		}
	}

	func showFileList(bookmark: OCBookmark) {
		if let appDelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate {
			let clientRootViewController = ClientRootViewController(bookmark: bookmark)

			appDelegate.serverListTableViewController?.present(clientRootViewController, animated: true, completion: nil)
		}
	}

	// MARK: - Mocks
	func mockOCoreForBookmark(mockBookmark: OCBookmark) {
		let completionHandlerBlock : OCMRequestCoreForBookmark = { (bookmark, mockedBlock) in
			let core = OCCore(bookmark: mockBookmark)
			mockedBlock(core, nil)
			return core
		}

		OCMockManager.shared.addMocking(blocks: [OCMockLocation.ocCoreManagerRequestCoreForBookmark: completionHandlerBlock])
	}

	func mockQueryPropfindResults(resourceName: String, basePath: String, state: OCQueryState) {
		let completionHandlerBlock : OCMRequestChangeSetWithFlags = { (flags, mockedBlock) in

			var items: [OCItem]?

			let bundle = Bundle.main
			if let path: String = bundle.path(forResource: resourceName, ofType: "xml") {

				if let data = NSData(contentsOf: URL(fileURLWithPath: path)) {
					if let parser = OCXMLParser(data: data as Data) {
						parser.options = ["basePath": basePath]
						parser.addObjectCreationClasses([OCItem.self])
						if parser.parse() {
							items = parser.parsedObjects as? [OCItem]
						}
					}
				}
			}

			items?.removeFirst()

			let querySet: OCQueryChangeSet = OCQueryChangeSet(queryResult: items, relativeTo: nil)
			let query: OCQuery = OCQuery()
			query.state = state

			mockedBlock(query, querySet)
		}

		OCMockManager.shared.addMocking(blocks: [OCMockLocation.ocQueryRequestChangeSetWithFlags: completionHandlerBlock])
	}
}
