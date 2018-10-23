//
//  CreateBookmarkTests.swift
//  ownCloudTests
//
//  Created by Javier Gonzalez on 23/10/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import XCTest
import EarlGrey
import ownCloudSDK
import ownCloudMocking

@testable import ownCloud

class CreateBookmarkTests: XCTestCase {

	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDown() {
		AppLockManager.shared.passcode = nil
		AppLockManager.shared.lockEnabled = false
		super.tearDown()
	}

	public typealias OCMPrepareForSetupCompletionHandler = @convention(block) () ->
		(_ issue: OCConnectionIssue?, _ suggestedURL: NSURL?, _ supportedMethods: [OCAuthenticationMethodIdentifier]?, _ preferredAuthenticationMethods: [OCAuthenticationMethodIdentifier]?) -> Void

	public typealias OCMPrepareForSetup = @convention(block) () ->
		(_ options: NSDictionary, _ completionHandler: OCMPrepareForSetupCompletionHandler) -> Void

	func testCheckURLServer () {

		let mockUrlServer = "http://mocked.owncloud.server.com"

		EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))

		let mockedBlock: OCMPrepareForSetupCompletionHandler = { return { (nil, _, _, _) in } }
		let completionHandlerBlock : OCMPrepareForSetup = { return {(dict, mockedBlock) in }  }

		OCMockManager.shared.addMocking(blocks:
			[OCMockLocation.ocConnectionPrepareForSetupWithOptions: completionHandlerBlock])

		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-continue-continue")).perform(grey_tap())




		/*let mockTest = OCMockTestClass()

		XCTAssert(OCMockTestClass.returnsTrue()==true)
		XCTAssert(mockTest.returnsFalse()==false)

		let returnTrueBlock : OCMockMockTestClassReturnsBool = {return false}
		let returnFalseBlock : OCMockMockTestClassReturnsBool = {return true}

		OCMockManager.shared.addMocking(blocks:
			[OCMockLocation.mockTestClassReturnsTrue: returnTrueBlock,
			 OCMockLocation.mockTestClassReturnsFalse: returnFalseBlock])

		XCTAssert(OCMockTestClass.returnsTrue()==false)
		XCTAssert(mockTest.returnsFalse()==true)*/
	}
}
