//
//  NavigationRevocationManager.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 22.11.22.
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

open class NavigationRevocationManager: NSObject {
	var actions: NSHashTable<NavigationRevocationAction>

	public static var shared : NavigationRevocationManager = {
		return NavigationRevocationManager()
	}()

	override init() {
		self.actions = NSHashTable<NavigationRevocationAction>.weakObjects()
	}

	open func register(action: NavigationRevocationAction) {
		OCSynchronized(self) {
			actions.add(action)
		}
	}

	open func unregister(action: NavigationRevocationAction) {
		OCSynchronized(self) {
			actions.remove(action)
		}
	}

	open func handle(event: NavigationRevocationEvent) {
		OCSynchronized(self) {
			for action in self.actions.allObjects {
				if action.handle(event: event) {
					self.actions.remove(action)
				}
			}
		}
	}
}
