//
//  UITextField+Extension.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 09.08.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
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

import UIKit

public extension UITextField {
	var cursorPosition : Int? {
		if let selectedTextRange = selectedTextRange, selectedTextRange.isEmpty {
			return offset(from: beginningOfDocument, to: selectedTextRange.start)
		}
		return nil
	}
}

public extension UISearchTextField {
	var cursorPositionInTextualRange : Int? {
		if let selectedTextRange = selectedTextRange, selectedTextRange.isEmpty {
			return offset(from: textualRange.start, to: selectedTextRange.start)
		}
		return nil
	}

	func textRange(from range: NSRange) -> UITextRange? {
		let textualRange = textualRange
		if let startPosition = position(from: textualRange.start, offset: range.location),
		   let endPosition = position(from: startPosition, in: .right, offset: range.length) {
		   	return textRange(from: startPosition, to: endPosition)
		}

		return nil
	}
}
