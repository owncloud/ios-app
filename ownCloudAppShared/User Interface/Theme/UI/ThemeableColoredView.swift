//
//  ThemeableColoredView.swift
//  ownCloud
//
//  Created by Matthias Hühne on 18.02.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

open class ThemeableColoredView: UIView, Themeable {

	// MARK: - Instance variables.

	var messageThemeApplierToken : ThemeApplierToken?

	override public init(frame: CGRect) {
		super.init(frame: frame)

		Theme.shared.register(client: self, applyImmediately: true)
	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)

		if messageThemeApplierToken != nil {
			Theme.shared.remove(applierForToken: messageThemeApplierToken)
			messageThemeApplierToken = nil
		}
	}

	// MARK: - Theme support

	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.backgroundColor = collection.navigationBarColors.backgroundColor
	}
}
