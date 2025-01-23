//
//  main.swift
//  ocstringstool
//
//  Created by Felix Schwarz on 24.08.23.
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

import Foundation

// MARK: - Types
enum Command: String {
	case normalize
}

// MARK: - Parsing
if CommandLine.argc < 3 {
	print("ocstringstool normalize [base folder 1] …")
	exit(0)
}

let arguments = CommandLine.arguments
let command = Command(rawValue: arguments[1])
var argIdx = 2

switch command {
	case .normalize:
		while argIdx < CommandLine.argc {
			let rootPath = arguments[argIdx]
			commandNormalize(rootPath: rootPath)
			argIdx += 1
		}

	default:
		print("Unknown command \(command?.rawValue ?? "")")
		exit(-1)
}

// MARK: - Commands
func commandNormalize(rootPath locRootPath: String) {
	let locRootURL = NSURL(fileURLWithPath: locRootPath)
	var convertedFilesCount = 0

	print("[normalize] scanning \(locRootURL.path ?? locRootPath)")

	if let enumerator = FileManager.default.enumerator(at: locRootURL as URL, includingPropertiesForKeys: [ .isDirectoryKey, .nameKey ]) {
		for case let fileURL as URL in enumerator {
			guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .nameKey]),
			      let isDirectory = resourceValues.isDirectory,
			      let fileName = resourceValues.name
			else {
				continue
			}

			var encoding: String.Encoding = .utf8

			if !isDirectory {
				if fileName.hasSuffix(".strings"),
				   let strings = try? String(contentsOf: fileURL, usedEncoding: &encoding), encoding != .utf8 {
					print("[normalize] converting \(fileURL.absoluteString) to UTF-8…")
					if let utf8Data = strings.data(using: .utf8, allowLossyConversion: false) {
						try? utf8Data.write(to: fileURL)
						convertedFilesCount += 1
					}
				}

				if fileName.hasSuffix(".xcstrings"),
				   let data = try? Data(contentsOf: fileURL),
				   let jsonObj = try? JSONSerialization.jsonObject(with: data) {
					print("[normalize] normalizing \(fileURL.absoluteString) to AppleJSON[sortedKeys,prettyPrinted,withoutEscapingSlashes]…")

					if let reformattedJSONData = try? JSONSerialization.data(withJSONObject: jsonObj, options: [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]) {
						try? reformattedJSONData.write(to: fileURL)
						convertedFilesCount += 1
					}
				}
			}
		}
	}

	print("[normalize] converted \(convertedFilesCount) files in \(locRootURL.path ?? locRootPath)")
}
