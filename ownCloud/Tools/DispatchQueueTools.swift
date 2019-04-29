//
//  DispatchQueueTools.swift
//  ownCloud
//
//  Created by Felix Schwarz on 05.05.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2018, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import Foundation

func OnMainThread(async: Bool = true, after: TimeInterval? = nil, inline: Bool = false, _ block: @escaping () -> Void) {
	if inline {
		if Thread.isMainThread {
			block()
			return
		}
	}

	if let after = after {
		DispatchQueue.main.asyncAfter(deadline: .now() + after, execute: block)
	} else {
		if async {
			DispatchQueue.main.async(execute: block)
		} else {
			DispatchQueue.main.sync(execute: block)
		}
	}
}

func OnBackgroundQueue(async: Bool = true, after: TimeInterval? = nil, _ block: @escaping () -> Void) {
	if let after = after {
		DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + after, execute: block)
	} else {
		if async {
			DispatchQueue.global(qos: .background).async(execute: block)
		} else {
			DispatchQueue.global(qos: .background).sync(execute: block)
		}
	}
}
