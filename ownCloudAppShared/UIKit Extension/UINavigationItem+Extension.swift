//
//  UINavigationItem+Extension.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 08.12.22.
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

public extension UINavigationItem {
	var titleLabel: UILabel? {
		return titleView as? UILabel
	}

	var titleLabelText: String? {
		// In iOS 16, titles can get cut off when using UINavigationItem.title - this works around this bug
		get {
			return titleLabel?.text
		}

		set {
			if titleView == nil {
				let navigationTitleLabel = UILabel()
				navigationTitleLabel.font = UIFont.systemFont(ofSize: UIFont.buttonFontSize, weight: .semibold)
				navigationTitleLabel.lineBreakMode = .byTruncatingMiddle
				navigationTitleLabel.textColor = Theme.shared.activeCollection.navigationBarColors.labelColor
				navigationTitleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
				titleView = navigationTitleLabel
			}

			titleLabel?.text = newValue
		}
	}
}
