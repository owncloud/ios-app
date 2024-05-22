//
//  OCAction+UIAction.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 23.10.23.
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
import ownCloudSDK

public extension OCAction {
	func uiAction(with options: [OCActionRunOptionKey : Any]? = nil) -> UIAction {
		return UIAction(title: title, image: icon, attributes: [], handler: { action in
			self.run(options: options)
		})
	}

	func accessibilityCustomAction(with options: [OCActionRunOptionKey : Any]? = nil) -> UIAccessibilityCustomAction {
		return UIAccessibilityCustomAction(name: title, image: icon) { _ in
			self.run(options: options)
			return true
		}
	}
}
