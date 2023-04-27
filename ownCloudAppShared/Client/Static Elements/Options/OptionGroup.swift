//
//  OptionGroup.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 20.04.23.
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

open class OptionGroup: NSObject {
	open var items: [OptionItem] = [] {
		willSet {
			for item in items {
				item.group = nil
			}
		}
		didSet {
			for item in items {
				item.group = self
			}
		}
	}

	open var chosenItems: [OptionItem] {
		get {
			return items.filter({ item in
				return item.state
			})
		}

		set {
			for item in items {
				item.state = newValue.contains(item)
			}
		}
	}

	open var chosenValues: [Any] {
		get {
			return chosenItems.filter({ item in
				return item.state && (item.value != nil)
			}).map({ item in
				return item.value!
			})
		}

		set {

			chosenItems = items.filter({ item in
				if let value = item.value {
					return (newValue as NSArray).contains(value)
				}
				return false
			})
		}
	}

	open var changeAction: ((_ group: OptionGroup, _ selectedItem: OptionItem) -> Void)?

	func update(with selectedItem: OptionItem) {
		// Toggle
		if selectedItem.kind == .toggle || selectedItem.kind == .single {
			changeAction?(self, selectedItem)
			return
		}

		// Multiple choice
		for item in items {
			if item != selectedItem, item.kind == selectedItem.kind {
				item.state = false
			}
		}

		changeAction?(self, selectedItem)
	}
}
