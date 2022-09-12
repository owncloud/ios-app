//
//  UIFont+Weight.swift
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

public extension UIFont {
	static func preferredFont(forTextStyle textStyle: UIFont.TextStyle, with weight: UIFont.Weight) -> UIFont {
		let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)
		let font = UIFont.systemFont(ofSize: fontDescriptor.pointSize, weight: weight)
		let fontMetrics = UIFontMetrics(forTextStyle: textStyle)

		return fontMetrics.scaledFont(for: font)
	}
}
