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

	public typealias OCMPrepareForSetupCompletionHandler = @convention(block)
		(_ issue: OCConnectionIssue, _ suggestedURL: NSURL, _ supportedMethods: [OCAuthenticationMethodIdentifier], _ preferredAuthenticationMethods: [OCAuthenticationMethodIdentifier]) -> Void

	public typealias OCMPrepareForSetup = @convention(block)
		(_ options: NSDictionary, _ completionHandler: OCMPrepareForSetupCompletionHandler) -> Void

	public typealias OCMGenerateAuthenticationDataWithMethodCompletionHandler = @convention(block)
		(_ error: NSError?, _ authenticationMethodIdentifier: OCAuthenticationMethodIdentifier, _ authenticationData: NSData?) -> Void

	public typealias OCMGenerateAuthenticationDataWithMethod = @convention(block)
		(_ methodIdentifier: OCAuthenticationMethodIdentifier, _ options: OCAuthenticationMethodBookmarkAuthenticationDataGenerationOptions, _ completionHandler: OCMGenerateAuthenticationDataWithMethodCompletionHandler) -> Void

	override func setUp() {
		super.setUp()
		OCMockManager.shared.removeAllMockingBlocks()
		UtilsTests.deleteAllBookmarks()
		UtilsTests.showNoServerMessageServerList()
	}

	override func tearDown() {
		super.tearDown()
	}

    func testCheckInitialViewAuth () {

        //Actions
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())

        //Assert
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).assert(grey_sufficientlyVisible())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-continue-continue")).assert(grey_sufficientlyVisible())

        //Reset status
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
    }

    func testCheckURLEmptyBasicAuth () {

        //Actions
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-continue-continue")).perform(grey_tap())

        //Assert
        EarlGrey.select(elementWithMatcher: grey_text("Missing hostname".localized)).assert(grey_sufficientlyVisible())

        //Reset status
        EarlGrey.select(elementWithMatcher: grey_text("OK")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
    }

    
    func testCheckURLBasicAuthInformalIssue () {

        let mockUrlServer = "http://mocked.owncloud.server.com"
        let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodBasicAuthIdentifier as NSString,
                                                               OCAuthenticationMethodOAuth2Identifier as NSString]
        let issue: OCConnectionIssue = OCConnectionIssue(forError: NSError(domain: "mocked.owncloud.server.com", code: 1033, userInfo: [NSLocalizedDescriptionKey: "Informal issue description"]), level: .informal, issueHandler: nil)

        //Mock
        mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)

        //Actions
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-continue-continue")).perform(grey_tap())

        //Assert
        let isServerChecked = GREYCondition(name: "Wait for server is checked", block: {
            var error: NSError?

            EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).assert(grey_sufficientlyVisible(), error: &error)
            EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).assert(grey_sufficientlyVisible(), error: &error)
            EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).assert(grey_sufficientlyVisible(), error: &error)
            EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-name-name")).assert(grey_sufficientlyVisible(), error: &error)

            return error == nil
        }).wait(withTimeout: 5.0, pollInterval: 0.5)

        GREYAssertTrue(isServerChecked, reason: "Failed check the server")

        //Reset status
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
    }

    
    func testCheckURLBasicAuthWarningIssueView () {

        let mockUrlServer = "http://mocked.owncloud.server.com"
        let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodBasicAuthIdentifier as NSString,
                                                               OCAuthenticationMethodOAuth2Identifier as NSString]
        let issue: OCConnectionIssue = OCConnectionIssue(forError: NSError(domain: "mocked.owncloud.server.com", code: 1033, userInfo: [NSLocalizedDescriptionKey: "Warning issue description"]), level: .warning, issueHandler: nil)

        //Mock
        mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)

        //Actions
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-continue-continue")).perform(grey_tap())

        //Assert
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("approve-button")).assert(grey_sufficientlyVisible())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel-button")).assert(grey_sufficientlyVisible())

        //Reset status
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel-button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
    }
    
    func testCheckURLBasicAuthWarningIssueApproval () {

        let mockUrlServer = "http://mocked.owncloud.server.com"
        let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodBasicAuthIdentifier as NSString,
                                                               OCAuthenticationMethodOAuth2Identifier as NSString]
        let issue: OCConnectionIssue = OCConnectionIssue(forError: NSError(domain: "mocked.owncloud.server.com", code: 1033, userInfo: [NSLocalizedDescriptionKey: "Warning issue description"]), level: .warning, issueHandler: nil)

        //Mock
        mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)

        //Actions
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-continue-continue")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("approve-button")).perform(grey_tap())

        //Assert
        let isServerChecked = GREYCondition(name: "Wait for server is checked", block: {
            var error: NSError?

            EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).assert(grey_sufficientlyVisible(), error: &error)
            EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).assert(grey_sufficientlyVisible(), error: &error)
            EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).assert(grey_sufficientlyVisible(), error: &error)
            EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-name-name")).assert(grey_sufficientlyVisible(), error: &error)

            return error == nil
        }).wait(withTimeout: 5.0, pollInterval: 0.5)

        GREYAssertTrue(isServerChecked, reason: "Failed check the server")

        //Reset status
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
    }

    func testCheckURLBasicAuthWarningIssueCancel () {

        let mockUrlServer = "http://mocked.owncloud.server.com"
        let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodBasicAuthIdentifier as NSString,
                                                               OCAuthenticationMethodOAuth2Identifier as NSString]
        let issue: OCConnectionIssue = OCConnectionIssue(forError: NSError(domain: "mocked.owncloud.server.com", code: 1033, userInfo: [NSLocalizedDescriptionKey: "Warning issue description"]), level: .warning, issueHandler: nil)

        //Mock
        mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)

        //Actions
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-continue-continue")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel-button")).perform(grey_tap())

        //Assert
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).assert(grey_sufficientlyVisible())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).assert(grey_notVisible())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).assert(grey_notVisible())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-name-name")).assert(grey_notVisible())

        //Reset status
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
    }

    func testCheckURLBasicAuthWarningIssueCertificate () {

    }

    func testCheckURLBasicAuthErrorIssue () {

        let mockUrlServer = "http://mocked.owncloud.server.com"
        let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodBasicAuthIdentifier as NSString,
                                                               OCAuthenticationMethodOAuth2Identifier as NSString]
        let issue: OCConnectionIssue = OCConnectionIssue(forError: NSError(domain: "mocked.owncloud.server.com", code: 1033, userInfo: [NSLocalizedDescriptionKey: "Error issue description"]), level: .error, issueHandler: nil)

        //Mock
        mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)

        //Actions
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-continue-continue")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("ok-button")).perform(grey_tap())

        //Assert
        let isServerChecked = GREYCondition(name: "Wait for server is checked", block: {
            var error: NSError?

            EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).assert(grey_sufficientlyVisible(), error: &error)
            EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).assert(grey_sufficientlyVisible(), error: &error)
            EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).assert(grey_sufficientlyVisible(), error: &error)
            EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-name-name")).assert(grey_sufficientlyVisible(), error: &error)

            return error == nil
        }).wait(withTimeout: 5.0, pollInterval: 0.5)

        GREYAssertTrue(!isServerChecked, reason: "Failed check the server")
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).assert(grey_notVisible())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).assert(grey_notVisible())

        //Reset status
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
    }

    func testCheckURLServerOAuth2 () {

        let mockUrlServer = "http://mocked.owncloud.server.com"
        let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodOAuth2Identifier as NSString,
                                                               OCAuthenticationMethodBasicAuthIdentifier as NSString]
        let issue: OCConnectionIssue = OCConnectionIssue(forError: NSError(domain: "mocked.owncloud.server.com", code: 1033, userInfo: [NSLocalizedDescriptionKey: "Error description"]), level: .warning, issueHandler: nil)

		let authenticationMethodIdentifier = OCAuthenticationMethodOAuth2Identifier as NSString
		let tokenResponse:[String : String] = ["access_token" : "RyFyDu1wH0Wvd8KlCP0Qeo9dlTqWajgvWHNqSdfl9bVD6Wp72CGikmgSkvUaAMML",
										"expires_in" : "3600",
										"message_url" : "https://localhost/apps/oauth2/authorization-successful",
										"refresh_token" : "khA8H18TWC84g1DmB0fzqgDOWvNRNPGJkkzQ1E6AZjq8UrqZ79QTK8UgSsJB6MrW",
										"token_type" : "Bearer",
										"user_id" : "admin"]
		let dictionary:[String : Any] = ["bearerString" : "Bearer RyFyDu1wH0Wvd8KlCP0Qeo9dlTqWajgvWHNqSdfl9bVD6Wp72CGikmgSkvUaAMML",
									 "expirationDate" : "2018-11-15 14:34:39 +0000",
									 "tokenResponse" : tokenResponse]
		let error: NSError?  = nil

        //Mock
        mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)
		mockOCConnectionGenerateAuthenticationData(authenticationMethodIdentifier: authenticationMethodIdentifier, dictionary: dictionary, error: error)

        //Actions
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-continue-continue")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("approve-button")).perform(grey_tap())

        //Assert
        let isServerChecked = GREYCondition(name: "Wait for server is checked", block: {
            var error: NSError?

            EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).assert(grey_sufficientlyVisible(), error: &error)
            EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).assert(grey_notVisible(), error: &error)
            EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).assert(grey_notVisible(), error: &error)

            return error == nil
        }).wait(withTimeout: 5.0, pollInterval: 0.5)

        GREYAssertTrue(isServerChecked, reason: "Failed check the server")

        //Reset status
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
    }

	func testCheckUrlWithErrorCertificate() {

		let mockUrlServer = "http://mocked.owncloud.server.com"
		let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodBasicAuthIdentifier as NSString,
															   OCAuthenticationMethodOAuth2Identifier as NSString]
		if let certificate: OCCertificate = UtilsTests.getCertificate(mockUrlServer: mockUrlServer) {

				let issue: OCConnectionIssue = OCConnectionIssue.init(for: certificate, validationResult: OCCertificateValidationResult.userAccepted, url: URL(string: mockUrlServer), level: .warning, issueHandler: nil)

				//Mock
				mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)

				//Actions
				EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
				EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
				EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-continue-continue")).perform(grey_tap())

				//Assert
				EarlGrey.select(elementWithMatcher: grey_text("Approve".localized)).assert(grey_sufficientlyVisible())
		} else {
			assertionFailure("Not possible to read the test_certificate.cer")
		}
	}

	func testLoginOauth2RightCredentials () {

		let mockUrlServer = "http://mocked.owncloud.server.com"
		let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodOAuth2Identifier as NSString,
															   OCAuthenticationMethodBasicAuthIdentifier as NSString]
		let issue: OCConnectionIssue = OCConnectionIssue(forError: NSError(domain: "mocked.owncloud.server.com", code: 1033, userInfo: [NSLocalizedDescriptionKey: "Error description"]), level: .informal, issueHandler: nil)

		let authenticationMethodIdentifier = OCAuthenticationMethodOAuth2Identifier as NSString
		let tokenResponse:[String : String] = ["access_token" : "RyFyDu1wH0Wvd8KlCP0Qeo9dlTqWajgvWHNqSdfl9bVD6Wp72CGikmgSkvUaAMML",
											   "expires_in" : "3600",
											   "message_url" : "https://localhost/apps/oauth2/authorization-successful",
											   "refresh_token" : "khA8H18TWC84g1DmB0fzqgDOWvNRNPGJkkzQ1E6AZjq8UrqZ79QTK8UgSsJB6MrW",
											   "token_type" : "Bearer",
											   "user_id" : "admin"]
		let dictionary:[String : Any] = ["bearerString" : "Bearer RyFyDu1wH0Wvd8KlCP0Qeo9dlTqWajgvWHNqSdfl9bVD6Wp72CGikmgSkvUaAMML",
										 "expirationDate" : "2018-11-15 14:34:39 +0000",
										 "tokenResponse" : tokenResponse]
		let error: NSError?  = nil

		//Mock
		mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)
		mockOCConnectionGenerateAuthenticationData(authenticationMethodIdentifier: authenticationMethodIdentifier, dictionary: dictionary, error: error)

		//Actions
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-continue-continue")).perform(grey_tap())
		//EarlGrey.select(elementWithMatcher: grey_accessibilityID("approve-button")).perform(grey_tap())

		//Assert
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("server-bookmark-cell")).assert(grey_sufficientlyVisible())
	}

    func testLoginBasicAuthRightCredentials () {

        let mockUrlServer = "http://mocked.owncloud.server.com"
        let userName = "test"
        let password = "test"
        let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodBasicAuthIdentifier as NSString,
                                                               OCAuthenticationMethodOAuth2Identifier as NSString]
        let issue: OCConnectionIssue = OCConnectionIssue(forError: NSError(domain: "mocked.owncloud.server.com", code: 1033, userInfo: [NSLocalizedDescriptionKey: "Error description"]), level: .warning, issueHandler: nil)

		let error: NSError?  = nil
		let authenticationMethodIdentifier = OCAuthenticationMethodBasicAuthIdentifier as NSString
		let dictionary:Dictionary = ["BasicAuthString" : "Basic YWRtaW46YWRtaW4=",
									 "passphrase" : "admin",
									 "username" : "admin"]

        //Mock
        mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)
		mockOCConnectionGenerateAuthenticationData(authenticationMethodIdentifier: authenticationMethodIdentifier, dictionary: dictionary, error: error)

        //Actions
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-continue-continue")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("approve-button")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).perform(grey_replaceText(userName))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).perform(grey_replaceText(password))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-continue-continue")).perform(grey_tap())

        //Assert
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("server-bookmark-cell")).assert(grey_sufficientlyVisible())
    }

    func testLoginBasicAuthWarningIssue () {

        let mockUrlServer = "http://mocked.owncloud.server.com"
        let userName = "test"
        let password = "test"
        let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodBasicAuthIdentifier as NSString,
                                                               OCAuthenticationMethodOAuth2Identifier as NSString]

        let errorURL: NSError = NSError(domain: "mocked.owncloud.server.com", code: 1000, userInfo: [NSLocalizedDescriptionKey: "Error URL"])
        let issue: OCConnectionIssue = OCConnectionIssue(forError: errorURL, level: .informal, issueHandler: nil)

		let authenticationMethodIdentifier = OCAuthenticationMethodBasicAuthIdentifier as NSString
		let dictionary:Dictionary = ["BasicAuthString" : "Basic YWRtaW46YWRtaW4=",
									 "passphrase" : "admin",
									 "username" : "admin"]
		let errorCredentials: NSError = NSError(domain: "OCError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Error Credentials"])

        //Mock
        mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)
		mockOCConnectionGenerateAuthenticationData(authenticationMethodIdentifier: authenticationMethodIdentifier, dictionary: dictionary, error: errorCredentials)

        //Actions
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-continue-continue")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).perform(grey_replaceText(userName))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).perform(grey_replaceText(password))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-continue-continue")).perform(grey_tap())

        //Assert
        //TO-DO: catch shake
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("server-bookmark-cell")).assert(grey_notVisible())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).assert(grey_sufficientlyVisible())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-continue-continue")).assert(grey_sufficientlyVisible())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).assert(grey_sufficientlyVisible())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).assert(grey_sufficientlyVisible())

        //Reset status
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
    }

    func testLoginBasicAuthErrorIssue () {

        let mockUrlServer = "http://mocked.owncloud.server.com"
        let userName = "test"
        let password = "test"
        let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodBasicAuthIdentifier as NSString,
                                                               OCAuthenticationMethodOAuth2Identifier as NSString]

        let errorURL: NSError = NSError(domain: "mocked.owncloud.server.com", code: 1000, userInfo: [NSLocalizedDescriptionKey: "Error URL"])
        let issue: OCConnectionIssue = OCConnectionIssue(forError: errorURL, level: .informal, issueHandler: nil)

		let authenticationMethodIdentifier = OCAuthenticationMethodBasicAuthIdentifier as NSString
		let dictionary:Dictionary = ["BasicAuthString" : "Basic YWRtaW46YWRtaW4=",
									 "passphrase" : "admin",
									 "username" : "admin"]
        let errorCredentials: NSError = NSError(domain: "OCError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error Credentials"])

        //Mock
        mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)
		mockOCConnectionGenerateAuthenticationData(authenticationMethodIdentifier: authenticationMethodIdentifier, dictionary: dictionary, error: errorCredentials)

        //Actions
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-continue-continue")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).perform(grey_replaceText(userName))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).perform(grey_replaceText(password))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-continue-continue")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("ok-button")).perform(grey_tap())

        //Assert
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("server-bookmark-cell")).assert(grey_notVisible())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).assert(grey_sufficientlyVisible())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-continue-continue")).assert(grey_sufficientlyVisible())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).assert(grey_sufficientlyVisible())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).assert(grey_sufficientlyVisible())

        //Reset status
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
    }

    // MARK: - Mocks
    func mockOCConnectionPrepareForSetup(mockUrlServer: String, authMethods: [OCAuthenticationMethodIdentifier], issue: OCConnectionIssue) {
        let completionHandlerBlock : OCMPrepareForSetup = {
            (dict, mockedBlock) in
            let url: NSURL = NSURL(fileURLWithPath: mockUrlServer)
            mockedBlock(issue, url, authMethods, authMethods)
        }

        OCMockManager.shared.addMocking(blocks:
            [OCMockLocation.ocConnectionPrepareForSetupWithOptions: completionHandlerBlock])
    }

	func mockOCConnectionGenerateAuthenticationData(authenticationMethodIdentifier: OCAuthenticationMethodIdentifier, dictionary: [String: Any], error: NSError?) {
        let completionHandlerBlock : OCMGenerateAuthenticationDataWithMethod = {
            (methodIdentifier, options, mockedBlock) in

            var data: Data? = nil
            do {
                data = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .binary, options: 0)
            } catch {
                return
            }

            mockedBlock(error, authenticationMethodIdentifier, data! as NSData)
        }

        OCMockManager.shared.addMocking(blocks:
            [OCMockLocation.ocConnectionGenerateAuthenticationDataWithMethod: completionHandlerBlock])
    }
}
