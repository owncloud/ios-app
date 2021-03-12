//
//  DisplaySleepPreventer.swift
//  ownCloud
//
//  Created by Felix Schwarz on 25.03.20.
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

class DisplaySleepPreventer : NSObject {
	static var shared : DisplaySleepPreventer = DisplaySleepPreventer()

	typealias Reason = String

	private var preventCount : Int = 0
	private var preventReasons : Set<Reason> = Set()

	private var effectiveReasonCount : Int {
		return preventCount + preventReasons.count
	}

	func isPreventing(for reason: Reason) -> Bool {
		return preventReasons.contains(reason)
	}

	func startPreventingDisplaySleep(for reason: Reason? = nil) {
		if effectiveReasonCount == 0 {
			UIApplication.shared.isIdleTimerDisabled = true
		}

		if let reason = reason {
			preventReasons.insert(reason)
		} else {
			preventCount += 1
		}
	}

	func stopPreventingDisplaySleep(for reason: Reason? = nil) {
		if effectiveReasonCount > 0 {
			if let reason = reason {
				preventReasons.remove(reason)
			} else {
				preventCount -= 1
			}

			if effectiveReasonCount == 0 {
				UIApplication.shared.isIdleTimerDisabled = false
			}
		}
	}
}
