//
//  ThemeNavigationViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 11.04.18.
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

import UIKit

public protocol CustomStatusBarViewControllerProtocol : AnyObject {
	func statusBarStyle() -> UIStatusBarStyle
}

open class ThemeNavigationController: UINavigationController, Themeable {
	public enum ThemeNavigationControllerStyle {
		case regular
		case splitViewContent
	}

	public var style: ThemeNavigationControllerStyle = .regular {
		didSet {
			applyThemeCollection(theme: Theme.shared, collection: Theme.shared.activeCollection, event: .initial)
		}
	}

	override open var preferredStatusBarStyle : UIStatusBarStyle {
		if let object = self.viewControllers.last, self.presentedViewController == nil, let loginViewController = object as? CustomStatusBarViewControllerProtocol {
			return loginViewController.statusBarStyle()
		}

		return Theme.shared.activeCollection.css.getStatusBarStyle(for: self) ?? .default
	}

	open override var childForStatusBarStyle: UIViewController? {
		return nil
	}

	override open func viewDidLoad() {
		super.viewDidLoad()
		applyThemeCollection(theme: Theme.shared, collection: Theme.shared.activeCollection, event: .initial)
	}

	open override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		Theme.shared.register(client: self, applyImmediately: true)
	}

	open var popLastHandler : ((UIViewController?) -> Bool)?

	open override func popViewController(animated: Bool) -> UIViewController? {
		if let popLastHandler = popLastHandler {
			let viewControllerToPop = self.viewControllers.count > 1 ? self.viewControllers[self.viewControllers.count-2] : self.viewControllers.last

			if popLastHandler(viewControllerToPop) {
				return super.popViewController(animated: animated)
			} else {
				// Avoid empty navigation bar bug when returning nil
				self.pushViewController(UIViewController(), animated: false)
				return super.popViewController(animated: false)
			}
		}

		return super.popViewController(animated: animated)
	}

	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.applyThemeCollection(collection)
		self.toolbar.applyThemeCollection(collection)
		self.view.backgroundColor = .clear

		if event == .update {
			self.setNeedsStatusBarAppearanceUpdate()
		}
	}
}
