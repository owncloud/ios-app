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

	var accountName = "ownCloud"
	let takeBrandedScreenshots = true

	let url = "demo.owncloud.com"
	let user = "admin"
	let password = "admin"

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

		if !takeBrandedScreenshots {
			regularAppSetup(app: app)

			// Workaround: Open the File List to dismiss keyboard
			prepareFileList(app: app)
			app.navigationBars[accountName].buttons["Accounts"].tap()

			snapshot("11_ios_accounts_list_demo")
			prepareFileList(app: app)

			if waitForDocumentsCell(app: app) != .completed {
				XCTFail("Error: File list not loaded")
			}
		} else {
			accountName = "ownCloud.online"
			brandedAppSetup(app: app)

			let tablesQuery = app.tables
			app.navigationBars[accountName].buttons["Manage"].tap()

			snapshot("11_ios_accounts_list_demo")

			tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Access Files"]/*[[".cells.staticTexts[\"Access Files\"]",".staticTexts[\"Access Files\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
		}

		preparePDFFile(app: app)
		preparePhotos(app: app)
		prepareQuickAccess(app: app)

		if UIDevice.current.userInterfaceIdiom == .pad {
			prepareMultipleWindows(app: app)
		}

		XCTAssert(true, "Screenshots taken")
	}

	func regularAppSetup(app: XCUIApplication) {
		addUIInterruptionMonitor(withDescription: "System Dialog") {
			(alert) -> Bool in
			alert.buttons["Allow"].tap()
			return true
		}
		app.tap()

		snapshot("10_ios_accounts_welcome_demo")

		//Settings
		app.toolbars["Toolbar"].buttons["settingsBarButtonItem"].tap()
		snapshot("60_ios_settings_demo")
		app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()

		if waitForAddAccountButton(app: app) != .completed {
			XCTFail("Error: Account Button not available")
		}
		//Add account
		let credentials : [String : String] = ["url" : url, "user" : user, "password" : password, "serverDescription" : accountName]
		addAccount(app: app, credentials: credentials)

		if waitForAddAccountButton(app: app) != .completed {
			XCTFail("Error: Account Button not available")
		}

		//Add account
		let credentialsDemo : [String : String] = ["url" : url, "user" : user, "password" : password, "serverDescription" : "demo@demo.owncloud.com"]
		addAccount(app: app, credentials: credentialsDemo)

		if waitForAddAccountButton(app: app) != .completed {
			XCTFail("Error: Account Button not available")
		}

		//Add account
		let credentialsDemo2 : [String : String] = ["url" : url, "user" : user, "password" : password, "serverDescription" : "admin@demo.owncloud.com"]
		addAccount(app: app, credentials: credentialsDemo2)
	}

	func brandedAppSetup(app: XCUIApplication) {
		snapshot("10_ios_accounts_welcome_demo")

		//Settings
		app.toolbars["Toolbar"].buttons["settingsBarButtonItem"].tap()
		snapshot("60_ios_settings_demo")
		app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()

		let tablesQuery = app.tables
		tablesQuery/*@START_MENU_TOKEN@*/.textFields["url"]/*[[".cells",".textFields[\"https:\/\/\"]",".textFields[\"url\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
		tablesQuery/*@START_MENU_TOKEN@*/.textFields["url"]/*[[".cells",".textFields[\"https:\/\/\"]",".textFields[\"url\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.typeText(url)
		tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Continue"]/*[[".buttons[\"Continue\"].staticTexts[\"Continue\"]",".staticTexts[\"Continue\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
		tablesQuery/*@START_MENU_TOKEN@*/.textFields["username"]/*[[".cells",".textFields[\"Username\"]",".textFields[\"username\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
		tablesQuery/*@START_MENU_TOKEN@*/.textFields["username"]/*[[".cells",".textFields[\"Username\"]",".textFields[\"username\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.typeText(user)

		let passwordSecureTextField = tablesQuery/*@START_MENU_TOKEN@*/.secureTextFields["password"]/*[[".cells",".secureTextFields[\"Password\"]",".secureTextFields[\"password\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
		passwordSecureTextField.tap()
		passwordSecureTextField.typeText(password)
		tablesQuery.buttons["Login"].tap()

		addUIInterruptionMonitor(withDescription: "System Dialog") {
			(alert) -> Bool in
			alert.buttons["Allow"].tap()
			return true
		}
		app.tap()

		tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Access Files"]/*[[".cells.staticTexts[\"Access Files\"]",".staticTexts[\"Access Files\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
	}

	func addAccount(app: XCUIApplication, credentials: [String : String]) {
		if let url = credentials["url"], let user = credentials["user"], let password = credentials["password"], let serverDescription = credentials["serverDescription"] {

			app.navigationBars.element(boundBy: 0).buttons[localizedString(key: "Add account")].tap()
			app.textFields["row-url-url"].typeText(url)

			app.navigationBars[localizedString(key: "Add account")]/*@START_MENU_TOKEN@*/.buttons["continue-bar-button"]/*[[".buttons[\"Continue\"]",".buttons[\"continue-bar-button\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

			if waitForUserNameTextField(app: app) != .completed {
				XCTFail("Error: Can not check auth method of the server")
			}

			app.textFields["row-credentials-username"].typeText(user)
			app.secureTextFields["row-credentials-password"].tap()
			app.secureTextFields["row-credentials-password"].typeText(password)
			app.textFields["row-name-name"].tap()
			app.textFields["row-name-name"].typeText(serverDescription)

			app.navigationBars[localizedString(key: "Add account")]/*@START_MENU_TOKEN@*/.buttons["continue-bar-button"]/*[[".buttons[\"Continue\"]",".buttons[\"continue-bar-button\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
		} else {
			XCTFail("Error: Adding Login failed")
		}
	}

	func prepareFileList(app: XCUIApplication) {
		if waitForAccountList(app: app) != .completed {
			XCTFail("Error: Account list not loaded")
		}
		let tablesQuery = app.tables
		tablesQuery.staticTexts[accountName].firstMatch.tap()
	}

	func preparePDFFile(app: XCUIApplication) {
		let tablesQuery = app.tables
		tablesQuery.staticTexts["ownCloud Manual.pdf"].tap()

		if waitForPDFViewer(app: app) != .completed {
			XCTFail("Error: Loading PDF failed")
		}

		sleep(5)

		let scrollViewsQuery = app.scrollViews.firstMatch
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
		app.navigationBars["ownCloud Manual.pdf"].buttons[accountName].tap()
	}

	func preparePhotos(app: XCUIApplication) {
		let tablesQuery = XCUIApplication().tables

		tablesQuery.buttons[String(format: "ownCloud Manual.pdf %@", localizedString(key: "Actions"))].tap()
		snapshot("21_ios_files_actions_demo")

		let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
		let coordinate = normalized.withOffset(CGVector(dx: 44, dy: 44))
		coordinate.tap()

		tablesQuery.staticTexts["Photos"].tap()

		sleep(5)

		snapshot("20_ios_files_list_demo")
		app.navigationBars["Photos"].buttons[accountName].tap()
	}

	func prepareQuickAccess(app: XCUIApplication) {
		app.tabBars.buttons[localizedString(key: "Quick Access")].tap()
		snapshot("40_ios_quick_access_demo")
	}

	func prepareMultipleWindows(app: XCUIApplication) {
		XCUIDevice.shared.orientation = .landscapeLeft
		sleep(2)
		app.tabBars.buttons[localizedString(key: "Browse")].tap()

		let tablesQuery = XCUIApplication().tables
		tablesQuery/*@START_MENU_TOKEN@*/.buttons["Photos Actions"]/*[[".cells[\"Photos\"].buttons[\"Photos Actions\"]",".buttons[\"Photos Actions\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
		sleep(2)
		tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Open in a new Window"]/*[[".cells[\"com.owncloud.action.openscene\"].staticTexts[\"Open in a new Window\"]",".staticTexts[\"Open in a new Window\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

		sleep(2)

		let tablesQuery2 = XCUIApplication().tables
		tablesQuery2/*@START_MENU_TOKEN@*/.buttons["Photos Actions"]/*[[".cells[\"Photos\"].buttons[\"Photos Actions\"]",".buttons[\"Photos Actions\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()


		snapshot("23_ios_files_list_multiple_window_landscape")
	}

	// MARK: - Waiters

	func waitForAddAccountButton(app: XCUIApplication) -> XCTWaiter.Result {
		let element = app.navigationBars.element(boundBy: 0).buttons[localizedString(key: "Add account")]
		let predicate = NSPredicate(format: "exists == 1")
		let ocExpectation = expectation(for: predicate, evaluatedWith: element, handler: nil)

		let result = XCTWaiter().wait(for: [ocExpectation], timeout: 15)
		return result
	}

	func waitForAccountList(app: XCUIApplication) -> XCTWaiter.Result {
		let tablesQuery = app.tables
		let tableCell = tablesQuery.staticTexts[accountName].firstMatch
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
		let element = app.navigationBars["ownCloud Manual.pdf"].buttons[accountName]
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
