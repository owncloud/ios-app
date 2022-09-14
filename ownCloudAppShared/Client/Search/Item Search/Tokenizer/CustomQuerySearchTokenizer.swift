//
//  CustomQuerySearchTokenizer.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 25.08.22.
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
import ownCloudApp

open class CustomQuerySearchTokenizer : SearchTokenizer {
	open override func shouldTokenize(segment: OCSearchSegment) -> SearchToken? {
		// Determine if that parsing this segment would result in a non-itemname query condition
		if let queryCondition = OCQueryCondition.fromSearchTerm(segment.segmentedString) {
			if let property = queryCondition.property {
				if (property != .name) || (queryCondition.operator != .propertyContains) {
					// Non-itemname, property-based query condition -> generate search token
					return queryCondition.generateSearchToken(fallbackText: segment.segmentedString, inputComplete: !segment.hasCursor)
				}
			} else {
				// Non-itemname, logic-based query condition -> generate search token
				return queryCondition.generateSearchToken(fallbackText: segment.segmentedString, inputComplete: !segment.hasCursor)
			}
		}

		// Do not generate a search token
		return nil
	}

	open override func composeTextElement(segment: OCSearchSegment) -> SearchElement {
		// Compose search element with query condition representation
		return SearchElement(text: segment.segmentedString, representedObject: OCQueryCondition.fromSearchTerm(segment.segmentedString), inputComplete: !segment.hasCursor)
	}
}
