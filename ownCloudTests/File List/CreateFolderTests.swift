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

			//Asserts
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("name-text-field")).assert(grey_sufficientlyVisible())

			//Reset status
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel-button")).perform(grey_tap())
			dismissFileList()
		} else {
			assertionFailure("File list not loaded because Bookmark is nil")
		}
	}

	/*
	* PASSED if: A folder is created
	*/
	func testCreateFolder() {

		if let bookmark: OCBookmark = UtilsTests.getBookmark() {

			let folderName = "New Folder"

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

			//Assert
			let isFolderCreated = GREYCondition(name: "Wait for folder is created", block: {
				var error: NSError?

				EarlGrey.select(elementWithMatcher: grey_accessibilityID(folderName)).assert(grey_sufficientlyVisible(), error: &error)

				return error == nil
			}).wait(withTimeout: 5.0, pollInterval: 0.5)

			GREYAssertTrue(isFolderCreated, reason: "Failed to create the folder")

			//Reset status
			dismissFileList()

		} else {
			assertionFailure("File list not loaded because Bookmark is nil")
		}
	}

	/*
	* PASSED if: Done button is disabled with empty name
	*/
	func testDisableButtonCreateFolderWithEmptyName() {

		if let bookmark: OCBookmark = UtilsTests.getBookmark() {

			let folderName = ""

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

			//Assert
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("done-button")).assert(grey_not(grey_enabled()))

			//Reset status
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel-button")).perform(grey_tap())
			dismissFileList()
		} else {
			assertionFailure("File list not loaded because Bookmark is nil")
		}
	}

	/*
	* PASSED if: Done button is enabled with a valid name
	*/
	func testEnableButtonCreateFolderWithValidName() {

		if let bookmark: OCBookmark = UtilsTests.getBookmark() {

			let folderName = "Valid Name"

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

			//Assert
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("done-button")).assert(grey_enabled())

			//Reset status
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel-button")).perform(grey_tap())
			dismissFileList()
		} else {
			assertionFailure("File list not loaded because Bookmark is nil")
		}
	}

	/*
	* PASSED if: Done if Forbidden Characters Alert appears
	*/
	func testCreateFolderWithInvalidCharacters() {

		if let bookmark: OCBookmark = UtilsTests.getBookmark() {

			let folderName = "New/Folder"

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

			//Assert
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("forbidden-characters-alert")).assert(grey_sufficientlyVisible())

			//Reset status
			EarlGrey.select(elementWithMatcher: grey_text("OK".localized)).perform(grey_tap())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel-button")).perform(grey_tap())
			dismissFileList()
		} else {
			assertionFailure("File list not loaded because Bookmark is nil")
		}
	}

	/*
	* PASSED if: Error is shown on the view
	*/
	func testCreateFolderWithExistingName() {

		if let bookmark: OCBookmark = UtilsTests.getBookmark() {

			let folderName = "New Folder"
			let errorTitle = "Error title"
			let errorMessage = "Error message"

			//Mocks
			self.mockOCoreForBookmark(mockBookmark: bookmark)
			self.mockQueryPropfindResults(resourceName: "PropfindResponseNewFolder", basePath: "/remote.php/dav/files/admin", state: .contentsFromCache)

			let issue: OCIssue = OCIssue(forMultipleChoicesWithLocalizedTitle: errorTitle, localizedDescription: errorMessage, choices: [OCIssueChoice(type: .cancel, identifier: nil, label: "Cancel".localized, userInfo: nil, handler: nil)]) { (issue, decission) in
			}

			self.showFileList(bookmark: bookmark, issue: issue)

			//Actions
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("sort-bar.leftButton")).perform(grey_tap())

			EarlGrey.select(elementWithMatcher: grey_accessibilityID("name-text-field")).perform(grey_replaceText(folderName))
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("done-button")).perform(grey_tap())

			//Assert
			EarlGrey.select(elementWithMatcher: grey_text(errorTitle)).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_text(errorMessage)).assert(grey_sufficientlyVisible())

			//Reset status
			EarlGrey.select(elementWithMatcher: grey_text("Cancel".localized)).perform(grey_tap())
			dismissFileList()

		} else {
			assertionFailure("File list not loaded because Bookmark is nil")
		}
	}

	func showFileList(bookmark: OCBookmark, issue: OCIssue? = nil) {
		if let appDelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate {

			let query = MockOCQuery(path: "/")
			let core = MockOCCore(query: query, bookmark: bookmark, issue: issue)

			let rootViewController: MockClientRootViewController = MockClientRootViewController(core: core, query: query, bookmark: bookmark)

			//let clientQueryViewController = ClientQueryViewController(core: core, query: query)
			appDelegate.serverListTableViewController?.present(rootViewController, animated: true, completion: nil)
		}
	}

	func dismissFileList() {
		if let appDelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate {
			appDelegate.serverListTableViewController?.dismiss(animated: true, completion: nil)
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
