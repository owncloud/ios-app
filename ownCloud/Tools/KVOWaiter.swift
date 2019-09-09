//
//  KVOWaiter.swift
//  ownCloud
//
//  Created by Felix Schwarz on 11.06.19.
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

class KVOWaiter<T, V>: NSObject where T : NSObject {
	var observation : NSKeyValueObservation?

	private var objcAssociationHandle = 1

	@discardableResult init(observe obj: T, keyPath: KeyPath<T, V>, condition: @escaping (T) -> Bool, action: @escaping () -> Void) {
		super.init()

		let performCheck : (_ obj: T) -> Void = { [weak self] (obj) in
			if condition(obj) {
				action()

				if let self = self {
					objc_setAssociatedObject(obj, &self.objcAssociationHandle, nil, .OBJC_ASSOCIATION_RETAIN)
				}
			}
		}

		objc_setAssociatedObject(obj, &objcAssociationHandle, self, .OBJC_ASSOCIATION_RETAIN)

		observation = obj.observe(keyPath) { (obj, _) in
			performCheck(obj)
		}

		performCheck(obj)
	}

	deinit {
		observation?.invalidate()
	}
}
