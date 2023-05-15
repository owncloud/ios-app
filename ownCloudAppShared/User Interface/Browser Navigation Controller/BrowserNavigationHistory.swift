//
//  BrowserNavigationHistory.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 23.01.23.
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

public protocol BrowserNavigationHistoryDelegate: AnyObject {
	func present(item: BrowserNavigationItem?, with direction: BrowserNavigationHistory.Direction, completion: BrowserNavigationHistory.CompletionHandler?)
}

open class BrowserNavigationHistory {
	public typealias CompletionHandler = (_ success: Bool) -> Void

	public enum Direction {
		case none
		case toPrevious
		case toNext
	}

	weak var delegate: BrowserNavigationHistoryDelegate?

	open var items: [BrowserNavigationItem] = []
	open var currentItem: BrowserNavigationItem? {
		if items.count > 0, position < items.count, position >= 0 {
			return items[position]
		}

		return nil
	}
	open var position: Int = -1

	open var canMoveBack: Bool {
		return position > 0
	}

	open var canMoveForward: Bool {
		return position < items.count-1
	}

	open var isEmpty: Bool {
		return items.isEmpty
	}

	open func push(item: BrowserNavigationItem, completion: CompletionHandler? = nil) {
		OCSynchronized(self) {
			if position < items.count - 1 {
				items.removeSubrange((position+1)...items.count-1)
			}

			items.append(item)
			position += 1
		}

		present(item: item, with: (position == 0) ? .none : .toNext, completion: completion)
	}

	@discardableResult open func moveBack(completion: CompletionHandler? = nil) -> BrowserNavigationItem? {
		var presentItem: BrowserNavigationItem?

		OCSynchronized(self) {
			if position > 0 {
				position -= 1
				presentItem = items[position]
			}
		}

		if let presentItem {
			present(item: presentItem, with: .toPrevious, completion: completion)
		} else {
			completion?(false)
		}

		return presentItem
	}

	@discardableResult open func moveForward(completion: CompletionHandler? = nil) -> BrowserNavigationItem? {
		var presentItem: BrowserNavigationItem?

		OCSynchronized(self) {
			if position < items.count - 1 {
				position += 1
				presentItem = items[position]
			}
		}

		if let presentItem {
			present(item: presentItem, with: .toNext, completion: completion)
		} else {
			completion?(false)
		}

		return presentItem
	}

	open func item(for viewController: UIViewController?) -> BrowserNavigationItem? {
		var foundItem: BrowserNavigationItem?

		OCSynchronized(self) {
			for item in items {
				if item.viewControllerIfLoaded == viewController {
					foundItem = item
					break
				}
			}
		}

		return foundItem
	}

	@discardableResult open func remove(item: BrowserNavigationItem, completion: BrowserNavigationHistory.CompletionHandler?) -> Bool {
		var didRemove = false

		OCSynchronized(self) {
			if let index = items.firstIndex(of: item) {
				var presentNewItem = (index == position)
				var direction: Direction = .none

				if index == position {
					direction = .toPrevious
				}

				if index <= position {
					position -= 1
				}

				items.remove(at: index)

				if position < 0 {
					if items.count > 0 {
						position = 0
					} else {
						position = -1
						presentNewItem = true
					}
				}

				if presentNewItem {
					present(item: currentItem, with: direction, completion: completion)
				} else {
					completion?(true)
				}

				didRemove = true
			}
		}

		if didRemove {
			return true
		}

		completion?(false)
		return false
	}

	private var lastPresentItem: BrowserNavigationItem?
	private var lastDirection: BrowserNavigationHistory.Direction = .none

	func present(item: BrowserNavigationItem?, with direction: BrowserNavigationHistory.Direction, completion: BrowserNavigationHistory.CompletionHandler?) {
		OCSynchronized(self) {
			lastPresentItem = item
			lastDirection = direction
		}

		OnMainThread {
			var performPresentation: Bool = true

			OCSynchronized(self) {
				performPresentation = (self.lastPresentItem == item) && (self.lastDirection == direction)
			}

			guard performPresentation, let delegate = self.delegate else {
				completion?(true)
				return
			}

			delegate.present(item: item, with: direction, completion: completion)
		}
	}
}
