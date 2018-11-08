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

	func testShowFileList() {
		if let bookmark: OCBookmark = UtilsTests.getBookmark() {
			let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
			let clientRootViewController = ClientRootViewController(bookmark: bookmark)

			appDelegate.serverListTableViewController?.present(clientRootViewController, animated: true, completion: nil)
		} else {
			assertionFailure()
		}
	}
}
