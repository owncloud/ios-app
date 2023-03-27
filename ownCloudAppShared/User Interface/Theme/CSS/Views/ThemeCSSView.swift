//
//  ThemeCSSView.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 20.03.23.
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
import ownCloudApp

open class ThemeCSSView: UIView, Themeable {
	private var hasRegistered : Bool = false

	public init() {
		super.init(frame: .zero)
	}

	public override init(frame: CGRect) {
		super.init(frame: frame)
	}

	convenience public init(withSelectors: [ThemeCSSSelector]) {
		self.init()
		cssSelectors = withSelectors
	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override open func didMoveToWindow() {
		super.didMoveToWindow()

		if window != nil, !hasRegistered {
			hasRegistered = true
			Theme.shared.register(client: self, applyImmediately: true)
		}
	}

	private var themeAppliers : [ThemeApplier] = []

	open func addThemeApplier(_ applier: @escaping ThemeApplier) {
		themeAppliers.append(applier)
	}

	open func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		for applier in themeAppliers {
			applier(theme, collection, event)
		}

		apply(css: collection.css, properties: [.fill])
	}
}
