//
//  Application.swift
//  ownCloudAppShared
//
//  Created by Matthias Hühne on 11.03.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2020, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

open class Application {
	static var shared: UIApplication {
		let sharedSelector = NSSelectorFromString("sharedApplication")
		guard UIApplication.responds(to: sharedSelector) else {
			fatalError("[Extensions cannot access Application]")
		}
		let shared = UIApplication.perform(sharedSelector)
		return shared?.takeUnretainedValue() as! UIApplication
	}
}
