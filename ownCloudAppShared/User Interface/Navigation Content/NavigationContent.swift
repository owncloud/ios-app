//
//  NavigationContent.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 24.01.23.
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

open class NavigationContent: NSObject {
	public static let existingContentIdentifier: String = "existing-content"

	weak var navigationItem: UINavigationItem?

	// Area to fill with content
	public enum Area {
		case left	// Left bar buttons
		case right	// Right bar buttons
		case title	// Title
	}

	// Position within area
	public enum Position: Int {
		case leading = 0
		case middle = 10
		case trailing = 20
	}

	// Priority of content - content is only shown from the respective highest priority
	public enum Priority: Int {
		case lowest = 0
		case low
		case standard
		case high
		case highest
	}

	public typealias Snapshot = [NavigationContentItem]

	public var initialExistingItemsSnapshot: Snapshot

	var items: [NavigationContentItem] = []

	init(for navigationItem: UINavigationItem, existingWithPriority priority: Priority = .standard, position: Position = .trailing) {
		initialExistingItemsSnapshot = navigationItem.takeNavigationContentSnapshot(withIdentifier: NavigationContent.existingContentIdentifier, priority: priority, position: position)

		super.init()
		self.navigationItem = navigationItem

		items.append(contentsOf: initialExistingItemsSnapshot)
	}

	public func add(items content: [NavigationContentItem]) {
		// Remove existing items for ALL identifiers used in content
		items.removeAll(where: { item in
			return content.contains(where: { contentItem in
				return contentItem.identifier == item.identifier
			})
		})

		// Add content
		items.append(contentsOf: content)

		setNeedsRecomputation()
	}

	public func remove(items content: [NavigationContentItem]) {
		// Remove content
		items.removeAll(where: { item in
			content.contains(item)
		})

		setNeedsRecomputation()
	}

	public func remove(itemsWithIdentifier identifier: String) {
		// Remove all items with identifier
		items.removeAll(where: { item in
			return item.identifier == identifier
		})

		setNeedsRecomputation()
	}

	public func remove(itemsWithIdentifiers identifiers: [String]) {
		// Remove all items with identifiers
		items.removeAll(where: { item in
			return identifiers.contains(item.identifier)
		})

		setNeedsRecomputation()
	}

	public func items(withIdentifier identifier: String) -> ([NavigationContentItem], [UIBarButtonItem]) {
		let contentItems = items.filter({ item in
			return (item.identifier == identifier)
		})

		var barButtonItems: [UIBarButtonItem] = []
		for contentItem in contentItems {
			if let content = contentItem.items {
				barButtonItems.append(contentsOf: content)
			}
		}

		return (contentItems, barButtonItems)
	}

	private var _needsRecomputation: Bool = false
	func setNeedsRecomputation(applyImmediately: Bool = true) {
		if !applyImmediately {
			_needsRecomputation = true

			OnMainThread {
				if self._needsRecomputation {
					self._needsRecomputation = false
					self.recompute()
				}
			}
		} else {
			self.recompute()
		}
	}

	func pickAndComposeItems(for area: Area) -> ([NavigationContentItem], [UIBarButtonItem]) {
		var highestPriority: Priority = .lowest
		var areaItems = items.compactMap({ item in
			if item.area == area {
				if item.priority.rawValue > highestPriority.rawValue {
					highestPriority = item.priority
				}

				return item
			}
			return nil
		})
		areaItems = areaItems.compactMap({ item in
			return item.visibleInPriorities.contains(highestPriority) ? item : nil
		})
		areaItems.sort(by: { item1, item2 in
			return item1.position.rawValue < item2.position.rawValue
		})

		var barButtonItems: [UIBarButtonItem] = []

		for item in areaItems {
			if let items = item.items {
				barButtonItems.append(contentsOf: items)
			}
		}

		return (areaItems, barButtonItems)
	}

	func recompute() {
		let (_, leftBarButtonItems) = pickAndComposeItems(for: .left)
		navigationItem?.leftBarButtonItems = leftBarButtonItems

		let (_, rightBarButtonItems) = pickAndComposeItems(for: .right)
		navigationItem?.rightBarButtonItems = rightBarButtonItems

		let (titleItems, _) = pickAndComposeItems(for: .title)
		if let titleItem = titleItems.first {
			if let title = titleItem.title {
				navigationItem?.titleLabelText = title
			}
			if let titleView = titleItem.titleView {
				navigationItem?.titleView = titleView
			}
		}
	}
}
