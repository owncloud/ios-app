//
//  OCQueryCondition+SearchToken.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 22.08.22.
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
import ownCloudSDK

extension SearchElement {
	func isEquivalent(to condition: OCQueryCondition) -> Bool {
		if let token = self as? SearchToken, let tokenCondition = token.representedObject as? OCQueryCondition {
			return tokenCondition.isEquivalent(to: condition)
		}

		return false
	}
}

extension OCQueryCondition {
	func isEquivalent(to condition: OCQueryCondition) -> Bool {
		return (condition.localizedDescription == localizedDescription) && (condition.symbolName == symbolName)
	}

	var firstNonLogicalCondition: OCQueryCondition? {
		switch self.operator {
			case .negate, .or, .and:
				if let condition = self.value as? OCQueryCondition {
					return condition
				}

			default:
				return self
		}

		return self
	}

	var firstDescriptiveCondition: OCQueryCondition? {
		if localizedDescription != nil {
			return self
		} else {
			if let condition = self.value as? OCQueryCondition {
				return condition.firstDescriptiveCondition
			} else if let conditions = self.value as? [OCQueryCondition] {
				for condition in conditions {
					if let descriptiveCondition = condition.firstDescriptiveCondition {
						return descriptiveCondition
					}
				}
			}
		}

		return nil
	}

	func generateSearchToken(fallbackText: String, inputComplete: Bool) -> SearchToken? {
		// Use existing description and symbol
		if let firstDescriptiveCondition = firstDescriptiveCondition, let localizedDescription = firstDescriptiveCondition.localizedDescription {
			return SearchToken(text: localizedDescription, icon: OCSymbol.icon(forSymbolName: firstDescriptiveCondition.symbolName), representedObject: self, inputComplete: inputComplete)
		}

		// Try to determine a useful icon and description
		guard let effectiveCondition = firstNonLogicalCondition, let effectiveProperty = effectiveCondition.property else {
			return nil
		}

		let effectiveOperator = effectiveCondition.operator
		var icon : UIImage?

		switch effectiveProperty {
			case .name:
				if effectiveOperator == .propertyHasSuffix {
					icon = UIImage(systemName: "smallcircle.filled.circle")
				}

			case .driveID:
				icon = UIImage(systemName: "square.grid.2x2")

			case .mimeType:
				icon = UIImage(systemName: "photo")

			case .size:
				switch effectiveOperator {
					case .propertyGreaterThanValue:
						icon = UIImage(systemName: "greaterthan")

					case .propertyLessThanValue:
						icon = UIImage(systemName: "lessthan")

					case .propertyEqualToValue:
						icon = UIImage(systemName: "equal")

					default: break
				}

			case .ownerUserName: break

			case .lastModified:
				icon = UIImage(systemName: "calendar")

			default: break
		}

		return SearchToken(text: localizedDescription ?? fallbackText, icon: icon, representedObject: self, inputComplete: inputComplete)
	}
}
