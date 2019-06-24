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

	let serverDescription = "ownCloud"

	override func setUp() {
		super.setUp()
		continueAfterFailure = false
	}

	override func tearDown() {
		super.tearDown()
	}

	func testTakeScreenshotStep() {
		let app = XCUIApplication()
		app.launchEnvironment = ["oc:app.show-beta-warning": "false", "oc:app.enable-ui-animations": "false"]
		app.launchArguments.append(contentsOf: ["-preferred-theme-style", "com.owncloud.classic"])
		app.launchArguments += ["UI-Testing"]
		setupSnapshot(app)
		app.launch()

		snapshot("10_ios_accounts_welcome_demo")

		//Settings
		app.toolbars["Toolbar"].buttons["settingsBarButtonItem"].tap()
		snapshot("60_ios_settings_demo")
		app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()

		//Add account
		let credentials : [String : String] = ["url" : url, "user" : user, "password" : password, "serverDescription" : serverDescription]
		addAccount(app: app, credentials: credentials)
		//Add account
		let credentialsDemo : [String : String] = ["url" : "demo.owncloud.com", "user" : "demo", "password" : "demo", "serverDescription" : "demo@demo.owncloud.com"]
		addAccount(app: app, credentials: credentialsDemo)
		//Add account
		let credentialsDemo2 : [String : String] = ["url" : "demo.owncloud.com", "user" : "admin", "password" : "admin", "serverDescription" : "admin@demo.owncloud.com"]
		addAccount(app: app, credentials: credentialsDemo2)

		snapshot("11_ios_accounts_list_demo")

		prepareFileList(app: app)
		if waitForDocumentsCell(app: app) != .completed {
			XCTFail("Error: File list not loaded")
		}
		preparePDFFile(app: app)
		preparePhotos(app: app)
		prepareQuickAccess(app: app)

		XCTAssert(true, "Screenshots taken")
	}

	func addAccount(app: XCUIApplication, credentials: [String : String]) {
		if let url = credentials["url"], let user = credentials["user"], let password = credentials["password"], let serverDescription = credentials["serverDescription"] {

			app.navigationBars.element(boundBy: 0).buttons[localizedString(key: "Add account")].tap()
			app.textFields["row-url-url"].typeText(url)

			app.navigationBars.element(boundBy: 0).buttons["continue-bar-button"].doubleTap()

			if waitForUserNameTextField(app: app) != .completed {
				XCTFail("Error: Can not check auth method of the server")
			}

			app.textFields["row-credentials-username"].typeText(user)
			app.secureTextFields["row-credentials-password"].tap()
			app.secureTextFields["row-credentials-password"].typeText(password)
			app.textFields["row-name-name"].tap()
			app.textFields["row-name-name"].typeText(serverDescription)

			app.navigationBars.element(boundBy: 0).buttons["continue-bar-button"].tap()
		} else {
			XCTFail("Error: Adding Login failed")
		}
	}

	func prepareFileList(app: XCUIApplication) {
		if waitForAccountList(app: app) != .completed {
			XCTFail("Error: Account list not loaded")
		}
		let tablesQuery = app.tables
		tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["ownCloud"]/*[[".cells[\"server-bookmark-cell\"].staticTexts[\"ownCloud\"]",".staticTexts[\"ownCloud\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
	}

	func preparePDFFile(app: XCUIApplication) {
		let tablesQuery = app.tables
		tablesQuery.staticTexts["ownCloud Manual.pdf"].tap()

		if waitForPDFViewer(app: app) != .completed {
			XCTFail("Error: Loading PDF failed")
		}

		sleep(5)

		let scrollViewsQuery = app.scrollViews
		scrollViewsQuery.children(matching: .other).element.children(matching: .other).element.swipeLeft()
		scrollViewsQuery.children(matching: .other).element.children(matching: .other).element.swipeLeft()
		scrollViewsQuery.children(matching: .other).element.children(matching: .other).element.swipeLeft()
		scrollViewsQuery.children(matching: .other).element.children(matching: .other).element.swipeLeft()
		scrollViewsQuery.children(matching: .other).element.children(matching: .other).element.swipeLeft()
		scrollViewsQuery.children(matching: .other).element.children(matching: .other).element.swipeLeft()
		scrollViewsQuery.children(matching: .other).element.children(matching: .other).element.swipeLeft()
		scrollViewsQuery.children(matching: .other).element.children(matching: .other).element.swipeLeft()
		scrollViewsQuery.children(matching: .other).element.children(matching: .other).element.swipeLeft()
		scrollViewsQuery.children(matching: .other).element.children(matching: .other).element.swipeLeft()
		scrollViewsQuery.children(matching: .other).element.children(matching: .other).element.swipeLeft()
		scrollViewsQuery.children(matching: .other).element.children(matching: .other).element.swipeLeft()
		snapshot("22_ios_files_preview_pdf_demo")
		app.navigationBars["ownCloud Manual.pdf"].buttons["ownCloud"].tap()
	}

	func preparePhotos(app: XCUIApplication) {
		let tablesQuery = XCUIApplication().tables

		tablesQuery.buttons[String(format: "Photos %@", localizedString(key: "Actions"))].tap()
		snapshot("21_ios_files_actions_demo")
		app.children(matching: .window).element(boundBy: 0).children(matching: .other).element(boundBy: 2).children(matching: .other).element(boundBy: 0).tap()

		tablesQuery.staticTexts["Photos"].tap()

		sleep(5)

		snapshot("20_ios_files_list_demo")
		app.navigationBars[localizedString(key: "Show parent paths")].buttons["ownCloud"].tap()
	}

	func prepareQuickAccess(app: XCUIApplication) {
		app.tabBars.buttons[localizedString(key: "Quick Access")].tap()
		snapshot("40_ios_quick_access_demo")
	}

	// MARK: - Waiters

	func waitForAccountList(app: XCUIApplication) -> XCTWaiter.Result {
		let tablesQuery = app.tables
		let tableCell = tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["ownCloud"]/*[[".cells[\"server-bookmark-cell\"].staticTexts[\"ownCloud\"]",".staticTexts[\"ownCloud\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch
		let predicate = NSPredicate(format: "exists == 1")
		let ocExpectation = expectation(for: predicate, evaluatedWith: tableCell, handler: nil)

		let result = XCTWaiter().wait(for: [ocExpectation], timeout: 15)
		return result
	}

	func waitForUserNameTextField(app: XCUIApplication) -> XCTWaiter.Result {
		let textField = app.textFields["row-credentials-username"]
		let predicate = NSPredicate(format: "exists == 1")
		let ocExpectation = expectation(for: predicate, evaluatedWith: textField, handler: nil)

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

	func waitForPDFViewer(app: XCUIApplication) -> XCTWaiter.Result {
		let element = app.navigationBars["ownCloud Manual.pdf"].buttons["ownCloud"]
		let predicate = NSPredicate(format: "exists == 1")
		let ocExpectation = expectation(for: predicate, evaluatedWith: element, handler: nil)

		let result = XCTWaiter().wait(for: [ocExpectation], timeout: 15)
		return result
	}

	func localizedString(key:String) -> String {
		if deviceLanguage == "en-US" {
			deviceLanguage = "en"
		}

		let localizationBundle = Bundle(path: Bundle(for: type(of: self)).path(forResource: deviceLanguage, ofType: "lproj")!)
		let result = NSLocalizedString(key, bundle:localizationBundle!, comment: "")

		return result
	}
}

extension XCUIElement {
	// The following is a workaround for inputting text in the simulator and prevent errors
	func setText(text: String, application: XCUIApplication) {
		UIPasteboard.general.string = text
		doubleTap()
		application.menuItems.element(boundBy: 0).tap()
	}
}
