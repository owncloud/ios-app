//
//  MockOCCore.swift
//  ownCloudTests
//
//  Created by Javier Gonzalez on 10/01/2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import ownCloudSDK

class MockOCCore: OCCore {

	var query:MockOCQuery?

	convenience init(query: MockOCQuery!, bookmark: OCBookmark!) {
		self.init(bookmark: bookmark)
		self.query = query
	}

	override func createFolder(_ folderName: String, inside: OCItem, options: [OCCoreOption : Any]? = nil, resultHandler: OCCoreActionResultHandler? = nil) -> Progress? {
		query?.delegate?.queryHasChangesAvailable(query!)
		return nil
	}
}
