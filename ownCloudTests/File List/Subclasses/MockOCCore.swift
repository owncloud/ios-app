//
//  MockOCCore.swift
//  ownCloudTests
//
//  Created by Javier Gonzalez on 10/01/2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2019, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

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
}
