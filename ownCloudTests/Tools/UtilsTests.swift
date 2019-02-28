//
//  UtilsTesting.swift
//  ownCloud
//
//  Created by Javier Gonzalez on 06/11/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2019, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

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

	static func showFileList(bookmark: OCBookmark, issue: OCIssue? = nil) {
		if let appDelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate {

			let query = MockOCQuery(path: "/")
			let core = MockOCCore(query: query, bookmark: bookmark, issue: issue)

			let rootViewController: MockClientRootViewController = MockClientRootViewController(core: core, query: query, bookmark: bookmark)

			appDelegate.serverListTableViewController?.navigationController?.navigationBar.prefersLargeTitles = false
			appDelegate.serverListTableViewController?.navigationController?.navigationItem.largeTitleDisplayMode = .never
			appDelegate.serverListTableViewController?.navigationController?.pushViewController(viewController: rootViewController, animated: true, completion: {
				appDelegate.serverListTableViewController?.navigationController?.setNavigationBarHidden(true, animated: false)
			})
		}
	}
}
