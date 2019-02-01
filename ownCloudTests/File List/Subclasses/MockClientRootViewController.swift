//
//  MockClientRootViewController.swift
//  ownCloudTests
//
//  Created by Javier Gonzalez on 01/02/2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK
@testable import ownCloud

class MockClientRootViewController: ClientRootViewController {

	var query:MockOCQuery!
	var mockedCore:MockOCCore!

	convenience init(core: MockOCCore!, query: MockOCQuery!, bookmark: OCBookmark!) {
		self.init(bookmark: bookmark)
		self.query = query
		self.mockedCore = core
		self.mockedCore.delegate = self
	}

	override func coreReady() {
		OnMainThread {
			let queryViewController = ClientQueryViewController(core: self.mockedCore!, query: self.query)
			queryViewController.navigationItem.leftBarButtonItem = self.logoutBarButtonItem()

			self.filesNavigationController?.pushViewController(queryViewController, animated: false)
		}
	}
}
