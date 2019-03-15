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

extension String {

    var localized: String {
        return NSLocalizedString(self, comment: "")
    }

    var isNumeric: Bool {
        let nonDigitsCharacterSet = CharacterSet.decimalDigits.inverted
        return !self.isEmpty && rangeOfCharacter(from: nonDigitsCharacterSet) == nil
    }

	func matches (regExp: String) -> Bool {
			guard let regex = try? NSRegularExpression(pattern: regExp) else { return false }
			let range = NSRange(location: 0, length: self.count)
			return regex.firstMatch(in: self, options: [], range: range) != nil
	}
}
