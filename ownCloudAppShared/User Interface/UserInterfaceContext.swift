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
	func provideRootView() -> UIView? /// provide "root-most" view for app

	func provideCurrentWindow() -> UIWindow? // provide front-most window of the app
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

	public var rootView : UIView? {
		return provider?.provideRootView()
	}

	public var currentWindow : UIWindow? {
		return provider?.provideCurrentWindow()
	}
}
