//
//  INIFile.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.04.24.
//  Copyright © 2024 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2024, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

public class INISection {
	public var title: String
	public var keyValuePairs: [(String, String)]

	public init(title: String, keyValuePairs: [(String, String)]) {
		self.title = title
		self.keyValuePairs = keyValuePairs
	}

	public func addPair(key: String, value: String) {
		keyValuePairs.append((key, value))
	}

	public func value(forFirst key: String) -> String? {
		return keyValuePairs.first { (pairKey, pairValue) in
			return pairKey == key
		}?.1
	}
}

public class INIFile {
	public var sections: [INISection]

	public init(with sections: [INISection]) {
		self.sections = sections
	}

	convenience public init(with data: Data) {
		var parsedSections: [INISection] = []

		if let string = String(data: data, encoding: .utf8) {
			let lines = string.components(separatedBy: .newlines)
			var currentSection: INISection?

			for line in lines {
				if line.hasPrefix("["), line.hasSuffix("]") {
					let sectionTitle = line[line.index(after: line.startIndex)..<line.index(before: line.endIndex)]

					currentSection = INISection(title: String(sectionTitle), keyValuePairs: [])

					if let currentSection {
						parsedSections.append(currentSection)
					}
				} else {
					if let equalRange = line.range(of: "="), let currentSection {
						let key = line[line.startIndex..<equalRange.lowerBound]
						let value = line[equalRange.upperBound..<line.endIndex]

						currentSection.addPair(key: String(key), value: String(value))
					}
				}
			}
		}

		self.init(with: parsedSections)
	}

	public var composedString: String {
		var composedString: String = ""

		for section in sections {
			composedString = composedString.appending("[\(section.title)]").appendingFormat("\n")
			for keyValuePair in section.keyValuePairs {
				composedString = composedString.appending("\(keyValuePair.0)=\(keyValuePair.1)").appendingFormat("\n")
			}
		}

		return composedString
	}

	public var data: Data? {
		return composedString.data(using: .utf8)
	}

	public func firstSection(titled title: String) -> INISection? {
		return sections.first { section in section.title == title }
	}
}
