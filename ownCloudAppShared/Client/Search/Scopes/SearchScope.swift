//
//  SearchScope.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 22.06.22.
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

open class SearchScope: NSObject, SearchElementUpdating {
	public var localizedName : String
	public var localizedPlaceholder: String?
	public var icon : UIImage?

	@objc public dynamic var results: OCDataSource?
	@objc public dynamic var resultsCellStyle: CollectionViewCellStyle?

	public var isSelected: Bool = false

	public weak var searchViewController: SearchViewController?
	public var clientContext: ClientContext

	public var tokenizer: SearchTokenizer? // a search tokenizer must be set by subclasses in init()
	public var scopeViewController: (UIViewController & SearchElementUpdating)?

	static public func modifyingQuery(with context: ClientContext, localizedName: String) -> SearchScope {
		return SingleFolderSearchScope(with: context, cellStyle: nil, localizedName: localizedName, localizedPlaceholder: "Search folder".localized, icon: UIImage(systemName: "folder"))
	}

	static public func driveSearch(with context: ClientContext, cellStyle: CollectionViewCellStyle, localizedName: String) -> SearchScope {
		var placeholder = "Search space".localized
		if let driveName = context.drive?.name, driveName.count > 0 {
			placeholder = "Search {{space.name}}".localized(["space.name" : driveName])
		}
		return DriveSearchScope(with: context, cellStyle: cellStyle, localizedName: localizedName, localizedPlaceholder: placeholder, icon: UIImage(systemName: "square.grid.2x2"))
	}

	static public func containerSearch(with context: ClientContext, cellStyle: CollectionViewCellStyle, localizedName: String) -> SearchScope {
		var placeholder = "Search tree".localized
		if let path = context.query?.queryLocation?.lastPathComponent, path.count > 0 {
			placeholder = "Search from {{folder.name}}".localized(["folder.name" : path])
		}
		return ContainerSearchScope(with: context, cellStyle: cellStyle, localizedName: localizedName, localizedPlaceholder: placeholder, icon: UIImage(systemName: "square.stack.3d.up"))
	}

	static public func accountSearch(with context: ClientContext, cellStyle: CollectionViewCellStyle, localizedName: String) -> SearchScope {
		return AccountSearchScope(with: context, cellStyle: cellStyle, localizedName: localizedName, localizedPlaceholder: "Search account".localized, icon: UIImage(systemName: "person"))
	}

	public init(with context: ClientContext, cellStyle: CollectionViewCellStyle?, localizedName name: String, localizedPlaceholder placeholder: String? = nil, icon: UIImage? = nil) {
		clientContext = context
		localizedName = name

		super.init()

		resultsCellStyle = cellStyle
		self.localizedPlaceholder = placeholder
		self.icon = icon
	}

	open func updateFor(_ searchElements: [SearchElement]) {
	}

	// Save and restore searches
	open var canSaveSearch: Bool {
		// subclasses should return true if the scope can save the current search
		return false
	}

	open var savedSearch: AnyObject? {
		// subclasses should return an serializable object that can be used to restore the search if the scope can save the current search
		return nil
	}

	open var canSaveTemplate: Bool {
		// subclasses should return true if the scope can save the current search as template
		return false
	}

	open var savedTemplate: AnyObject? {
		// subclasses should return an serializable object that can be used to restore the search if the scope can save the current search as template
		return nil
	}

	open func canRestore(savedTemplate: AnyObject) -> Bool {
		// subclasses should return true if they can restore a saved template from the provided savedSearch object
		return false
	}

	open func restore(savedTemplate: AnyObject) -> [SearchElement]? {
		// subclasses should convert the saved template into search elements that can be used to popuplate f.ex. UISearchTextField
		return nil
	}
}
