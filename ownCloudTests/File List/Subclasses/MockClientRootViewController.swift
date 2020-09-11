//
//  MockClientRootViewController.swift
//  ownCloudTests
//
//  Created by Javier Gonzalez on 01/02/2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK
import ownCloudAppShared

@testable import ownCloud

class MockClientRootViewController: ClientRootViewController {

	var query:MockOCQuery
	var mockedCore:MockOCCore

	init(core: MockOCCore, query: MockOCQuery, bookmark: OCBookmark) {
		self.query = query
		self.mockedCore = core
		super.init(bookmark: bookmark)
		self.mockedCore.delegate = self
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func coreReady(_ lastVisibleItemId: String?) {
		OnMainThread {
			let queryViewController = ClientQueryViewController(core: self.mockedCore, query: self.query)
			self.filesNavigationController?.setViewControllers([self.emptyViewController, queryViewController], animated: false)
			self.activityViewController?.core = self.core!
		}
	}
}
