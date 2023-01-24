//
//  BrowserNavigationItem.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 16.01.23.
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

public protocol BrowserNavigationTrimming {
	var browserNavigationBuilder: BrowserNavigationItem.Builder? { get }
}

open class BrowserNavigationItem: NSObject {
	public typealias Builder = (_ item: BrowserNavigationItem) -> UIViewController?

	private var _viewController: UIViewController?
	open var viewController: UIViewController? {
		if let _viewController {
			return _viewController
		}

		if let builder {
			_viewController = builder(self)
			return _viewController
		}

		return nil
	}
	open var builder: Builder?

	init(viewController: UIViewController? = nil, builder: Builder? = nil) {
		super.init()

		_viewController = viewController
		self.builder = builder

		if self.builder == nil, let trimmingSupport = viewController as? BrowserNavigationTrimming  {
			self.builder = trimmingSupport.browserNavigationBuilder
		}
	}

	open func trim() {
		if builder != nil {
			_viewController = nil
		}
	}
}
