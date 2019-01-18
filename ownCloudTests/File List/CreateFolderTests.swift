//
//  CreateFolderTests.swift
//  ownCloudTests
//
//  Created by Javier Gonzalez on 08/01/2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import XCTest
import EarlGrey
import ownCloudSDK
import ownCloudMocking

@testable import ownCloud

class CreateFolderTests: XCTestCase {

	let hostSimulator: OCHostSimulator = OCHostSimulator()

	override func setUp() {
		super.setUp()
//		hostSimulator.unroutableRequestHandler = { (connection, request, responseHandler) in
//			responseHandler(NSError(domain: kCFErrorDomainCFNetwork, code: kCFHostErrorHostNotFound, userInfo: nil))
//			return true
//		}
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
	* PASSED if: Create Folder view is shown
	*/
	func testShowCreateFolder() {

		if let bookmark: OCBookmark = UtilsTests.getBookmark() {
			//Mocks
			self.mockOCoreForBookmark(mockBookmark: bookmark)
			self.mockQueryPropfindResults(resourceName: "PropfindResponse", basePath: "/remote.php/dav/files/admin", state: .contentsFromCache)
			self.showFileList(bookmark: bookmark)

			//Actions
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("sort-bar.leftButton")).perform(grey_tap())

			//Assets
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("name-text-field")).assert(grey_sufficientlyVisible())

			//Reset status
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel-button")).perform(grey_tap())
		} else {
			assertionFailure("File list not loaded because Bookmark is nil")
		}
	}

	/*
	* PASSED if: A folder is Created Folder
	*/
	func testCreateFolder() {

		if let bookmark: OCBookmark = UtilsTests.getBookmark() {

			let folderName = "New folder"

			//Mocks
			self.mockOCoreForBookmark(mockBookmark: bookmark)
			self.mockQueryPropfindResults(resourceName: "PropfindResponse", basePath: "/remote.php/dav/files/admin", state: .contentsFromCache)
			self.showFileList(bookmark: bookmark)

			//Actions
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("sort-bar.leftButton")).perform(grey_tap())

			//Remove Mocks
			OCMockManager.shared.removeMockingBlock(atLocation: OCMockLocation.ocQueryRequestChangeSetWithFlags)

			//Mock again
			self.mockQueryPropfindResults(resourceName: "PropfindResponseNewFolder", basePath: "/remote.php/dav/files/admin", state: .contentsFromCache)

			EarlGrey.select(elementWithMatcher: grey_accessibilityID("name-text-field")).perform(grey_replaceText(folderName))
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("done-button")).perform(grey_tap())

			//Assets
			let isFolderCreated = GREYCondition(name: "Wait for folder is created", block: {
				var error: NSError?

				//TODO: Validate create folder
				//EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).assert(grey_sufficientlyVisible(), error: &error)

				return error == nil
			}).wait(withTimeout: 5.0, pollInterval: 0.5)

			//Assert
			GREYAssertTrue(isFolderCreated, reason: "Failed to create the folder")
		} else {
			assertionFailure("File list not loaded because Bookmark is nil")
		}
	}

	func showFileList(bookmark: OCBookmark) {
		if let appDelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate {

			let query = MockOCQuery(path: "/")
			let core = MockOCCore(query: query, bookmark: bookmark)
//			core.connection.hostSimulator = self.hostSimulator

			let clientQueryViewController = ClientQueryViewController(core: core, query: query)
			appDelegate.serverListTableViewController?.present(clientQueryViewController, animated: true, completion: nil)
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

//		hostSimulator.unroutableRequestHandler = nil
//
//		let bundle = Bundle.main
//		if let path: String = bundle.path(forResource: resourceName, ofType: "xml") {
//
//			if let data = NSData(contentsOf: URL(fileURLWithPath: path)) {
//				hostSimulator.responseByPath = ["/remote.php/dav/files/admin" : OCHostSimulatorResponse(url: nil,
//																								  statusCode: OCHTTPStatusCode.OK,
//																								  headers: ["Www-Authenticate" : "Bearer realm=\"\", Basic realm=\"\""],
//																								  contentType: "application/xml",
//																								  bodyData: data as Data)]
//			}
//		}

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
