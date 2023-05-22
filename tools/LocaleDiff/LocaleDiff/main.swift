//
//  main.swift
//  LocaleDiff
//
//  Created by Felix Schwarz on 07.10.22.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import Foundation

if CommandLine.argc < 2 {
	print("LocaleDiff [base Localizable.strings] [translated Localizable.strings] …")
} else {
	let arguments = CommandLine.arguments
	var argIdx = 1

	while argIdx+1 < CommandLine.argc {
		let baseStringsURL = URL(fileURLWithPath: arguments[argIdx])
		let translatedStringsURL = URL(fileURLWithPath: arguments[argIdx+1])

		if let baseStringsData = try? Data(contentsOf: baseStringsURL),
		   let baseStringsDict = try? PropertyListSerialization.propertyList(from: baseStringsData, format: nil) as? [String:String],
		   let translatedStringsData = try? Data(contentsOf: translatedStringsURL),
		   let translatedStringsDict = try? PropertyListSerialization.propertyList(from: translatedStringsData, format: nil) as? [String:String] {
			let baseKeys = Set<String>(baseStringsDict.keys)
			let translatedKeys = Set<String>(translatedStringsDict.keys)

			let superfluousKeys = translatedKeys.subtracting(baseKeys)
			let untranslatedKeys = baseKeys.subtracting(translatedKeys)

			if !superfluousKeys.isEmpty {
				print("⛔️ Superfluous keys in \(translatedStringsURL.path):")

				for superfluousKey in superfluousKeys {
					print("- \(superfluousKey)")
				}
			}

			if !untranslatedKeys.isEmpty {
				print("⚠️ Untranslated keys in \(translatedStringsURL.path):")

				for untranslatedKey in untranslatedKeys {
					let translationTemplate = "\"\(untranslatedKey.replacingOccurrences(of: "\"", with: "\\\""))\""

					print("\(translationTemplate) = \(translationTemplate);")
				}
			}
		}

		argIdx += 2
	}
}
