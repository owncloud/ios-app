//
//  TVGImageAttribute.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 13.02.26.
//  Copyright © 2026 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2026, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

public class TVGImageAttribute: NSObject {
	public enum Name: String {
		case fill = "fill"
		case stroke = "stroke"
	}

	public var name: Name
	public var varName: String?

	var dict: [String: Any]?

	init(name: Name, dict: [String: Any]) {
		self.name = name
		self.varName = dict["variable"] as? String
		self.dict = dict
	}

	func color(forDark: Bool) -> UIColor? {
		guard let dict, let colorString = (dict[forDark ? "dark" : "light"] ?? dict[forDark ? "light" : "dark"] ?? dict["default"]) as? String else {
		      return nil
		}

		return UIColor(from: colorString)
	}
}
