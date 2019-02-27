//
//  MockClientRootViewController.swift
//  ownCloudTests
//
//  Created by Javier Gonzalez on 01/02/2019.
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

import UIKit
import ownCloudSDK
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

	override func coreReady() {
		OnMainThread {
			let queryViewController = ClientQueryViewController(core: self.mockedCore, query: self.query)
			self.filesNavigationController?.setViewControllers([self.emptyViewController, queryViewController], animated: false)
			self.activityViewController?.core = self.core!
		}
	}
}
