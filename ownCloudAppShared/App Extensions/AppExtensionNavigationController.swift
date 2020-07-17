//
//  AppExtensionNavigationController.swift
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

@objc(AppExtensionNavigationController)
open class AppExtensionNavigationController: ThemeNavigationController {
	// MARK: - UserInterfaceContext glue
	static public weak var mainNavigationController : ThemeNavigationController? {
		didSet {
			ThemeStyle.considerAppearanceUpdate()
		}
	}

	// MARK: - Theme change detection
	public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)

		if #available(iOS 13.0, *) {
			if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
				ThemeStyle.considerAppearanceUpdate()
			}
		}
	}

	// MARK: - Entry point
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

		ThemeStyle.registerDefaultStyles()
		AppExtensionNavigationController.mainNavigationController = self

		setupViewControllers()
	}

	open func setupViewControllers() {
		// Subclass entry point
	}

	@available(*, unavailable)
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
}
