//
//  UserInterfaceContext.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 17.07.20.
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

public protocol UserInterfaceContextProvider: class {
	func provideMainWindow() -> ThemeWindow? /// provide

	func provideCurrentWindow() -> ThemeWindow? // provide front-most window
}

open class UserInterfaceContext: NSObject {
	static public var shared : UserInterfaceContext = {
		let context = UserInterfaceContext()

		if let provider = context as? UserInterfaceContextProvider {
			context.provider = provider
		}

		return context
	}()

	public var provider : UserInterfaceContextProvider?

	public var mainWindow : ThemeWindow? {
		return provider?.provideMainWindow()
	}

	public var currentWindow : ThemeWindow? {
		return provider?.provideCurrentWindow()
	}
}
