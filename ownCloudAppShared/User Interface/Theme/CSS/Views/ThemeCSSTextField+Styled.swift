//
//  ThemeCSSTextField+Styled.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 13.12.24.
//  Copyright © 2024 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2024, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

extension ThemeCSSTextField {
	static func formField(withPlaceholder: String?, text: String? = nil, accessibilityLabel: String? = nil) -> ThemeCSSTextField {
		let textField = ThemeCSSTextField()
		textField.translatesAutoresizingMaskIntoConstraints = false
		textField.setContentHuggingPriority(.required, for: .vertical)
		textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
		textField.placeholder = withPlaceholder
		textField.text = text
		textField.accessibilityLabel = accessibilityLabel
		textField.clearButtonMode = .whileEditing
		return textField
	}
}
