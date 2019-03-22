//
//  ownCloudScreenshotsTests.swift
//  ownCloudScreenshotsTests
//
//  Created by Javier Gonzalez on 19/03/2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2018, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import XCTest
import EarlGrey
import ownCloudSDK
import LocalAuthentication

@testable import ownCloud

class ownCloudScreenshotsTests: XCTestCase {

    override func setUp() {
		super.setUp()
        continueAfterFailure = false
    }

    override func tearDown() {
		super.tearDown()
    }

	func testScreenshot01Login() {

		let app = XCUIApplication()
		app.launchEnvironment = ["oc:app.show-beta-warning": "false"]
		setupSnapshot(app)
		app.launch()

		//snapshot("01_connect_with_owncloud")

		//Actions
		//EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
	}
}
