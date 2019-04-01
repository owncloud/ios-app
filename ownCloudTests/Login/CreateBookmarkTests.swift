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
		OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
	}
	
	override func tearDown() {
		super.tearDown()
		OCMockManager.shared.removeAllMockingBlocks()
		OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
	}
	
	/*
	* PASSED if: Initial view correct: URL field and continue button are displayed
	*/
	func testCheckInitialViewAuth () {
		
		//Actions
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
		
		//Assert
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).assert(grey_sufficientlyVisible())
		EarlGrey.select(elementWithMatcher: grey_text("Continue".localized)).assert(grey_sufficientlyVisible())
		
		//Reset status
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
	}
	
	/*
	* PASSED if: Alert view with missing URL displayed if Continue is clicked with empty URL
	*/
	func testCheckURLEmptyBasicAuth () {
		
		//Actions
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
		
		//Assert
		EarlGrey.select(elementWithMatcher: grey_text("Continue".localized)).assert(grey_not(grey_enabled()))
		
		//Reset status
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
	}
	
	/*
	* PASSED if: URL leads to informal issue. Credentials fields, name and Continue are displayed
	*/
	func testCheckURLBasicAuthInformalIssue () {
		
		let mockUrlServer = "http://mocked.owncloud.server.com"
		let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodIdentifier.basicAuth,
															   OCAuthenticationMethodIdentifier.oAuth2]
		let issue: OCIssue = OCIssue(forError: NSError(domain: "mocked.owncloud.server.com", code: 1033, userInfo: [NSLocalizedDescriptionKey: "Informal issue description"]), level: .informal, issueHandler: nil)
		
		//Mock
		UtilsTests.mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)
		
		//Actions
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
		EarlGrey.select(elementWithMatcher: grey_text("Continue".localized)).perform(grey_tap())
		
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
	
	/*
	* PASSED if: URL leads to warning issue. Issue with Approve and Cancel buttons are displayed
	*/
	func testCheckURLBasicAuthWarningIssueView () {
		
		let mockUrlServer = "http://mocked.owncloud.server.com"
		let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodIdentifier.basicAuth,
															   OCAuthenticationMethodIdentifier.oAuth2]
		let issue: OCIssue = OCIssue(forError: NSError(domain: "mocked.owncloud.server.com", code: 1033, userInfo: [NSLocalizedDescriptionKey: "Warning issue description"]), level: .warning, issueHandler: nil)
		
		//Mock
		UtilsTests.mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)
		
		//Actions
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
		EarlGrey.select(elementWithMatcher: grey_text("Continue".localized)).perform(grey_tap())
		
		//Assert
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("approve-button")).assert(grey_sufficientlyVisible())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel-button")).assert(grey_sufficientlyVisible())
		
		//Reset status
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel-button")).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
	}
	
	/*
	* PASSED if: URL leads to warning issue. Issue approved: URL, Credentials fields, Name and Continue are displayed
	*/
	func testCheckURLBasicAuthWarningIssueApproval () {
		
		let mockUrlServer = "http://mocked.owncloud.server.com"
		let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodIdentifier.basicAuth,
															   OCAuthenticationMethodIdentifier.oAuth2]
		let issue: OCIssue = OCIssue(forError: NSError(domain: "mocked.owncloud.server.com", code: 1033, userInfo: [NSLocalizedDescriptionKey: "Warning issue description"]), level: .warning, issueHandler: nil)
		
		//Mock
		UtilsTests.mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)
		
		//Actions
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
		EarlGrey.select(elementWithMatcher: grey_text("Continue".localized)).perform(grey_tap())
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
	
	/*
	* PASSED if: URL leads to warning issue. Issue cancelled: URL displayed. Credentials and name not displayed
	*/
	func testCheckURLBasicAuthWarningIssueCancel () {
		
		let mockUrlServer = "http://mocked.owncloud.server.com"
		let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodIdentifier.basicAuth,
															   OCAuthenticationMethodIdentifier.oAuth2]
		let issue: OCIssue = OCIssue(forError: NSError(domain: "mocked.owncloud.server.com", code: 1033, userInfo: [NSLocalizedDescriptionKey: "Warning issue description"]), level: .warning, issueHandler: nil)
		
		//Mock
		UtilsTests.mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)
		
		//Actions
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
		EarlGrey.select(elementWithMatcher: grey_text("Continue".localized)).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel-button")).perform(grey_tap())
		
		//Assert
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).assert(grey_sufficientlyVisible())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).assert(grey_notVisible())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).assert(grey_notVisible())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-name-name")).assert(grey_notVisible())
		
		//Reset status
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
	}
	
	/*
	* PASSED if: URL leads to error issue. Error displayed. URL displayed. Credentials and name not displayed
	*/
	func testCheckURLBasicAuthErrorIssue () {
		
		let mockUrlServer = "http://mocked.owncloud.server.com"
		let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodIdentifier.basicAuth,
															   OCAuthenticationMethodIdentifier.oAuth2]
		let issue: OCIssue = OCIssue(forError: NSError(domain: "mocked.owncloud.server.com", code: 1033, userInfo: [NSLocalizedDescriptionKey: "Error issue description"]), level: .error, issueHandler: nil)
		
		//Mock
		UtilsTests.mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)
		
		//Actions
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
		EarlGrey.select(elementWithMatcher: grey_text("Continue".localized)).perform(grey_tap())
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
	
	/*
	* PASSED if: URL leads to warning issue type Certificate. Certificate issue displayed with Approve displayed
	*/
	func testCheckURLBasicAuthWarningIssueCertificate() {
		
		let mockUrlServer = "http://mocked.owncloud.server.com"
		let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodIdentifier.basicAuth,
															   OCAuthenticationMethodIdentifier.oAuth2]
		if let certificate: OCCertificate = UtilsTests.getCertificate(mockUrlServer: mockUrlServer) {
			guard let url = URL(string: mockUrlServer) else {
				assertionFailure("Creation of URL object for \(mockUrlServer) failed")
				return
			}
			let issue: OCIssue = OCIssue.init(for: certificate, validationResult: OCCertificateValidationResult.userAccepted, url: url, level: .warning, issueHandler: nil)
			
			//Mock
			UtilsTests.mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)
			
			//Actions
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
			EarlGrey.select(elementWithMatcher: grey_text("Continue".localized)).perform(grey_tap())
			
			//Assert
			EarlGrey.select(elementWithMatcher: grey_text("Certificate".localized)).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_text("Approve".localized)).assert(grey_sufficientlyVisible())
			
			//Reset status
			EarlGrey.select(elementWithMatcher: grey_text("Approve".localized)).perform(grey_tap())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
		} else {
			assertionFailure("Not possible to read the test_certificate.cer")
		}
	}
	
	/*
	* PASSED if: URL leads to warning issue type Certificate. Click on certificate displays the certificate info
	*/
	func testCheckURLBasicAuthWarningIssueCertificateDisplayInfo() {
		
		let mockUrlServer = "http://mocked.owncloud.server.com"
		let authMethods: [OCAuthenticationMethodIdentifier] = [.basicAuth, .oAuth2]
		if let certificate: OCCertificate = UtilsTests.getCertificate(mockUrlServer: mockUrlServer) {
			guard let url = URL(string: mockUrlServer) else {
				assertionFailure("Creation of URL object for \(mockUrlServer) failed")
				return
			}
			let issue: OCIssue = OCIssue(for: certificate, validationResult: .userAccepted, url: url, level: .warning, issueHandler: nil)
			
			//Mock
			UtilsTests.mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)
			
			//Actions
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
			EarlGrey.select(elementWithMatcher: grey_text("Continue".localized)).perform(grey_tap())
			EarlGrey.select(elementWithMatcher: grey_text("Certificate".localized)).perform(grey_tap())
			
			//Assert
			EarlGrey.waitForElement(withMatcher: grey_text("Certificate Details".localized), label: "Certificate Details")
			EarlGrey.select(elementWithMatcher: grey_text("Certificate Details".localized)).assert(grey_sufficientlyVisible())
			
			//Reset status
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("ok-button-certificate-details")).perform(grey_tap())
			
			EarlGrey.select(elementWithMatcher: grey_text("Approve".localized)).perform(grey_tap())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
		} else {
			assertionFailure("Not possible to read the test_certificate.cer")
		}
	}
	
	/*
	* PASSED if: URL leads to warning issue type Certificate. Approve certificate leads to credentials
	*/
	func testCheckURLBasicAuthWarningIssueCertificateApproval() {
		
		let mockUrlServer = "http://mocked.owncloud.server.com"
		let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodIdentifier.basicAuth,
															   OCAuthenticationMethodIdentifier.oAuth2]
		if let certificate: OCCertificate = UtilsTests.getCertificate(mockUrlServer: mockUrlServer) {
			guard let url = URL(string: mockUrlServer) else {
				assertionFailure("Creation of URL object for \(mockUrlServer) failed")
				return
			}
			let issue: OCIssue = OCIssue.init(for: certificate, validationResult: OCCertificateValidationResult.userAccepted, url:url, level: .warning, issueHandler: nil)
			
			//Mock
			UtilsTests.mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)
			
			//Actions
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
			EarlGrey.select(elementWithMatcher: grey_text("Continue".localized)).perform(grey_tap())
			EarlGrey.select(elementWithMatcher: grey_text("Approve".localized)).perform(grey_tap())
			
			//Assert
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).assert(grey_sufficientlyVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).assert(grey_sufficientlyVisible())
			
			//Reset status
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
			
		} else {
			assertionFailure("Not possible to read the test_certificate.cer")
		}
	}
	
	/*
	* PASSED if: URL leads to warning issue type Certificate. Cancel certificate does not display credentials
	*/
	func testCheckURLBasicAuthWarningIssueCertificateCancel() {
		
		let mockUrlServer = "http://mocked.owncloud.server.com"
		let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodIdentifier.basicAuth,
															   OCAuthenticationMethodIdentifier.oAuth2]
		if let certificate: OCCertificate = UtilsTests.getCertificate(mockUrlServer: mockUrlServer) {
			guard let url = URL(string: mockUrlServer) else {
				assertionFailure("Creation of URL object for \(mockUrlServer) failed")
				return
			}
			let issue: OCIssue = OCIssue.init(for: certificate, validationResult: OCCertificateValidationResult.userAccepted, url: url, level: .warning, issueHandler: nil)
			
			//Mock
			UtilsTests.mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)
			
			//Actions
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
			EarlGrey.select(elementWithMatcher: grey_text("Continue".localized)).perform(grey_tap())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel-button")).perform(grey_tap())
			
			//Assert
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).assert(grey_notVisible())
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).assert(grey_notVisible())
			
			//Reset status
			EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
			
		} else {
			assertionFailure("Not possible to read the test_certificate.cer")
		}
	}
	
	/*
	* PASSED if: URL leads to OAuth2 authentication. Credentials fields not displayed.
	*/
	func testCheckURLOAuth2 () {
		
		let mockUrlServer = "http://mocked.owncloud.server.com"
		let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodIdentifier.oAuth2,
															   OCAuthenticationMethodIdentifier.basicAuth]
		let issue: OCIssue = OCIssue(forError: NSError(domain: "mocked.owncloud.server.com", code: 1033, userInfo: [NSLocalizedDescriptionKey: "Error description"]), level: .warning, issueHandler: nil)
		
		let authenticationMethodIdentifier = OCAuthenticationMethodIdentifier.oAuth2 as NSString
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
		UtilsTests.mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)
		UtilsTests.mockOCConnectionGenerateAuthenticationData(authenticationMethodIdentifier: authenticationMethodIdentifier as OCAuthenticationMethodIdentifier, dictionary: dictionary, error: error)
		
		//Actions
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
		EarlGrey.select(elementWithMatcher: grey_text("Continue".localized)).perform(grey_tap())
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
	
	/*
	* PASSED if: URL leads to correct OAuth2 authentication. Warning is displayed
	*/
	func testLoginOAuth2Warning () {

		let mockUrlServer = "http://mocked.owncloud.server.com"
		let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodIdentifier.oAuth2,
															   OCAuthenticationMethodIdentifier.basicAuth]
		let issue: OCIssue = OCIssue(forError: NSError(domain: "mocked.owncloud.server.com", code: 1033, userInfo: [NSLocalizedDescriptionKey: "Error description"]), level: .informal, issueHandler: nil)

		//Mock
		UtilsTests.mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)

		//Actions
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
		EarlGrey.select(elementWithMatcher: grey_text("Continue".localized)).perform(grey_tap())

		let isServerChecked = GREYCondition(name: "Wait for server is checked", block: {
			var error: NSError?

			//Assert
			EarlGrey.select(elementWithMatcher: grey_text("If you 'Continue', you will be prompted to allow the ownCloud App to open OAuth2 login where you can enter your credentials.".localized)).assert(grey_sufficientlyVisible(), error: &error)

			return error == nil
		}).wait(withTimeout: 5.0, pollInterval: 0.5)

		GREYAssertTrue(!isServerChecked, reason: "Failed check the server")

		//Reset
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
		OCMockManager.shared.removeAllMockingBlocks()
		OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
	}

	/*
	* PASSED if: URL leads to correct OAuth2 authentication. Bookmark cell created and displayed
	*/
	func testLoginOAuth2RightCredentials () {
		
		let mockUrlServer = "http://mocked.owncloud.server.com"
		let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodIdentifier.oAuth2,
															   OCAuthenticationMethodIdentifier.basicAuth]
		let issue: OCIssue = OCIssue(forError: NSError(domain: "mocked.owncloud.server.com", code: 1033, userInfo: [NSLocalizedDescriptionKey: "Error description"]), level: .informal, issueHandler: nil)
		
		let authenticationMethodIdentifier = OCAuthenticationMethodIdentifier.oAuth2
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
		let user: OCUser = OCUser.init()
		user.displayName = "Admin"
		
		//Mock
		UtilsTests.mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)
		UtilsTests.mockOCConnectionGenerateAuthenticationData(authenticationMethodIdentifier: authenticationMethodIdentifier, dictionary: dictionary, error: error)
		UtilsTests.mockOCConnectionConnectWithCompletionHandler(issue: issue, user: user, error: error)
		UtilsTests.mockOCConnectionDisconnectWithCompletionHandler()
		
		//Actions
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
		EarlGrey.select(elementWithMatcher: grey_text("Continue".localized)).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_text("Continue".localized)).perform(grey_tap())
		
		//Assert
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("server-bookmark-cell")).assert(grey_sufficientlyVisible())
		
		//Reset
		OCMockManager.shared.removeAllMockingBlocks()
		OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
	}
	
	/*
	* PASSED if: URL leads to correct Basic authentication. Bookmark cell created and displayed
	*/
	func testLoginBasicAuthRightCredentials () {
		
		let mockUrlServer = "http://mocked.owncloud.server.com"
		let userName = "test"
		let password = "test"
		let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodIdentifier.basicAuth,
															   OCAuthenticationMethodIdentifier.oAuth2]
		let issue: OCIssue = OCIssue(forError: NSError(domain: "mocked.owncloud.server.com", code: 1033, userInfo: [NSLocalizedDescriptionKey: "Error description"]), level: .warning, issueHandler: nil)
		
		let error: NSError?  = nil
		let authenticationMethodIdentifier = OCAuthenticationMethodIdentifier.basicAuth
		let dictionary:Dictionary = ["BasicAuthString" : "Basic YWRtaW46YWRtaW4=",
									 "passphrase" : "admin",
									 "username" : "admin"]
		let user: OCUser = OCUser.init()
		user.displayName = "Admin"
		
		//Mock
		UtilsTests.mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)
		UtilsTests.mockOCConnectionGenerateAuthenticationData(authenticationMethodIdentifier: authenticationMethodIdentifier, dictionary: dictionary, error: error)
		UtilsTests.mockOCConnectionConnectWithCompletionHandler(issue: issue, user: user, error: error)
		UtilsTests.mockOCConnectionDisconnectWithCompletionHandler()
		
		//Actions
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
		EarlGrey.select(elementWithMatcher: grey_text("Continue".localized)).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("approve-button")).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).perform(grey_replaceText(userName))
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).perform(grey_replaceText(password))
		EarlGrey.select(elementWithMatcher: grey_text("Continue".localized)).perform(grey_tap())
		
		//Assert
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("server-bookmark-cell")).assert(grey_sufficientlyVisible())
		
		//Reset
		OCMockManager.shared.removeAllMockingBlocks()
		OCBookmarkManager.deleteAllBookmarks(waitForServerlistRefresh: true)
	}
	
	/*
	* PASSED if: URL leads to Basic authentication with warning issue. Bookmark cell is not displayed. Credentials, Name and Continue displayed.
	*/
	func testLoginBasicAuthWarningIssue () {
		
		let mockUrlServer = "http://mocked.owncloud.server.com"
		let userName = "test"
		let password = "test"
		let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodIdentifier.basicAuth,
															   OCAuthenticationMethodIdentifier.oAuth2]
		
		let errorURL: NSError = NSError(domain: "mocked.owncloud.server.com", code: 1000, userInfo: [NSLocalizedDescriptionKey: "Error URL"])
		let issue: OCIssue = OCIssue(forError: errorURL, level: .informal, issueHandler: nil)
		
		let authenticationMethodIdentifier = OCAuthenticationMethodIdentifier.basicAuth
		let dictionary:Dictionary = ["BasicAuthString" : "Basic YWRtaW46YWRtaW4=",
									 "passphrase" : "admin",
									 "username" : "admin"]
		let errorCredentials: NSError = NSError(domain: "OCError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Error Credentials"])
		
		//Mock
		UtilsTests.mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)
		UtilsTests.mockOCConnectionGenerateAuthenticationData(authenticationMethodIdentifier: authenticationMethodIdentifier, dictionary: dictionary, error: errorCredentials)
		
		//Actions
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
		EarlGrey.select(elementWithMatcher: grey_text("Continue".localized)).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).perform(grey_replaceText(userName))
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).perform(grey_replaceText(password))
		EarlGrey.select(elementWithMatcher: grey_text("Continue".localized)).perform(grey_tap())
		
		//Assert
		//TO-DO: catch shake
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("server-bookmark-cell")).assert(grey_notVisible())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).assert(grey_sufficientlyVisible())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).assert(grey_sufficientlyVisible())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).assert(grey_sufficientlyVisible())
		
		//Reset status
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("ok-button")).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).assert(grey_sufficientlyVisible())
	}
	
	/*
	* PASSED if: URL leads to Basic authentication with error. Bookmark cell is not displayed. Credentials, Name and Continue displayed.
	*/
	func testLoginBasicAuthErrorIssue () {
		
		let mockUrlServer = "http://mocked.owncloud.server.com"
		let userName = "test"
		let password = "test"
		let authMethods: [OCAuthenticationMethodIdentifier] = [OCAuthenticationMethodIdentifier.basicAuth,
															   OCAuthenticationMethodIdentifier.oAuth2]
		
		let errorURL: NSError = NSError(domain: "mocked.owncloud.server.com", code: 1000, userInfo: [NSLocalizedDescriptionKey: "Error URL"])
		let issue: OCIssue = OCIssue(forError: errorURL, level: .informal, issueHandler: nil)
		
		let authenticationMethodIdentifier = OCAuthenticationMethodIdentifier.basicAuth
		let dictionary:Dictionary = ["BasicAuthString" : "Basic YWRtaW46YWRtaW4=",
									 "passphrase" : "admin",
									 "username" : "admin"]
		let errorCredentials: NSError = NSError(domain: "OCError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error Credentials"])
		
		//Mock
		UtilsTests.mockOCConnectionPrepareForSetup(mockUrlServer: mockUrlServer, authMethods: authMethods, issue: issue)
		UtilsTests.mockOCConnectionGenerateAuthenticationData(authenticationMethodIdentifier: authenticationMethodIdentifier, dictionary: dictionary, error: errorCredentials)
		
		//Actions
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).perform(grey_replaceText(mockUrlServer))
		EarlGrey.select(elementWithMatcher: grey_text("Continue".localized)).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).perform(grey_replaceText(userName))
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-password")).perform(grey_replaceText(password))
		EarlGrey.select(elementWithMatcher: grey_text("Continue".localized)).perform(grey_tap())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("ok-button")).perform(grey_tap())
		
		//Assert
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("server-bookmark-cell")).assert(grey_notVisible())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-url-url")).assert(grey_sufficientlyVisible())
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("row-credentials-username")).assert(grey_sufficientlyVisible())
		
		//Reset status
		EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
	}
}
