//
//  UIBarButtonItem+Extension.swift
//  ownCloud
//
//  Created by Michael Neuwert on 24.01.2019.
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

public extension UIBarButtonItem {

	private struct imageFrame {
		static var x = 0.0
		static var y = 0.0
		static var width = 30.0
		static var height = 30.0
	}

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

	convenience init(image: UIImage?, target: AnyObject, action: Selector, dropTarget: AnyObject, actionIdentifier: OCExtensionIdentifier) {
		let button  = UIButton(type: .custom)
		button.setImage(image, for: .normal)
		button.frame = CGRect(x: imageFrame.x, y: imageFrame.y, width: imageFrame.width, height: imageFrame.height)
		button.actionIdentifier = actionIdentifier
		button.addTarget(target, action: action, for: .touchUpInside)
		button.sizeToFit()

		if let dropDelegate = dropTarget as? UIDropInteractionDelegate {
			let dropInteraction = UIDropInteraction(delegate: dropDelegate)
			button.addInteraction(dropInteraction)
		}

		self.init(customView: button)
		self.actionIdentifier = actionIdentifier
	}
}
