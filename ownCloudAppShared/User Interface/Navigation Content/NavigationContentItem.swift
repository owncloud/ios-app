//
//  NavigationContentItem.swift
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

public class NavigationContentItem: NSObject {
	public var identifier: String

	public var area: NavigationContent.Area
	public var priority: NavigationContent.Priority
	public var visibleInPriorities: [NavigationContent.Priority]
	public var position: NavigationContent.Position

	public var items: [UIBarButtonItem]? {
		didSet {

		}
	}

	public var titleView: UIView?
	public var title: String?

	public init(identifier: String, area: NavigationContent.Area, priority: NavigationContent.Priority, position: NavigationContent.Position, items: [UIBarButtonItem]? = nil, titleView: UIView? = nil, title: String? = nil) {
		self.identifier = identifier
		self.area = area
		self.priority = priority
		self.visibleInPriorities = [ priority ]
		self.position = position

		super.init()

		self.titleView = titleView
		self.title = title
		self.items = items
	}
}
