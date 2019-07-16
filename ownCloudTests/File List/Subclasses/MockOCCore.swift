//
//  MockOCCore.swift
//  ownCloudTests
//
//  Created by Javier Gonzalez on 10/01/2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import ownCloudSDK

class MockOCCore: OCCore {

	var query:MockOCQuery
	var issue: OCIssue?

	init(query: MockOCQuery, bookmark: OCBookmark, issue: OCIssue? = nil) {
		self.query = query
		self.issue = issue
		super.init(bookmark: bookmark)
	}

	override func createFolder(_ folderName: String, inside: OCItem, options: [OCCoreOption : Any]? = nil, resultHandler: OCCoreActionResultHandler? = nil) -> Progress? {

		if self.issue != nil {
			self.delegate?.core(self, handleError: nil, issue: issue)
		} else {
			query.delegate?.queryHasChangesAvailable(query)
		}

		return nil
	}

	override func suggestUnusedNameBased(on name: String, atPath path: String, isDirectory: Bool, using nameStyle: OCCoreDuplicateNameStyle, filteredBy filter: OCCoreUnusedNameSuggestionFilter?, resultHandler: @escaping OCCoreUnusedNameSuggestionResultHandler) {
		resultHandler(name, nil)
	}
}
