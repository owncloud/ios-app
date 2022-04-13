//
//  CollectionViewCellConfiguration.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 08.04.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

public class CollectionViewCellConfiguration: NSObject {
	public weak var source: OCDataSource?

	public var collectionItemRef: CollectionViewController.ItemRef?
	public var record: OCDataItemRecord?

	public weak var hostViewController: CollectionViewController?

	public init(source: OCDataSource? = nil, collectionItemRef: CollectionViewController.ItemRef? = nil, record: OCDataItemRecord? = nil, hostViewController: CollectionViewController?) {
		super.init()

		self.source = source
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
