//
//  LicenseOfferButton.swift
//  ownCloud
//
//  Created by Felix Schwarz on 11.12.19.
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
import ownCloudAppShared

class LicenseOfferButton: ThemeButton {
	var originalTitle : String?

	init(purchaseButtonWithTitle title: String, target: Any? = nil, action: Selector? = nil) {
		super.init(frame: .zero)

		self.translatesAutoresizingMaskIntoConstraints = false
		self.setContentCompressionResistancePriority(.required, for: .horizontal)
		self.setContentCompressionResistancePriority(.required, for: .vertical)
		self.buttonFont = UIFont.systemFont(ofSize: UIFont.labelFontSize)
		self.buttonVerticalPadding = -5
		self.buttonHorizontalPadding = 23
		self.buttonCornerRadius = .round

		originalTitle = title
		self.setTitle(title, for: .normal)

		if let action = action {
			self.addTarget(target, action: action, for: .primaryActionTriggered)
		}
	}

	init(subscribeButtonWithTitle title: String, target: Any? = nil, action: Selector? = nil) {
		super.init(frame: .zero)

		self.translatesAutoresizingMaskIntoConstraints = false
		self.buttonFont = UIFont.systemFont(ofSize: UIFont.labelFontSize)

		self.buttonVerticalPadding = 15
		self.buttonCornerRadius = .medium

		self.setTitle(title, for: .normal)

		if let action = action {
			self.addTarget(target, action: action, for: .primaryActionTriggered)
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
