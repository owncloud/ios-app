//
//  ResourceViewHost.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 24.01.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK
import ownCloudApp

public class ResourceViewHost: OCViewHost, Themeable {
	private var hasRegistered : Bool = false

	deinit {
		if hasRegistered {
			Theme.shared.unregister(client: self)
		}
	}

	public override func didMoveToSuperview() {
		if self.superview != nil {
			if !hasRegistered {
				hasRegistered = true
				Theme.shared.register(client: self, applyImmediately: true)
			}
		}
	}

	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		if let themableViewProvider = activeViewProvider as? ThemableViewProvider {
			if themableViewProvider.needsRefreshOnThemeChange {
				reloadView()
			}
		}
	}
}

protocol ThemableViewProvider: OCViewProvider {
	var needsRefreshOnThemeChange : Bool { get }
}
