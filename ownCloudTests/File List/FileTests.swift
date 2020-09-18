//
//  FileTests.swift
//  ownCloudTests
//  Base class for tests related to file list view
//
//  Created by Javier Gonzalez on 23/10/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import XCTest
import EarlGrey
import ownCloudSDK
import ownCloudMocking
import ownCloudAppShared

@testable import ownCloud

class FileTests: XCTestCase {

	public typealias OCMRequestCoreForBookmarkCompletionHandler = @convention(block)
		(_ core: OCCore, _ error: NSError?) -> Void

	public typealias OCMRequestCoreForBookmarkSetupHandler = @convention(block)
		(_ core: OCCore, _ error: NSError?) -> Void

	public typealias OCMRequestCoreForBookmark = @convention(block)
		(_ bookmark: OCBookmark, _ setup: OCMRequestCoreForBookmarkSetupHandler, _ completionHandler: OCMRequestCoreForBookmarkCompletionHandler) -> Void

	public typealias OCMRequestChangeSetWithFlags = @convention(block)
		(_ flags: OCQueryChangeSetRequestFlag, _ completionHandler: OCQueryChangeSetRequestCompletionHandler) -> Void

	// MARK: - XCTestCase overrides

	override func tearDown() {
		super.tearDown()
		OCMockManager.shared.removeAllMockingBlocks()
	}

	// MARK: - UI Helpers

	func showFileList(bookmark: OCBookmark, issue: OCIssue? = nil) {
		let query = MockOCQuery(path: "/")
		let core = MockOCCore(query: query, bookmark: bookmark, issue: issue)

		self.mockOCoreForBookmark(mockBookmark: bookmark, mockCore: core)

		let rootViewController: MockClientRootViewController = MockClientRootViewController(core: core, query: query, bookmark: bookmark)

		rootViewController.afterCoreStart(nil) {
			let navigationController = UserInterfaceContext.shared.currentWindow?.rootViewController
			let transitionDelegate = PushTransitionDelegate()

			rootViewController.pushTransition = transitionDelegate // Keep a reference, so it's still around on dismissal
			rootViewController.transitioningDelegate = transitionDelegate
			rootViewController.modalPresentationStyle = .custom

			navigationController?.present(rootViewController, animated: true)
		}
	}

	func dismissFileList() {
		UserInterfaceContext.shared.currentWindow?.rootViewController?.dismiss(animated: false, completion: nil)
	}

	// MARK: - Mocks

	func mockOCoreForBookmark(mockBookmark: OCBookmark, mockCore: OCCore? = nil) {
		let requestCoreBlock : OCMRequestCoreForBookmark = { (bookmark, setupHandler, completionHandler) in
			let core = mockCore ?? OCCore(bookmark: mockBookmark)
			setupHandler(core, nil)
			completionHandler(core, nil)
		}

		OCMockManager.shared.addMocking(blocks: [OCMockLocation.ocCoreManagerRequestCoreForBookmark : requestCoreBlock])
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
