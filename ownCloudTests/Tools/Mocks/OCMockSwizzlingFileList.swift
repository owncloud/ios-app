//
//  OCMockSwizzlingFileList.swift
//  ownCloudTests
//
//  Created by Javier Gonzalez on 26/02/2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import ownCloudSDK
import ownCloudMocking

class OCMockSwizzlingFileList {

	public typealias OCMRequestCoreForBookmarkCompletionHandler = @convention(block)
		(_ core: OCCore, _ error: NSError?) -> Void

	public typealias OCMRequestCoreForBookmarkSetupHandler = @convention(block)
		(_ core: OCCore, _ error: NSError?) -> Void

	public typealias OCMRequestCoreForBookmark = @convention(block)
		(_ bookmark: OCBookmark, _ setup: OCMRequestCoreForBookmarkSetupHandler, _ completionHandler: OCMRequestCoreForBookmarkCompletionHandler) -> Void

	public typealias OCMRequestChangeSetWithFlags = @convention(block)
		(_ flags: OCQueryChangeSetRequestFlag, _ completionHandler: OCQueryChangeSetRequestCompletionHandler) -> Void

	// MARK: - Mocks
	static func mockOCoreForBookmark(mockBookmark: OCBookmark) {
		let completionHandlerBlock : OCMRequestCoreForBookmark = { (bookmark, setupHandler, mockedBlock) in
			let core = OCCore(bookmark: mockBookmark)
			setupHandler(core, nil)
			mockedBlock(core, nil)
		}

		OCMockManager.shared.addMocking(blocks: [OCMockLocation.ocCoreManagerRequestCoreForBookmark: completionHandlerBlock])
	}

	static func mockQueryPropfindResults(resourceName: String, basePath: String, state: OCQueryState) {
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
