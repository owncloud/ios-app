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

open class CollectionViewCellStyle: NSObject {
	public enum StyleType {
		case header
		case footer
		case tableCell
		case tableLine
		case gridCell
		case gridCellLowDetail
		case gridCellNoDetail
		case fillSpace
		case sideBar

		var isGrid: Bool {
			return (self == .gridCell) || (self == .gridCellLowDetail) || (self == .gridCellNoDetail)
		}
	}

	public struct StyleOptionKey : Hashable {
		var rawValue: String
	}

	public var type: StyleType
	public var options: [StyleOptionKey : Any] = [:]

	public init(with type: StyleType) {
		self.type = type
		super.init()
	}

	public typealias Modifier = (CollectionViewCellStyle) -> Void

	public convenience init(from style: CollectionViewCellStyle, changing: Modifier) {
		self.init(with: style.type)

		self.options = style.options

		changing(self)
	}
}

public class CollectionViewCellConfiguration: NSObject {
	public weak var core: OCCore?
	public weak var source: OCDataSource?

	public var collectionItemRef: CollectionViewController.ItemRef?
	public var record: OCDataItemRecord?

	public weak var hostViewController: CollectionViewController?
	public weak var clientContext: ClientContext?

	public var style: CollectionViewCellStyle

	public var highlight: Bool = false

	public init(source: OCDataSource? = nil, core: OCCore? = nil, collectionItemRef: CollectionViewController.ItemRef? = nil, record: OCDataItemRecord? = nil, hostViewController: CollectionViewController?, style: CollectionViewCellStyle = .init(with: .tableCell), highlight: Bool = false, clientContext: ClientContext? = nil) {
		self.style = style
		self.highlight = highlight

		super.init()

		self.source = source
		self.core = core
		self.collectionItemRef = collectionItemRef
		self.record = record
		self.hostViewController = hostViewController
		self.clientContext = clientContext
	}

	public func configureCell(for collectionItemRef: CollectionViewController.ItemRef, with configurer: (_ itemRecord: OCDataItemRecord, _ item: OCDataItem, _ cellConfiguration: CollectionViewCellConfiguration) -> Void) {
		var itemRecord = record

		if itemRecord == nil {
			if let collectionViewController = hostViewController {
				let (itemRef, _) = collectionViewController.unwrap(collectionItemRef)

				if let retrievedItemRecord = try? source?.record(forItemRef: itemRef) {
					itemRecord = retrievedItemRecord
				}
			}
		}

		if let itemRecord = itemRecord {
			if let item = itemRecord.item {
				configurer(itemRecord, item, self)
			} else {
				// Request reconfiguration of cell
				itemRecord.retrieveItem(completionHandler: { error, itemRecord in
					if let collectionViewController = self.hostViewController {
						collectionViewController.performDataSourceUpdate { updateDone in
							collectionViewController.collectionViewDataSource.requestReconfigurationOfItems([collectionItemRef])
							updateDone()
						}
					}
				})
			}
		}
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
