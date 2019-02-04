//
//  EarlGrey+Tools.swift
//  ownCloudTests
//
//  Created by Felix Schwarz on 24.01.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

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
