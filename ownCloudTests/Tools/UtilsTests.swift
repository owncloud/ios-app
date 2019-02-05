//
//  UtilsTesting.swift
//  ownCloud
//
//  Created by Javier Gonzalez on 06/11/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import Foundation
import ownCloudSDK

@testable import ownCloud

class UtilsTests {
	static func removePasscode() {
		AppLockManager.shared.passcode = nil
		AppLockManager.shared.lockEnabled = false
		AppLockManager.shared.biometricalSecurityEnabled = false
		AppLockManager.shared.lockDelay = SecurityAskFrequency.always.rawValue
		AppLockManager.shared.dismissLockscreen(animated: false)
	}

	static func getBookmark(authenticationMethod: OCAuthenticationMethodIdentifier = OCAuthenticationMethodIdentifier.basicAuth, bookmarkName: String = "Server name") -> OCBookmark? {

		let mockUrlServer: String = "https://demo.owncloud.com/"

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
}
