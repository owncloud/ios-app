//
//  UtilsTesting.swift
//  ownCloud
//
//  Created by Javier Gonzalez on 06/11/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import Foundation
import ownCloudSDK
import ownCloudMocking

@testable import ownCloud

class UtilsTests {
	
	public typealias OCMPrepareForSetupCompletionHandler = @convention(block)
		(_ issue: OCIssue, _ suggestedURL: NSURL, _ supportedMethods: [OCAuthenticationMethodIdentifier], _ preferredAuthenticationMethods: [OCAuthenticationMethodIdentifier]) -> Void
	
	public typealias OCMPrepareForSetup = @convention(block)
		(_ connection: OCConnection, _ options: NSDictionary, _ completionHandler: OCMPrepareForSetupCompletionHandler) -> Void
	
	public typealias OCMGenerateAuthenticationDataWithMethodCompletionHandler = @convention(block)
		(_ error: NSError?, _ authenticationMethodIdentifier: OCAuthenticationMethodIdentifier, _ authenticationData: NSData?) -> Void
	
	public typealias OCMGenerateAuthenticationDataWithMethod = @convention(block)
		(_ connection: OCConnection, _ methodIdentifier: OCAuthenticationMethodIdentifier, _ options: OCAuthenticationMethodBookmarkAuthenticationDataGenerationOptions, _ completionHandler: OCMGenerateAuthenticationDataWithMethodCompletionHandler) -> Void
	
	public typealias OCMConnectCompletionHandler = @convention(block)
		(_ error: NSError?, _ issue: OCIssue?) -> Void
	
	public typealias OCMDisconnectCompletionHandler = @convention(block)
		() -> Void
	
	public typealias OCMConnect = @convention(block)
		(_ connection: OCConnection, _ completionHandler: OCMConnectCompletionHandler) -> Progress
	
	public typealias OCMDisconnect = @convention(block)
		(_ connection: OCConnection, _ completionHandler: OCMDisconnectCompletionHandler, _ invalidate: Bool) -> Void
	
	static func removePasscode() {
		AppLockManager.shared.passcode = nil
		AppLockManager.shared.lockEnabled = false
		AppLockManager.shared.biometricalSecurityEnabled = false
		AppLockManager.shared.lockDelay = SecurityAskFrequency.always.rawValue
		AppLockManager.shared.dismissLockscreen(animated: false)
	}

	// MARK: - Helper
	static func getBookmark(authenticationMethod: OCAuthenticationMethodIdentifier = OCAuthenticationMethodIdentifier.basicAuth, bookmarkName: String = "Server name", certifUserApproved: Bool = true) -> OCBookmark? {

		let mockUrlServer: String = "https://mock.owncloud.com/"

		let dictionary: Dictionary = ["BasicAuthString" : "Basic YWRtaW46YWRtaW4=",
		"passphrase" : "admin",
		"username" : "admin"]

		var data: Data?
		do {
			data = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .binary, options: 0)
		} catch {
			return nil
		}

		let bookmark: OCBookmark = OCBookmark()
		bookmark.name = bookmarkName
		bookmark.url = URL(string: mockUrlServer)
		bookmark.authenticationMethodIdentifier = authenticationMethod
		bookmark.authenticationData = data
		bookmark.certificate = self.getCertificate(mockUrlServer: mockUrlServer)
		bookmark.certificate?.userAccepted = certifUserApproved

		return bookmark
	}

	static func getCertificate(mockUrlServer: String) -> OCCertificate? {
		let bundle = Bundle.main
		if let url: URL = bundle.url(forResource: "test_certificate", withExtension: "cer") {
			do {
				let certificateData = try Data(contentsOf: url as URL)
				let certificate: OCCertificate = OCCertificate(certificateData: certificateData, hostName: mockUrlServer)

				return certificate
			} catch {
				print("Failing reading data of test_certificate.cer")
			}
		} else {
			print("Not possible to read the test_certificate.cer")
		}
		return nil
	}
	
	// MARK: - Mocks
	static func mockOCConnectionPrepareForSetup(mockUrlServer: String, authMethods: [OCAuthenticationMethodIdentifier], issue: OCIssue) {
		let completionHandlerBlock : OCMPrepareForSetup = {
			(connection, dict, mockedBlock) in
			let url: NSURL = NSURL(fileURLWithPath: mockUrlServer)
			mockedBlock(issue, url, authMethods, authMethods)
		}
		
		OCMockManager.shared.addMocking(blocks:
			[OCMockLocation.ocConnectionPrepareForSetupWithOptions : completionHandlerBlock])
	}
	
	static func mockOCConnectionGenerateAuthenticationData(authenticationMethodIdentifier: OCAuthenticationMethodIdentifier, dictionary: [String: Any], error: NSError?) {
		let completionHandlerBlock : OCMGenerateAuthenticationDataWithMethod = {
			(connection, methodIdentifier, options, mockedBlock) in
			
			var data: Data?
			
			do {
				data = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .binary, options: 0)
			} catch {
				return
			}
			
			mockedBlock(error, authenticationMethodIdentifier, data! as NSData)
		}
		
		OCMockManager.shared.addMocking(blocks:
			[OCMockLocation.ocConnectionGenerateAuthenticationDataWithMethod : completionHandlerBlock])
	}
	
	static func mockOCConnectionConnectWithCompletionHandler(issue: OCIssue, user: OCUser?, error: NSError?) {
		
		let completionHandlerBlock : OCMConnect = {
			(connection, mockedBlock) in
			
			if user != nil {
				connection.loggedInUser = user
			}
			
			mockedBlock(error, nil)
			
			return Progress()
		}
		
		OCMockManager.shared.addMocking(blocks:
			[OCMockLocation.ocConnectionConnectWithCompletionHandler : completionHandlerBlock])
	}
	
	static func mockOCConnectionDisconnectWithCompletionHandler() {
		
		let completionHandlerBlock : OCMDisconnect = {
			(connection, mockedBlock, invalidate) in
			
			mockedBlock()
		}
		
		OCMockManager.shared.addMocking(blocks:
			[OCMockLocation.ocConnectionDisconnectWithCompletionHandlerInvalidate : completionHandlerBlock])
	}
}
