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
import LocalAuthentication

class ScreenshotsTests: XCTestCase {

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

		let url = ""
		let user = ""
		let password = ""
		let description = "ownCloud"

		//Login
		app.navigationBars["ownCloud"].buttons["addAccount"].tap()
		app.textFields["row-url-url"].typeText(url)

		app.navigationBars.element(boundBy: 0)/*@START_MENU_TOKEN@*/.buttons["continue-bar-button"]/*[[".buttons[\"Continuar\"]",".buttons[\"continue-bar-button\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

		app.textFields["row-credentials-username"].typeText(user)
		app.secureTextFields["row-credentials-password"].tap()
		app.secureTextFields["row-credentials-password"].typeText(password)
		app.textFields["row-name-name"].tap()
		app.textFields["row-name-name"].typeText(description)


		XCUIApplication().navigationBars.element(boundBy: 0)/*@START_MENU_TOKEN@*/.buttons["continue-bar-button"]/*[[".buttons[\"Continuar\"]",".buttons[\"continue-bar-button\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

		let label = app.tables.cells.staticTexts[description]
		let exists = NSPredicate(format: "exists == 1")

		expectation(for: exists, evaluatedWith: label, handler: nil)
		waitForExpectations(timeout: 15, handler: nil)

		app.tables.cells.staticTexts["demo@demo.owncloud.com"].tap()


		//TODO:

		//Create folder
		//app.buttons.element(boundBy: 5).label

		//Setting button
		//XCUIApplication().toolbars["Toolbar"].buttons["settingsBarButtonItem"].tap()
		//snapshot("01_screenshot")
	}
}
