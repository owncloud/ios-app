//
//  EarlGrey+Tools.swift
//  ownCloudTests
//
//  Created by Felix Schwarz on 24.01.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
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

import UIKit
import EarlGrey

extension EarlGrey {
	@discardableResult
	static func waitForElement(withMatcher: GREYMatcher, label: String, timeout: CFTimeInterval = 2) -> Bool {
		let condition : GREYCondition = GREYCondition(name: "Wait for \(label)") { () -> Bool in
			var error : NSError?

			EarlGrey.select(elementWithMatcher: withMatcher).assert(with: grey_notNil(), error: &error)

			return error == nil
		}

		return condition.wait(withTimeout: timeout)
	}

	@discardableResult
	static func waitForElementMissing(withMatcher: GREYMatcher, label: String, timeout: CFTimeInterval = 2) -> Bool {
		let condition : GREYCondition = GREYCondition(name: "Wait for \(label)") { () -> Bool in
			var error : NSError?

			EarlGrey.select(elementWithMatcher: withMatcher).assert(with: grey_nil(), error: &error)

			return error == nil
		}

		return condition.wait(withTimeout: timeout)
	}

	@discardableResult
	static func waitForElement(accessibilityID: String, timeout: CFTimeInterval = 2) -> Bool {
		return self.waitForElement(withMatcher: grey_accessibilityID(accessibilityID), label: accessibilityID, timeout: timeout)
	}

	@discardableResult
	static func waitForElementMissing(accessibilityID: String, timeout: CFTimeInterval = 2) -> Bool {
		return self.waitForElementMissing(withMatcher: grey_accessibilityID(accessibilityID), label: accessibilityID, timeout: timeout)
	}
}
