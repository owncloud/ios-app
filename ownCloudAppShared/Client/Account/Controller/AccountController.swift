//
//  AccountController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 10.11.22.
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
import ownCloudApp

public protocol AccountControllerSpecialItems: AccountController {
	func updateSpecialItems(dataSource: OCDataSourceArray)
}

public extension OCDataItemType {
	static let accountController = OCDataItemType(rawValue: "accountController")
}

public class AccountController: NSObject, OCDataItem, OCDataItemVersioning, AccountConnectionStatusObserver, AccountConnectionMessageUpdates {
	public struct Configuration {
		var showSavedSearches: Bool
		var showActivity: Bool

		public static var defaultConfiguration: Configuration {
			return Configuration()
		}

		public init() {
			showSavedSearches = true
			showActivity = true
		}
	}

	public enum SpecialItem: String {
		case accountRoot
		case spacesFolder
		case savedSearchesFolder
		case quickAccessFolder
		case activity
	}

	open var clientContext: ClientContext
	open var configuration: Configuration

	weak var accountControllerSection: AccountControllerSection?

	public init(bookmark: OCBookmark, context: ClientContext, configuration: Configuration) {
		let accountConnection = AccountConnectionPool.shared.connection(for: bookmark)

		self.clientContext = ClientContext(with: context, modifier: { context in
			context.accountConnection = accountConnection
			context.progressSummarizer = accountConnection?.progressSummarizer
			context.actionProgressHandlerProvider = accountConnection
			context.inlineMessageCenter = accountConnection
		})

		self.configuration = configuration

		itemsDataSource = OCDataSourceComposition(sources: [])

		consumer = AccountConnectionConsumer()

		super.init()

		consumer.owner = self
		consumer.statusObserver = self
		consumer.messageUpdateHandler = self

		connection = accountConnection
		connection?.add(consumer: consumer)
	}

	deinit {
		connection?.remove(consumer: consumer)
	}

	// MARK: - Connection
	open weak var connection: AccountConnection?
	var consumer: AccountConnectionConsumer

	// MARK: - Connect & Disconnect
	public typealias CompletionHandler = (_ error: Error?) -> Void

	public func connect(completion: CompletionHandler?) {
		if let bookmark = connection?.bookmark,
		   !OCBookmarkManager.isLocked(bookmark: bookmark, presentAlertOn: clientContext.rootViewController) {
			connection?.connect(consumer: consumer, completion: completion)
		}
	}

	public func disconnect(completion: CompletionHandler?) {
		connection?.disconnect(consumer: consumer, completion: completion)
	}

	// MARK: - Status handling
	public func account(connection: AccountConnection, changedStatusTo status: AccountConnection.Status, initial: Bool) {
		if let vault = connection.core?.vault {
			// Create savedSearchesDataSource if wanted
			if configuration.showSavedSearches, savedSearchesDataSource == nil {
				savedSearchesDataSource = OCDataSourceKVO(object: vault, keyPath: "savedSearches", versionedItemUpdateHandler: nil)
			}
		} else {
			savedSearchesDataSource = nil
		}

		if status == .coreAvailable || status == .online {
			// Begin to show account items
			showAccountItems = true
			showDisconnectButton = true
		} else {
			// Do not show account items
			showAccountItems = false
			showDisconnectButton = false
		}

		if status == .noCore, !initial {
			// Send connection closed navigation event
			NavigationRevocationEvent.connectionClosed(bookmarkUUID: connection.bookmark.uuid).send()
		}
	}

	// MARK: - Account items
	var showAccountItems: Bool = false {
		didSet {
			if showAccountItems != oldValue {
				if showAccountItems {
					composeItemsDataSource()
				} else {
					itemsDataSource.sources = []
				}
			}
		}
	}

	@objc dynamic var showDisconnectButton: Bool = false

	var savedSearchesDataSource: OCDataSourceKVO?

	open var specialItems: [SpecialItem : OCDataItem] = [:]
	open var specialItemsDataSource: OCDataSourceArray = OCDataSourceArray(items: [])

	func composeItemsDataSource() {
		if let core = connection?.core {
			var sources : [OCDataSource] = []

			if core.useDrives {
				let (spacesDataSource, spacesFolderItem) = self.buildFolder(with: core.projectDrivesDataSource, title: "Spaces".localized, icon: OCSymbol.icon(forSymbolName: "square.grid.2x2"))

				specialItems[.savedSearchesFolder] = spacesFolderItem

				if let accountControllerSection = accountControllerSection,
				   let expandedItemRefs = accountControllerSection.collectionViewController?.wrap(references: [ spacesFolderItem.dataItemReference ], forSection: accountControllerSection.identifier) {
					accountControllerSection.expandedItemRefs = expandedItemRefs
				}

				sources = [
					core.hierarchicDrivesDataSource,
					spacesDataSource
				]
			} else {
				let accountRootLocation = OCLocation.legacyRoot

				specialItems[.accountRoot] = accountRootLocation

				sources = [
					OCDataSourceArray(items: [accountRootLocation])
				]
			}

			if configuration.showSavedSearches, let savedSearchesDataSource = savedSearchesDataSource {
				let (savedSearchesFolderDataSource, savedSearchesFolderItem) = self.buildFolder(with: savedSearchesDataSource, title: "Search views".localized, icon: OCSymbol.icon(forSymbolName: "magnifyingglass"))

				specialItems[.savedSearchesFolder] = savedSearchesFolderItem

				sources.append(savedSearchesFolderDataSource)
			}

			if let specialItemsSupport = self as? AccountControllerSpecialItems {
				specialItemsSupport.updateSpecialItems(dataSource: specialItemsDataSource)

				sources.append(specialItemsDataSource)
			}

			itemsDataSource.sources = sources
		}
	}

	func buildFolder(with contentsDataSource: OCDataSource, title: String, icon: UIImage?) -> (OCDataSource, OCDataItemPresentable) {
		let folderItem = OCDataItemPresentable(reference: "_folder_\(UUID().uuidString)" as NSString, originalDataItemType: .presentable, version: "1" as NSString)
		folderItem.title = title
		folderItem.image = icon

		folderItem.hasChildrenProvider = { (dataSource, item) in
			return true
		}

		folderItem.childrenDataSourceProvider = { (parentItemDataSource, parentItem) in
			return contentsDataSource
		}

		let titleSource = OCDataSourceArray()
		titleSource.setVersionedItems([ folderItem ])

		return (titleSource, folderItem)
	}

	// MARK: - Data sources
	open var itemsDataSource: OCDataSourceComposition
	private weak var _accountSectionDataSource: OCDataSourceComposition?
	open var accountSectionDataSource: OCDataSource? {
		if let dataSource = _accountSectionDataSource {
			return dataSource
		}

		let dataSource = OCDataSourceComposition(sources: [
			OCDataSourceArray(items: [self]),
			itemsDataSource
		])

		_accountSectionDataSource = dataSource

		return dataSource
	}

	// MARK: - OCDataItem & OCDataItemVersioning
	open var dataItemType: OCDataItemType = .accountController
	open var dataItemReference: OCDataItemReference = NSString(string: NSUUID().uuidString)
	open var dataItemVersion: OCDataItemVersion {
		let bookmark = self.connection?.bookmark
		return "\(bookmark?.shortName ?? "")-#_#-\(bookmark?.displayName ?? "")" as NSObject
	}
}

extension AccountController: DataItemSelectionInteraction {
	public func allowSelection(in viewController: UIViewController?, with context: ClientContext?) -> Bool {
		self.connect(completion: { error in
			Log.debug("Connected with \(error.debugDescription)")
		})
		return false
	}
}
