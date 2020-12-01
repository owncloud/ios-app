//
//  MetadataDocumentationTests.swift
//  ownCloudTests
//
//  Created by Felix Schwarz on 02.11.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2020, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import XCTest
import ownCloudSDK
import ownCloudAppShared

class MetadataDocumentationTests: XCTestCase {
	func testUpdateConfigurationJSONFromMetadata() throws {
	 	let sdkDocsURL = Bundle(for: type(of: self)).url(forResource: "class-settings-sdk", withExtension: nil)

		let docDict = OCClassSettings.shared.documentationDictionary(options: [
			.onlyJSONTypes : true,
			.externalDocumentationFolders : [ sdkDocsURL ]
		])

		if #available(iOS 13, *) {
			guard let jsonData = try? JSONSerialization.data(withJSONObject: docDict, options: [.prettyPrinted, .sortedKeys, .fragmentsAllowed, .withoutEscapingSlashes]) else {
				XCTFail("Failed encoding documentation dictionary as JSON")
				return
			}

			if let jsonString = String(data: jsonData, encoding: .utf8) {
				Log.debug("\(jsonString)")

				if let jsonPath = ProcessInfo.processInfo.environment["OC_SETTINGS_DOC_JSON"] {
					try? jsonData.write(to: URL(fileURLWithPath: jsonPath), options: .atomicWrite)
				}
			}
		} else {
			XCTFail("Test needs to be run on Simulator running iOS 13 or later")
		}
	}
}
