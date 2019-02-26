//
//  OCMockSwizzlingBookmark.swift
//  ownCloudTests
//
//  Created by Javier Gonzalez on 26/02/2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import ownCloudSDK
import ownCloudMocking

class OCMockSwizzlingBookmark {

	public typealias OCMPrepareForSetupCompletionHandler = @convention(block)
		(_ issue: OCIssue, _ suggestedURL: NSURL, _ supportedMethods: [OCAuthenticationMethodIdentifier], _ preferredAuthenticationMethods: [OCAuthenticationMethodIdentifier]) -> Void

	public typealias OCMPrepareForSetup = @convention(block)
		(_ options: NSDictionary, _ completionHandler: OCMPrepareForSetupCompletionHandler) -> Void

	public typealias OCMGenerateAuthenticationDataWithMethodCompletionHandler = @convention(block)
		(_ error: NSError?, _ authenticationMethodIdentifier: OCAuthenticationMethodIdentifier, _ authenticationData: NSData?) -> Void

	public typealias OCMGenerateAuthenticationDataWithMethod = @convention(block)
		(_ methodIdentifier: OCAuthenticationMethodIdentifier, _ options: OCAuthenticationMethodBookmarkAuthenticationDataGenerationOptions, _ completionHandler: OCMGenerateAuthenticationDataWithMethodCompletionHandler) -> Void

	// MARK: - Mocks
	static func mockOCConnectionPrepareForSetup(mockUrlServer: String, authMethods: [OCAuthenticationMethodIdentifier], issue: OCIssue) {
		let completionHandlerBlock : OCMPrepareForSetup = {
			(dict, mockedBlock) in
			let url: NSURL = NSURL(fileURLWithPath: mockUrlServer)
			mockedBlock(issue, url, authMethods, authMethods)
		}

		OCMockManager.shared.addMocking(blocks:
			[OCMockLocation.ocConnectionPrepareForSetupWithOptions: completionHandlerBlock])
	}

	static func mockOCConnectionGenerateAuthenticationData(authenticationMethodIdentifier: OCAuthenticationMethodIdentifier, dictionary: [String: Any], error: NSError?) {
		let completionHandlerBlock : OCMGenerateAuthenticationDataWithMethod = {
			(methodIdentifier, options, mockedBlock) in

			var data: Data?

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
