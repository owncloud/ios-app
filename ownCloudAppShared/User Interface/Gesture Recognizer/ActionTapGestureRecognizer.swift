//
//  ActionTapGestureRecognizer.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 23.01.23.
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

open class ActionTapGestureRecognizer: UITapGestureRecognizer {
	typealias Action = (UITapGestureRecognizer) -> Void

	var action: Action

	init(action: @escaping Action) {
		self.action = action

		super.init(target: nil, action:nil) // can't pass self as target in super.init()
		self.addTarget(self, action: #selector(runAction))
	}

	@objc private func runAction(_ gestureRecognizer: UITapGestureRecognizer) {
		action(gestureRecognizer)
	}
}
