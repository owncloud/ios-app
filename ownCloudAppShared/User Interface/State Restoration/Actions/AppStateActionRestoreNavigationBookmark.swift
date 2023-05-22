//
//  AppStateActionRestoreNavigationBookmark.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 09.02.23.
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

public class AppStateActionRestoreNavigationBookmark: AppStateAction {
	var navigationBookmark: BrowserNavigationBookmark?

	public init(navigationBookmark: BrowserNavigationBookmark, children: [AppStateAction]? = nil) {
		super.init(with: children)
		self.navigationBookmark = navigationBookmark
	}

	override open class var supportsSecureCoding: Bool {
		return true
	}

	public required init?(coder: NSCoder) {
		navigationBookmark = coder.decodeObject(of: BrowserNavigationBookmark.self, forKey: "navigationBookmark")
		super.init(coder: coder)
	}

	override public func encode(with coder: NSCoder) {
		super.encode(with: coder)
		coder.encode(navigationBookmark, forKey: "navigationBookmark")
	}

	override public func perform(in clientContext: ClientContext, completion: @escaping AppStateAction.Completion) {
		if let navigationBookmark {
			navigationBookmark.restore(in: nil, with: clientContext, completion: { (error, viewController) in
				defer {
					completion(error, clientContext)
				}

				guard error == nil else {
					return
				}

				_ = clientContext.pushViewControllerToNavigation(context: clientContext, provider: { context in
					return viewController
				}, push: true, animated: false)
			})
		} else {
			completion(NSError.init(ocError: .unknown), clientContext)
		}
	}
}

public extension AppStateAction {
	static func navigate(to navigationBookmark: BrowserNavigationBookmark, children: [AppStateAction]? = nil) -> AppStateActionRestoreNavigationBookmark {
		return AppStateActionRestoreNavigationBookmark(navigationBookmark: navigationBookmark, children: children)
	}
}
