//
//  LocalizationTests.swift
//  ownCloudTests
//
//  Created by Felix Schwarz on 23.08.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import XCTest

final class LocalizationTests: XCTestCase {
	func testConvertLocalizableUTF16() throws {
		if let locRootPath = ProcessInfo.processInfo.environment["OC_LOCALIZATION_ROOT"] {
			let locRootURL = NSURL(fileURLWithPath: locRootPath)
			if let enumerator = FileManager.default.enumerator(at: locRootURL as URL, includingPropertiesForKeys: [ .isDirectoryKey, .nameKey ]) {
				for case let fileURL as URL in enumerator {
					guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .nameKey]),
					      let isDirectory = resourceValues.isDirectory,
					      let fileName = resourceValues.name
					else {
						continue
					}

					var encoding: String.Encoding = .utf8

					if !isDirectory, fileName.hasSuffix(".strings"),
					   let strings = try? String(contentsOf: fileURL, usedEncoding: &encoding), encoding != .utf8 {
					   	if let utf8Data = strings.data(using: .utf8, allowLossyConversion: false) {
					   		try? utf8Data.write(to: fileURL)
						}
					}
				}
			}
		}
    	}
}
