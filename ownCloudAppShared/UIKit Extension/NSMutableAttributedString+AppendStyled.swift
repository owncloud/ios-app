//
//  NSMutableAttributedString+AppendStyled.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 20.04.22.
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

public extension NSMutableAttributedString {
	var boldFont: UIFont { return UIFont.preferredFont(forTextStyle: .headline) }
	var normalFont: UIFont { return UIFont.preferredFont(forTextStyle: .subheadline) }

	func appendBold(_ value:String) -> NSMutableAttributedString {
		let attributes:[NSAttributedString.Key : Any] = [
			.font : boldFont
		]

		self.append(NSAttributedString(string: value, attributes:attributes))
		return self
	}

	func appendNormal(_ value:String) -> NSMutableAttributedString {
		let attributes:[NSAttributedString.Key : Any] = [
			.font : normalFont
		]

		self.append(NSAttributedString(string: value, attributes:attributes))
		return self
	}
}
