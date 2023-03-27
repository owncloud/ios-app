//
//  ThemeCSSRecord.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 19.03.23.
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

import UIKit

open class ThemeCSSRecord: NSObject {
	open var selectors: [ThemeCSSSelector]
	open var property: ThemeCSSProperty
	open var important: Bool

	public init(selectors: [ThemeCSSSelector], property: ThemeCSSProperty, value: Any?, important: Bool = false) {
		self.selectors = selectors
		self.property = property
		self.value = value
		self.important = important
	}

	convenience init?(with selectorString: String, value: Any) {
		var selectorsAndProperty = selectorString.components(separatedBy: ".")

		let propertyName = selectorsAndProperty.last
		selectorsAndProperty.removeLast()

		guard let propertyName else { return nil }

		let property = ThemeCSSProperty(rawValue: propertyName)

		let parsedSelectors: [ThemeCSSSelector] = selectorsAndProperty.compactMap { selectorString in
			return ThemeCSSSelector(rawValue: selectorString)
		}

		self.init(selectors: parsedSelectors, property: property, value: value)
	}

	open var value: Any?

	open func score(for inSelectors: [ThemeCSSSelector], property inProperty: ThemeCSSProperty) -> Int {
		var score: Int = 0

		if inProperty != property {
			// Not applicable
			return -1
		} else {
			// Property match
			score += 1
		}

		// Direct match of most specific (== last) selector
		if let typeSelector = inSelectors.last, selectors.last == typeSelector {
			score += 100
		}

		// Match selectors
		for selector in selectors {
			// Matches weighted by position, the farther along the higher the specificity/score,
			// so that "collection.cell" does not override "segments" for "collection.cell.segments.title"
			if let inSelectorIndex = inSelectors.firstIndex(of: selector) {
				score += (inSelectorIndex + 1) * 10
			} else {
				return -1
			}

			// All matches weighted equal,
			// but then "collection.cell" overrides "segments" for "collection.cell.segments.title"
			//
			// if inSelectors.contains(selector) {
			//	score += 10
			// } else {
			//	return -1
			// }
		}

		// Important
		if important {
			score += 1000
		}

		// Property match
		return score
	}
}
