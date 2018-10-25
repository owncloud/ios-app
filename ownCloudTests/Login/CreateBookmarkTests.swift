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

	public typealias OCMPrepareForSetupCompletionHandler = @convention(block)
		(_ issue: OCConnectionIssue, _ suggestedURL: NSURL, _ supportedMethods: [OCAuthenticationMethodIdentifier], _ preferredAuthenticationMethods: [OCAuthenticationMethodIdentifier]) -> Void

	public typealias OCMPrepareForSetup = @convention(block)
		(_ options: NSDictionary, _ completionHandler: OCMPrepareForSetupCompletionHandler) -> Void

	func testCheckURLServer () {

		let mockUrlServer = "http://mocked.owncloud.server.com"

		let completionHandlerBlock : OCMPrepareForSetup = {
			(dict, mockedBlock) in
			let issue: OCConnectionIssue = OCConnectionIssue(forError: nil, level: .informal, issueHandler: nil)
			let url: NSURL = NSURL(fileURLWithPath: mockUrlServer)
			let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodBasicAuthIdentifier as NSString,
															 OCAuthenticationMethodOAuth2Identifier as NSString]
			mockedBlock(issue, url, authMethods, authMethods)
		}

		OCMockManager.shared.addMocking(blocks:
			[OCMockLocation.ocConnectionPrepareForSetupWithOptions: completionHandlerBlock])

		EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-continue-continue")).perform(grey_tap())

		let isPasscodeUnlocked = GREYCondition(name: "Wait for server is checked", block: {
			var error: NSError?

			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-name-name")).assert(grey_sufficientlyVisible(), error: &error)

			return error == nil
		}).wait(withTimeout: 5.0, pollInterval: 0.5)

		//Assert
		GREYAssertTrue(isPasscodeUnlocked, reason: "Failed check the server")

	}
}
