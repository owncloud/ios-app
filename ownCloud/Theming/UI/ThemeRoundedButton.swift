//
//  ThemeRoundedButton.swift
//  ownCloud
//
//  Created by Matthias Hühne on 28.01.19.
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

class ThemeRoundedButton: ThemeButton {

	override init(frame: CGRect) {
		super.init(frame: frame)

		self.buttonCornerRadius = -1
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

		self.buttonCornerRadius = -1
	}

}
