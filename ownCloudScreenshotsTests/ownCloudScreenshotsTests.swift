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
import ownCloudSDK

class ScreenshotsTests: XCTestCase {

	let url = ""
	let user = ""
	let password = ""
	let serverDescription = "ownCloud"

    override func setUp() {
		super.setUp()
        continueAfterFailure = false
    }

    override func tearDown() {
		super.tearDown()
    }

	func testScreenshotStep01() {

		let app = XCUIApplication()
		app.launchEnvironment = ["oc:app.show-beta-warning": "false"]
		setupSnapshot(app)
		app.launch()

		snapshot("01_screenshot")

		//Settings
		app.toolbars["Toolbar"]/*@START_MENU_TOKEN@*/.buttons["settingsBarButtonItem"]/*[[".buttons[\"Settings\"]",".buttons[\"settingsBarButtonItem\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
		snapshot("05_screenshot")
		app.navigationBars.element(boundBy: 0).buttons["ownCloud"].tap()

		//Login
		app.navigationBars["ownCloud"].buttons["addAccount"].tap()
		app.textFields["row-url-url"].typeText(url)

		app.navigationBars.element(boundBy: 0).buttons["continue-bar-button"].tap()

		//Expectation add server
		if waitForUserNameTextField(app: app) != .completed {
			XCTFail("Error: Can not check auth method of the server")
		}

		app.textFields["row-credentials-username"].typeText(user)
		app.secureTextFields["row-credentials-password"].tap()
		app.secureTextFields["row-credentials-password"].typeText(password)
		app.textFields["row-name-name"].tap()
		app.textFields["row-name-name"].typeText(serverDescription)

		app.navigationBars.element(boundBy: 0).buttons["continue-bar-button"].tap()

		//Expectation add server
		if waitForServerCell(app: app) != .completed {
			XCTFail("Error: Can not create server connection")
		}
	}

	func testScreenshotStep02() {
		let app = XCUIApplication()
		app.launchEnvironment = ["oc:app.show-beta-warning": "false"]
		setupSnapshot(app)
		app.launch()

		app.tables.cells.staticTexts[serverDescription].tap()

		if waitForDocumentsCell(app: app) != .completed {
			XCTFail("Error: Can not show the root file list")
		}

		snapshot("02_screenshot")

		//Create folder
//		app.tables.buttons["create-folder-button"].tap()
//		app.navigationBars["Create folder"]/*@START_MENU_TOKEN@*/.buttons["cancel-button"]/*[[".buttons[\"Cancel\"]",".buttons[\"cancel-button\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

		app.buttons["create-folder-button"].tap()
		snapshot("03_screenshot")
	}

	func testScreenshotStep03() {

		let app = XCUIApplication()
		app.launchEnvironment = ["oc:app.show-beta-warning": "false"]
		setupSnapshot(app)
		app.launch()

		app.tables.cells.staticTexts[serverDescription].tap()

		if waitForDocumentsCell(app: app) != .completed {
			XCTFail("Error: Can not show the root file list")
		}

		app.windows.element(boundBy: 0).tables.element(boundBy: 0).cells.element(boundBy: 2).tap()

		if waitForSquirrelCell(app: app) != .completed {
			XCTFail("Error: Can not show the cell of Squirrel.jpg")
		}

		app.tables.cells.staticTexts["Squirrel.jpg"].tap()
		snapshot("04_screenshot")

		XCTAssert(true, "Screenshots taken")
	}

	//MARK: Waiters

	func waitForUserNameTextField(app: XCUIApplication) -> XCTWaiter.Result {
		let textField = app.textFields["row-credentials-username"]
		let predicate = NSPredicate(format: "exists == 1")
		let ocExpectation = expectation(for: predicate, evaluatedWith: textField, handler: nil)

		let result = XCTWaiter().wait(for: [ocExpectation], timeout: 15)
		return result
	}

	func waitForServerCell(app: XCUIApplication) -> XCTWaiter.Result {
		let element = app.tables.cells.staticTexts[serverDescription]
		let predicate = NSPredicate(format: "exists == 1")
		let ocExpectation = expectation(for: predicate, evaluatedWith: element, handler: nil)

		let result = XCTWaiter().wait(for: [ocExpectation], timeout: 15)
		return result
	}

	func waitForDocumentsCell(app: XCUIApplication) -> XCTWaiter.Result {
		let element = app.tables.cells.staticTexts["Documents"]
		let predicate = NSPredicate(format: "exists == 1")
		let ocExpectation = expectation(for: predicate, evaluatedWith: element, handler: nil)

		let result = XCTWaiter().wait(for: [ocExpectation], timeout: 15)
		return result
	}

	func waitForSquirrelCell(app: XCUIApplication) -> XCTWaiter.Result {
		let element = app.tables.cells.staticTexts["Squirrel.jpg"]
		let predicate = NSPredicate(format: "exists == 1")
		let ocExpectation = expectation(for: predicate, evaluatedWith: element, handler: nil)

		let result = XCTWaiter().wait(for: [ocExpectation], timeout: 15)
		return result
	}
}
