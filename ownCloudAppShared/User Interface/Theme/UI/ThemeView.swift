//
//  ThemeView.swift
//  ownCloud
//
//  Created by Felix Schwarz on 27.11.18.
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

open class ThemeView: UIView, Themeable {
	private var hasRegistered : Bool = false

	public init() {
		super.init(frame: .zero)
	}

	deinit {
		if hasRegistered {
			Theme.shared.unregister(client: self)
		}
	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override open func didMoveToSuperview() {
		super.didMoveToSuperview()

		if self.superview != nil {
			if !hasRegistered {
				setupSubviews()

				hasRegistered = true
				Theme.shared.register(client: self, applyImmediately: true)
			}
		}
	}

	private var themeAppliers : [ThemeApplier] = []

	open func setupSubviews() {
		// Override point for subclasses
	}

	open func addThemeApplier(_ applier: @escaping ThemeApplier) {
		themeAppliers.append(applier)
	}

	open func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		for applier in themeAppliers {
			applier(theme, collection, event)
		}
	}
}