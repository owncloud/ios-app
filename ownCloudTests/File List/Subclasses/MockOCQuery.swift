//
//  MockOCQuery.swift
//  ownCloudTests
//
//  Created by Javier Gonzalez on 08/01/2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

class MockOCQuery: OCQuery {

	convenience init(path: String!) {
		self.init(forPath: path)
		self.rootItem = OCItem()
	}
}
