//
//  String+Extension.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 05/04/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2018, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import Foundation
import UIKit

private let _sharedAppBundle = Bundle(identifier: "com.owncloud.ownCloudAppShared")

public extension Bundle {
	static var sharedAppBundle : Bundle {
		return _sharedAppBundle!
	}
}

extension String {

	public var localized: String {
		return NSLocalizedString(self, comment: "")
	}

	public var slocalized : String {
		return NSLocalizedString(self, tableName: nil, bundle: Bundle.sharedAppBundle, value: self, comment: "")
	}

	public var isNumeric: Bool {
		let nonDigitsCharacterSet = CharacterSet.decimalDigits.inverted
		return !self.isEmpty && rangeOfCharacter(from: nonDigitsCharacterSet) == nil
	}

	public var pathRepresentation : String {
		if !self.hasSuffix("/") {
			return String(format: "%@/", self)
		}
		return self
	}

	public func matches(regExp: String) -> Bool {
		guard let regex = try? NSRegularExpression(pattern: regExp) else { return false }
		let range = NSRange(location: 0, length: self.count)
		return regex.firstMatch(in: self, options: [], range: range) != nil
	}

	public func matches(for regex: String) -> [String] {
		do {
			let regex = try NSRegularExpression(pattern: regex)
			let results = regex.matches(in: self,
										range: NSRange(self.startIndex..., in: self))
			return results.map {
				String(self[Range($0.range, in: self)!])
			}
		} catch _ {
			return []
		}
	}

	public func replacingOccurrences(for regex: String) -> String {
		if let regex = try? NSRegularExpression(pattern: regex, options: .caseInsensitive) {
			return regex.stringByReplacingMatches(in: self, options: [], range: NSRange(location: 0, length:  self.count), withTemplate: "")
		}
		return self
	}

	public func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
		let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
		let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)

		return ceil(boundingBox.width)
	}
}
