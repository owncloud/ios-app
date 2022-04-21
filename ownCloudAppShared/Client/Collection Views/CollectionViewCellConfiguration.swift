//
//  CollectionViewCellConfiguration.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 08.04.22.
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

public enum CollectionViewCellStyle {
	case regular
	case header
	case footer
	case item(actionHandlers: ItemCellActionHandlers)
}

public class CollectionViewCellConfiguration: NSObject {
	public weak var core: OCCore?
	public weak var source: OCDataSource?

	public var collectionItemRef: CollectionViewController.ItemRef?
	public var record: OCDataItemRecord?

	public weak var hostViewController: CollectionViewController?

	public var style : CollectionViewCellStyle

	public init(source: OCDataSource? = nil, core: OCCore? = nil, collectionItemRef: CollectionViewController.ItemRef? = nil, record: OCDataItemRecord? = nil, hostViewController: CollectionViewController?, style: CollectionViewCellStyle = .regular) {
		self.style = style

		super.init()

		self.source = source
		self.core = core
		self.collectionItemRef = collectionItemRef
		self.record = record
		self.hostViewController = hostViewController
	}
}

public extension NSObject {
	private struct AssociatedKeys {
		static var cellConfiguration = "cellConfiguration"
	}

	var ocCellConfiguration : CollectionViewCellConfiguration? {
		set {
			objc_setAssociatedObject(self, &AssociatedKeys.cellConfiguration, newValue, .OBJC_ASSOCIATION_RETAIN)
		}

		get {
			return objc_getAssociatedObject(self, &AssociatedKeys.cellConfiguration) as? CollectionViewCellConfiguration
		}
	}
}
