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

	static func deleteAllBookmarks() {

		if let bookmarks:[OCBookmark] = OCBookmarkManager.shared.bookmarks as? [OCBookmark] {
			for bookmark:OCBookmark in bookmarks {
				OCCoreManager.shared.scheduleOfflineOperation({ (inBookmark, completionHandler) in
					if let bookmark = inBookmark {
						let vault : OCVault = OCVault(bookmark: bookmark)

						vault.erase(completionHandler: { (_, error) in
							DispatchQueue.main.async {
								if error == nil {
									OCBookmarkManager.shared.removeBookmark(bookmark)
								} else {
									print("Error deleting bookmarks")
								}
							}
						})
					}
				}, for: bookmark)
			}
		}

		OCBookmarkManager.shared.bookmarks.removeAllObjects()
	}

	static func removePasscode() {
		AppLockManager.shared.passcode = nil
		AppLockManager.shared.lockEnabled = false
		AppLockManager.shared.biometricalSecurityEnabled = false
		AppLockManager.shared.lockDelay = SecurityAskFrequency.always.rawValue
		AppLockManager.shared.dismissLockscreen(animated: false)
	}

	static func refreshServerList() {
		if let appDelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate {
			appDelegate.serverListTableViewController?.updateNoServerMessageVisibility()
		}
	}

	static func getBookmark(authenticationMethod: OCAuthenticationMethodIdentifier = OCAuthenticationMethodIdentifier.basicAuth) -> OCBookmark? {

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
		bookmark.name = "Server name"
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
