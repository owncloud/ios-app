//
//  BrowserNavigationBookmark.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 26.01.23.
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
import ownCloudSDK
import ownCloudApp

open class BrowserNavigationBookmark: NSObject, NSSecureCoding {
	public typealias BookmarkType = String
	public typealias BookmarkRestoreAction = String

	open var type: BookmarkType

	open var bookmarkUUID: UUID?
	open var location: OCLocation?

	open var itemLocalID: String?

	open var specialItem: AccountController.SpecialItem?
	open var savedSearch: OCSavedSearch?
	open var sidebarItem: OCSidebarItem?

	open var restoreFromClass: String?
	open var restoreAction: BookmarkRestoreAction?

	public init(type: BookmarkType, bookmarkUUID: UUID? = nil, location: OCLocation? = nil, itemLocalID: String? = nil, specialItem: AccountController.SpecialItem? = nil, savedSearchUUID: String? = nil, savedSearch: OCSavedSearch? = nil, sidebarItem: OCSidebarItem? = nil, restoreFromClass: String? = nil, action: BookmarkRestoreAction? = nil) {
		self.type = type

		self.bookmarkUUID = bookmarkUUID
		if bookmarkUUID == nil, let locationBookmarkUUID = location?.bookmarkUUID {
			self.bookmarkUUID = locationBookmarkUUID
		}

		self.location = location

		self.itemLocalID = itemLocalID

		self.specialItem = specialItem

		self.savedSearch = savedSearch
		self.sidebarItem = sidebarItem

		self.restoreFromClass = restoreFromClass
		self.restoreAction = action
	}

	static public func from(dataItem: OCDataItem, bookmarkUUID: UUID? = nil, bookmark: OCBookmark? = nil, clientContext: ClientContext? = nil, restoreAction: BookmarkRestoreAction) -> BrowserNavigationBookmark? {
		guard let useBookmarkUUID = bookmarkUUID ?? bookmark?.uuid ?? (dataItem as? OCLocation)?.bookmarkUUID ?? clientContext?.core?.bookmark.uuid else {
			return nil
		}

		if let itemReStore = dataItem as? DataItemBrowserNavigationBookmarkReStore {
			return itemReStore.store(in: useBookmarkUUID, context: clientContext, restoreAction: restoreAction)
		}

		return nil
	}

	convenience public init?(type: BookmarkType = .dataItem, for dataItem: OCDataItem, in bookmarkUUID: UUID? = nil, restoreAction: BookmarkRestoreAction) {
		let className = NSStringFromClass(Swift.type(of: dataItem))

		self.init(type: type, bookmarkUUID: bookmarkUUID, restoreFromClass: className, action: restoreAction)
	}

	// MARK: - Restoration
	public var isRestorable: Bool {
		if specialItem != nil {
			return true
		}

		if let restoreFromClass, let restoreClass = NSClassFromString(restoreFromClass),
		   (restoreClass as? DataItemBrowserNavigationBookmarkReStore.Type) != nil {
			return true
		}

		return false
	}

	public func restore(in viewController: UIViewController? = nil, with context: ClientContext? = nil, completion: @escaping ((Error?, UIViewController?) -> Void)) {
		if let restoreFromClass, let restoreClass = NSClassFromString(restoreFromClass),
		   let reStore = restoreClass as? DataItemBrowserNavigationBookmarkReStore.Type {
			reStore.restore(navigationBookmark: self, in: viewController, with: context, completion: completion)
		} else {
			if let restorer = context?.rootViewController as? BrowserNavigationBookmarkRestore {
				restorer.restore(navigationBookmark: self, in: viewController, with: context, completion: completion)
			} else {
				completion(NSError(ocError: .invalidType), nil)
			}
		}
	}

	// MARK: - Secure Coding
	public static var supportsSecureCoding: Bool = true

	public func encode(with coder: NSCoder) {
		coder.encode(type, forKey: "type")
		coder.encode(bookmarkUUID, forKey: "bookmarkUUID")

		coder.encode(location, forKey: "location")

		coder.encode(itemLocalID, forKey: "itemLocalID")

		coder.encode(specialItem?.rawValue, forKey: "specialItem")
		coder.encode(savedSearch, forKey: "savedSearch")
		coder.encode(sidebarItem, forKey: "sidebarItem")

		coder.encode(restoreFromClass, forKey: "restoreFromClass")
		coder.encode(restoreAction, forKey: "restoreAction")
	}

	public required init?(coder: NSCoder) {
		type = (coder.decodeObject(of: NSString.self, forKey: "type") as? String) ?? .dataItem
		bookmarkUUID = coder.decodeObject(of: NSUUID.self, forKey: "bookmarkUUID") as? UUID

		location = coder.decodeObject(of: OCLocation.self, forKey: "location")

		itemLocalID = coder.decodeObject(of: NSString.self, forKey: "itemLocalID") as? String

		if let specialItemString = coder.decodeObject(of: NSString.self, forKey: "specialItem") as? String {
			specialItem = AccountController.SpecialItem(rawValue: specialItemString)
		}
		savedSearch = coder.decodeObject(of: OCSavedSearch.self, forKey: "savedSearch")
		sidebarItem = coder.decodeObject(of: OCSidebarItem.self, forKey: "sidebarItem")

		restoreFromClass = coder.decodeObject(of: NSString.self, forKey: "restoreFromClass") as? String
		restoreAction = coder.decodeObject(of: NSString.self, forKey: "restoreAction") as? String
	}
}

public extension BrowserNavigationBookmark.BookmarkType {
	static let dataItem = "dataItem"
	static let specialItem = "specialItem"
}

public extension BrowserNavigationBookmark.BookmarkRestoreAction {
	static let standard = "standard"

	static let open = "open"
	static let reveal = "reveal"
	static let handleSelection = "handleSelection"
}

public protocol BrowserNavigationBookmarkRestore {
	func restore(navigationBookmark: BrowserNavigationBookmark, in viewController: UIViewController?, with context:ClientContext?, completion: @escaping ((_ error: Error?, _ viewController: UIViewController?) -> Void))
}
