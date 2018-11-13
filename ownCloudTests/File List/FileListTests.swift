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

class FileListTests: XCTestCase {

	override func setUp() {
		super.setUp()
		UtilsTests.deleteAllBookmarks()
		UtilsTests.showNoServerMessageServerList()
	}

	override func tearDown() {
		super.tearDown()
	}

	public typealias OCMRequestCoreForBookmarkCompletionHandler = @convention(block)
		(_ core: OCCore, _ error: NSError?) -> Void

	public typealias OCMRequestCoreForBookmark = @convention(block)
		(_ bookmark: OCBookmark, _ completionHandler: OCMRequestCoreForBookmarkCompletionHandler) -> OCCore

	func testShowFileList() {

		if let bookmark: OCBookmark = UtilsTests.getBookmark() {
			//Mocks
			self.mockOCoreForBookmark(mockBookmark: bookmark)
			self.showFileList(bookmark: bookmark)

			//Assets
			EarlGrey.select(elementWithMatcher: grey_text("Disconnect".localized)).assert(grey_sufficientlyVisible())
		} else {
			assertionFailure("File list not loaded because Bookmark is nil")
		}
	}

	func showFileList(bookmark: OCBookmark) {
		let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
		let clientRootViewController = ClientRootViewController(bookmark: bookmark)

		appDelegate.serverListTableViewController?.present(clientRootViewController, animated: true, completion: nil)
	}

	// MARK: - Mocks
	func mockOCoreForBookmark(mockBookmark: OCBookmark) {
		let completionHandlerBlock : OCMRequestCoreForBookmark = {
			(bookmark, mockedBlock) in
			let core = OCCore(bookmark: mockBookmark)
			mockedBlock(core, nil)
			return core
		}

		OCMockManager.shared.addMocking(blocks: [OCMockLocation.ocCoreManagerRequestCoreForBookmark: completionHandlerBlock])
	}
}
