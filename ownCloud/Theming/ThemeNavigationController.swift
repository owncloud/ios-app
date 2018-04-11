//
//  ThemeNavigationViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 11.04.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit

class ThemeNavigationController: UINavigationController {
	private var themeToken : ThemeApplierToken?

	override var preferredStatusBarStyle : UIStatusBarStyle {
		return Theme.shared.activeCollection.statusBarStyle
	}

	override func viewDidLoad() {
		themeToken = Theme.shared.add(applier: { (_, themeCollection, event) in
			self.applyThemeCollection(themeCollection)
			self.toolbar.applyThemeCollection(themeCollection)

			if event == .update {
				self.setNeedsStatusBarAppearanceUpdate()
			}
		}, applyImmediately: true)
	}

	deinit {
		Theme.shared.remove(applierForToken: themeToken)
	}
}
