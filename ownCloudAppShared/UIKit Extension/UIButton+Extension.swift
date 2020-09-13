//
//  UIButton+Extension.swift
//  ownCloud
//
//  Created by Matthias Hühne on 13.03.2019.
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

import Foundation
import UIKit
import ownCloudSDK

public extension UIButton {
	private struct AssociatedKeys {
		static var actionKey = "actionKey"
	}

	var actionIdentifier: OCExtensionIdentifier? {
		get {
			return objc_getAssociatedObject(self, &AssociatedKeys.actionKey) as? OCExtensionIdentifier
		}

		set {
			if newValue != nil {
				objc_setAssociatedObject(self, &AssociatedKeys.actionKey, newValue!, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
			}
		}
	}
}
