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
		if let appDelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate {

			let query = MockOCQuery(path: "/")
			let core = MockOCCore(query: query, bookmark: bookmark, issue: issue)

			let rootViewController: MockClientRootViewController = MockClientRootViewController(core: core, query: query, bookmark: bookmark)

			rootViewController.afterCoreStart {
				let navigationController = (appDelegate.serverListTableViewController?.navigationController)!
				let transitionDelegate = PushTransitionDelegate()

				rootViewController.pushTransition = transitionDelegate // Keep a reference, so it's still around on dismissal
				rootViewController.transitioningDelegate = transitionDelegate
				rootViewController.modalPresentationStyle = .custom

				navigationController.present(rootViewController, animated: true)
			}
		}
	}

	func dismissFileList() {
		if let appDelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate {
			appDelegate.serverListTableViewController?.navigationController?.popViewController(animated: false)
		}
	}

	// MARK: - Mocks

	func mockOCoreForBookmark(mockBookmark: OCBookmark) {
		let completionHandlerBlock : OCMRequestCoreForBookmark = { (bookmark, setupHandler, mockedBlock) in
			let core = OCCore(bookmark: mockBookmark)
			setupHandler(core, nil)
			mockedBlock(core, nil)
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
