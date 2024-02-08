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

public protocol AccountControllerExtraItems: AccountController {
	func updateExtraItems(dataSource: OCDataSourceArray)
	func provideExtraItemViewController(for specialItem: SpecialItem, in context: ClientContext) -> UIViewController?
}

public extension OCDataItemType {
	static let accountController = OCDataItemType(rawValue: "accountController")
}

public class AccountController: NSObject, OCDataItem, OCDataItemVersioning, AccountConnectionStatusObserver, AccountConnectionMessageUpdates {
	public struct Configuration {
		public var showAccountPill: Bool
		public var showShared: Bool
		public var showSearch: Bool
		public var showRecents: Bool
		public var showFavorites: Bool
		public var showAvailableOffline: Bool
		public var showActivity: Bool
		public var autoSelectPersonalFolder: Bool

		public var sectionAppearance: UICollectionLayoutListConfiguration.Appearance = .sidebar

		public static var defaultConfiguration: Configuration {
			return Configuration()
		}

		public static var pickerConfiguration: Configuration {
			var config = Configuration()

			config.showSearch = false
			config.showActivity = false
			config.showAvailableOffline = false

			config.sectionAppearance = .insetGrouped

			config.autoSelectPersonalFolder = false

			return config
		}

		public init() {
			showAccountPill = true
			showShared = true
			showSearch = true
			showFavorites = true
			showRecents = true
			showAvailableOffline = true
			showActivity = true

			autoSelectPersonalFolder = true
		}
	}

	public enum SpecialItem: String, CaseIterable {
		case sharingFolder
			case sharedWithMe
			case sharedByMe
			case sharedByLink

		case spacesFolder

		case globalSearch

		case recents
		case favoriteItems
		case availableOfflineItems

		case activity
	}

	open var clientContext: ClientContext
	open var configuration: Configuration

	open var connectionErrorHandler: AccountConnectionCoreErrorHandler?

	weak var accountControllerSection: AccountControllerSection?

	open var bookmark: OCBookmark? { // Convenience accessor
		return connection?.bookmark
	}

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
		controllerDataSource = OCDataSourceArray(items: [])

		consumer = AccountConnectionConsumer()

		let bookmarkUUID = bookmark.uuid

		for specialItem in SpecialItem.allCases {
			if let representationSideBarItemRef = BrowserNavigationBookmark(type: .specialItem, bookmarkUUID: bookmarkUUID, specialItem: specialItem).representationSideBarItemRef {
				specialItemsDataReferences[specialItem] = representationSideBarItemRef
			}
		}

		legacyAccountRootLocation = OCLocation.legacyRoot
		legacyAccountRootLocation.bookmarkUUID = bookmark.uuid

		super.init()

		controllerDataSource.setVersionedItems([ self ])

		consumer.owner = self
		consumer.statusObserver = self
		consumer.messageUpdateHandler = self

		connection = accountConnection
		connection?.add(consumer: consumer)

		addErrorHandler()
	}

	func destroy() {
		// Break retain cycles
		controllerDataSource.setVersionedItems([])
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
		   	// Add controller's error handler
			addErrorHandler()

			connection?.connect(consumer: consumer, completion: completion)
		} else {
			completion?(NSError.init(ocError: .internal))
		}
	}

	public func disconnect(completion: CompletionHandler?) {
		connection?.disconnect(consumer: consumer, completion: completion)
	}

	func addErrorHandler() {
		if connectionErrorHandler == nil {
			self.connectionErrorHandler = AccountConnectionErrorHandler(for: clientContext)
		}
	}

	func removeErrorHandler() {
		connectionErrorHandler = nil
	}

	// MARK: - Status handling
	public func account(connection: AccountConnection, changedStatusTo status: AccountConnection.Status, initial: Bool) {
		if let vault = connection.core?.vault {
			// Create savedSearchesDataSource if wanted
			if configuration.showSearch, savedSearchesDataSource == nil {
				savedSearchesDataSource = OCDataSourceKVO(object: vault, keyPath: "savedSearches", versionedItemUpdateHandler: { obj, keypath, newValue in
					if let savedSearches = newValue as? [OCSavedSearch] {
						return savedSearches.filter { savedSearch in return !savedSearch.isTemplate }
					}

					return nil
				})
			}
		} else {
			savedSearchesDataSource = nil
		}

		switch status {
			case .authenticationError(failure: let failure):
				// Authentication failure
				authFailure = failure

			case .coreAvailable, .online:
				// Begin to show account items
				showAccountItems = true
				showDisconnectButton = true
				authFailure = nil

			default:
				// Do not show account items
				showAccountItems = false
				showDisconnectButton = false
				authFailure = nil
		}

		if case .noCore = status, !initial {
			// Remove controller's error handler
			removeErrorHandler()

			// Send connection closed navigation event
			NavigationRevocationEvent.connectionClosed(bookmarkUUID: connection.bookmark.uuid).send()
		}
	}

	// MARK: - Authentication failures
	var authFailure: AccountConnection.AuthFailure? {
		didSet {
			if let authFailure = authFailure {
				let authFailureResolveAction = OCAction(title: authFailure.title, icon: OCSymbol.icon(forSymbolName: "person.crop.circle.badge.exclamationmark"), action: { [weak self] _, _, completion in
					if let self = self {
						self.authFailure?.resolve(context: self.clientContext)
					}
					completion(nil)
				})

				authFailureResolveAction.selectable = false
				authFailureResolveAction.buttonLabel = "More".localized
				authFailureResolveAction.type = .warning

				controllerDataSource.setVersionedItems([
					self,
					authFailureResolveAction
				])
			} else {
				if authFailure == nil, oldValue == nil {
					return
				}

				controllerDataSource.setVersionedItems([
					self
				])
			}
		}
	}

	// MARK: - Account items
	var showAccountItems: Bool = false {
		didSet {
			if showAccountItems != oldValue {
				if showAccountItems {
					composeItemsDataSource()
				} else {
					authFailure = nil
					itemsDataSource.sources = []
				}
			}
		}
	}

	@objc dynamic var showDisconnectButton: Bool = false

	var savedSearchesDataSource: OCDataSourceKVO?
	var savedSearchesCondition: DataSourceCondition?

	open var specialItems: [SpecialItem : OCDataItem & OCDataItemVersioning] = [:]
	open var specialItemsDataReferences: [SpecialItem : OCDataItemReference] = [:]
	open var specialItemsDataSources: [SpecialItem : OCDataSource] = [:]

	open var sharingItemsDataSource: OCDataSourceArray = OCDataSourceArray(items: [])

	open var quickAccessItemsDataSource: OCDataSourceArray = OCDataSourceArray(items: [])

	open var extraItemsDataSource: OCDataSourceArray = OCDataSourceArray(items: [])

	open var personalSpaceDataItemRef: OCDataItemReference? {
		var personalSpaceItemRef: OCDataItemReference?

		if connection?.core?.useDrives == true {
			personalSpaceItemRef = connection?.core?.drives.first(where: { drive in
				return drive.specialType == .personal
			})?.dataItemReference
		} else {
			personalSpaceItemRef = legacyAccountRootLocation.dataItemReference
		}

		return personalSpaceItemRef
	}

	open var sharesFolderDataItemRef: OCDataItemReference? {
		return connection?.core?.drives.first(where: { drive in
			return drive.specialType == .shares
		})?.dataItemReference
	}

	private var legacyAccountRootLocation: OCLocation

	private let useFolderForSearches: Bool = false

	func composeItemsDataSource() {
		if let core = connection?.core {
			var sources : [OCDataSource] = []

			// Personal Folder, Shared Files + Drives
			if core.useDrives {
				// Spaces
				let spacesDataSource = self.buildTopFolder(with: core.projectDrivesDataSource, title: "Spaces".localized, icon: OCSymbol.icon(forSymbolName: "square.grid.2x2"), topItem: .spacesFolder, viewControllerProvider: { [weak self] context, action in
					return self?.provideViewController(for: .spacesFolder, in: context)
				})

				if let accountControllerSection = accountControllerSection,
				   let expandedItemRefs = accountControllerSection.collectionViewController?.wrap(references: [ /* specialItemsDataReferences[.spacesFolder]! */ ], forSection: accountControllerSection.identifier) {
					accountControllerSection.expandedItemRefs = expandedItemRefs
				}

				sources = [
					core.personalDriveDataSource,
					spacesDataSource
				]
			} else {
				// OC10 Root folder
				sources = [
					OCDataSourceArray(items: [legacyAccountRootLocation])
				]
			}

			// Sharing
			if configuration.showShared {
				let (sharingFolderDataSource, sharingFolderItem) = self.buildFolder(with: sharingItemsDataSource, title: "Shares".localized, icon: OCSymbol.icon(forSymbolName: "arrowshape.turn.up.left"), folderItemRef: specialItemsDataReferences[.sharingFolder]!)

				specialItems[.sharingFolder] = sharingFolderItem
				specialItemsDataSources[.sharingFolder] = sharingFolderDataSource

				if specialItems[.sharedWithMe] == nil {
					specialItems[.sharedWithMe] = CollectionSidebarAction(with: "Shared with me".localized, icon: OCSymbol.icon(forSymbolName: "arrowshape.turn.up.left"), identifier: specialItemsDataReferences[.sharedWithMe], viewControllerProvider: { [weak self] context, action in
						return self?.provideViewController(for: .sharedWithMe, in: context)
					}, cacheViewControllers: false)
				}

				if specialItems[.sharedByMe] == nil {
					specialItems[.sharedByMe] = CollectionSidebarAction(with: "Shared by me".localized, icon: OCSymbol.icon(forSymbolName: "arrowshape.turn.up.right"), identifier: specialItemsDataReferences[.sharedByMe], viewControllerProvider: { [weak self] context, action in
						return self?.provideViewController(for: .sharedByMe, in: context)
					}, cacheViewControllers: false)
				}

				if specialItems[.sharedByLink] == nil {
					specialItems[.sharedByLink] = CollectionSidebarAction(with: "Shared by link".localized, icon: OCSymbol.icon(forSymbolName: "link"), identifier: specialItemsDataReferences[.sharedByLink], viewControllerProvider: { [weak self] context, action in
						return self?.provideViewController(for: .sharedByLink, in: context)
					}, cacheViewControllers: false)
				}

				var sharingItems : [OCDataItem & OCDataItemVersioning] = []

				if let sharingItem = specialItems[.sharedWithMe] { sharingItems.append(sharingItem) }
				if let sharingItem = specialItems[.sharedByMe] { sharingItems.append(sharingItem) }
				if let sharingItem = specialItems[.sharedByLink] { sharingItems.append(sharingItem) }

				sharingItemsDataSource.setVersionedItems(sharingItems)

				sources.insert(sharingFolderDataSource, at: 1)
			}

			// Saved searches
			var savedSearchesSidebarDataSource: OCDataSource?

			if configuration.showSearch, let savedSearchesDataSource {
				if useFolderForSearches {
					// Use "Search" item in sidebar, showing saved searches when unfolded
					let savedSearchesFolderDataSource = self.buildTopFolder(with: savedSearchesDataSource, title: "Search".localized, icon: OCSymbol.icon(forSymbolName: "magnifyingglass"), topItem: .globalSearch) { [weak self] context, action in
						return self?.provideViewController(for: .globalSearch, in: context)
					}

					sources.append(savedSearchesFolderDataSource)
				} else {
					// Add "Search" item to sidebar, making saved searches standalone items
					let globalSearchItem = CollectionSidebarAction(with: "Search".localized, icon: OCSymbol.icon(forSymbolName: "magnifyingglass"), identifier: specialItemsDataReferences[.globalSearch], viewControllerProvider: { [weak self] context, action in
						return self?.provideViewController(for: .globalSearch, in: context)
					}, cacheViewControllers: false)

					specialItems[.globalSearch] = globalSearchItem

					sources.append(OCDataSourceArray(items: [ globalSearchItem ]))
					savedSearchesSidebarDataSource = savedSearchesDataSource // Add saved searches only after Available Offline
				}
			}

			// Other sidebar items
			var otherItems: [OCDataItem & OCDataItemVersioning] = []

			func addSidebarItem(_ itemID: SpecialItem, _ generate: ()->OCDataItem&OCDataItemVersioning) {
				var item = specialItems[itemID]

				if item == nil {
					item = generate()
					specialItems[itemID] = item
				}

				if let item {
					otherItems.append(item)
				}
			}

			// Recents
			if configuration.showRecents {
				// Recents
				addSidebarItem(.recents) {
					return OCSavedSearch(scope: .account, location: nil, name: "Recents".localized, isTemplate: false, searchTerm: ":recent :file").withCustomIcon(name: "clock.arrow.circlepath").useNameAsTitle(true).useSortDescriptor(SortDescriptor(method: .lastUsed, direction: .ascendant))
				}
			}

			// Favorites
			if configuration.showFavorites, bookmark?.hasCapability(.favorites) == true {
				addSidebarItem(.favoriteItems) {
					return buildSidebarSpecialItem(with: "Favorites".localized, icon: OCSymbol.icon(forSymbolName: "star"), for: .favoriteItems)
				}
			}

			// Available offline
			if configuration.showAvailableOffline {
				addSidebarItem(.availableOfflineItems) {
					return buildSidebarSpecialItem(with: "Available Offline".localized, icon: OCItem.cloudAvailableOfflineStatusIcon, for: .availableOfflineItems)
				}
			}

			if otherItems.count > 0 {
				let otherItemsDataSource = OCDataSourceArray()
				otherItemsDataSource.setVersionedItems(otherItems)
				sources.append(otherItemsDataSource)
			}

			// Saved searches (if not in folder)
			if let savedSearchesSidebarDataSource {
				sources.append(savedSearchesSidebarDataSource)
			}

			// Extra items (Activity & Co via class extension in the app)
			if let extraItemsSupport = self as? AccountControllerExtraItems {
				extraItemsSupport.updateExtraItems(dataSource: extraItemsDataSource)

				sources.append(extraItemsDataSource)
			}

			itemsDataSource.sources = sources
		}
	}

	func buildActionFolder(with contentsDataSource: OCDataSource, title: String, icon: UIImage?, folderItemRef: OCDataItemReference = "_folder_\(UUID().uuidString)" as NSString, viewControllerProvider: @escaping CollectionSidebarAction.ViewControllerProvider) -> (OCDataSource, CollectionSidebarAction) {
		let folderAction = CollectionSidebarAction(with: title, icon: icon, identifier: folderItemRef, viewControllerProvider: viewControllerProvider)
		folderAction.childrenDataSource = contentsDataSource

		let titleSource = OCDataSourceArray()
		titleSource.setVersionedItems([ folderAction ])

		return (titleSource, folderAction)
	}

	func buildTopFolder(with contentsDataSource: OCDataSource, title: String, icon: UIImage?, topItem: SpecialItem, viewControllerProvider: @escaping CollectionSidebarAction.ViewControllerProvider) -> OCDataSource {
		let (titleSource, folderAction) = buildActionFolder(with: contentsDataSource, title: title, icon: icon, folderItemRef: specialItemsDataReferences[topItem]!, viewControllerProvider: viewControllerProvider)

		specialItems[topItem] = folderAction
		specialItemsDataSources[topItem] = titleSource
		specialItemsDataReferences[topItem] = folderAction.dataItemReference

		return titleSource
	}

	func buildFolder(with contentsDataSource: OCDataSource, title: String, icon: UIImage?, folderItemRef: OCDataItemReference = "_folder_\(UUID().uuidString)" as NSString) -> (OCDataSource, OCDataItemPresentable) {
		let folderItem = OCDataItemPresentable(reference: folderItemRef, originalDataItemType: .presentable, version: "1" as NSString)
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

	// MARK: - View controller construction
	open func provideViewController(for specialItem: SpecialItem, in context: ClientContext?) -> UIViewController? {
		guard let context else { return nil }

		var viewController: UIViewController?

		switch specialItem {
			case .sharedWithMe:
				viewController = ClientSharedWithMeViewController(context: context)

			case .sharedByMe:
				viewController = ClientSharedByMeViewController(context: context, byMe: true)

			case .sharedByLink:
				viewController = ClientSharedByMeViewController(context: context, byLink: true)

			case .spacesFolder:
				viewController = AccountControllerSpacesGridViewController(with: context)

			case .globalSearch:
				viewController = AccountControllerSearchViewController(context: context)

			case .availableOfflineItems:
				if let core = context.core {
					let availableOfflineFilesDataSource = core.availableOfflineFilesDataSource
					let sortedDataSource = SortedItemDataSource(itemDataSource: availableOfflineFilesDataSource)

					let availableOfflineViewController = ClientItemViewController(context: context, query: nil, itemsDatasource: sortedDataSource, showRevealButtonForItems: true, emptyItemListIcon: OCItem.cloudAvailableOfflineStatusIcon, emptyItemListTitleLocalized: "No files available offline".localized, emptyItemListMessageLocalized: "Files selected and downloaded for offline availability will show up here.".localized)
					availableOfflineViewController.navigationTitle = "Available Offline".localized

					sortedDataSource.sortingFollowsContext = availableOfflineViewController.clientContext

					let availableOfflineItemPoliciesDataSource = core.availableOfflineItemPoliciesDataSource

					let locationsSection = CollectionViewSection(identifier: "locations", dataSource: availableOfflineItemPoliciesDataSource, cellStyle: .init(with: .tableCell), cellLayout: .list(appearance: .plain, contentInsets: NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 30, trailing: 0)), clientContext: context)

					locationsSection.hideIfEmptyDataSource = availableOfflineFilesDataSource
					locationsSection.boundarySupplementaryItems = [
						.title("Locations".localized, pinned: true)
					]
					locationsSection.hidden = true

					let downloadedFilesHeaderSection = CollectionViewSection(identifier: "downloadedFilesHeader", dataSource: nil, cellStyle: .init(with: .tableCell), cellLayout: .list(appearance: .plain), clientContext: context)
					downloadedFilesHeaderSection.hideIfEmptyDataSource = sortedDataSource
					downloadedFilesHeaderSection.boundarySupplementaryItems = [
						.title("Downloaded Files".localized)
					]
					downloadedFilesHeaderSection.hidden = true

					availableOfflineViewController.insert(sections: [ locationsSection, downloadedFilesHeaderSection ], at: 0)

					availableOfflineViewController.revoke(in: context, when: [ .connectionClosed ])

					viewController = availableOfflineViewController
				}

			case .favoriteItems:
				if let favoritesDataSource = context.core?.favoritesDataSource {
					let favoritesContext = ClientContext(with: context, modifier: { context in
						context.queryDatasource = favoritesDataSource
					})

					let sortedDataSource = SortedItemDataSource(itemDataSource: favoritesDataSource)

					let favoritesViewController = ClientItemViewController(context: favoritesContext, query: nil, itemsDatasource: sortedDataSource, showRevealButtonForItems: true, emptyItemListIcon: OCSymbol.icon(forSymbolName: "star.fill"), emptyItemListTitleLocalized: "No favorites found".localized, emptyItemListMessageLocalized: "If you make an item a favorite, it will turn up here.".localized)
					favoritesViewController.navigationTitle = "Favorites".localized

					sortedDataSource.sortingFollowsContext = favoritesViewController.clientContext

					favoritesViewController.revoke(in: favoritesContext, when: [ .connectionClosed ])
					viewController = favoritesViewController
				}

			default:
				if let extraItemsProvider = self as? AccountControllerExtraItems,
				   let extraViewController = extraItemsProvider.provideExtraItemViewController(for: specialItem, in: context) {
				   viewController = extraViewController
				}
		}

		if viewController?.navigationBookmark == nil {
			viewController?.navigationBookmark = BrowserNavigationBookmark(type: .specialItem, bookmarkUUID: context.accountConnection?.bookmark.uuid, specialItem: specialItem)
		}

		return viewController
	}

	// MARK: - Data sources
	open var controllerDataSource: OCDataSourceArray
	open var itemsDataSource: OCDataSourceComposition
	private weak var _accountSectionDataSource: OCDataSourceComposition?
	open var accountSectionDataSource: OCDataSource? {
		if let dataSource = _accountSectionDataSource {
			return dataSource
		}

		let dataSource = OCDataSourceComposition(sources: [
			controllerDataSource,
			itemsDataSource
		])

		if !configuration.showAccountPill {
			dataSource.setInclude(false, for: controllerDataSource)
		}

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

// MARK: - Selection handling
extension AccountController: DataItemSelectionInteraction {
	public func allowSelection(in viewController: UIViewController?, section: CollectionViewSection?, with context: ClientContext?) -> Bool {
		func revealPersonalItem() {
			if let personalSpaceDataItemRef = self.personalSpaceDataItemRef,
			   let sectionID = section?.identifier,
			   let personalFolderItemRef = section?.collectionViewController?.wrap(references: [personalSpaceDataItemRef], forSection: sectionID).first,
			   let /* spacesFolderItemRef */ _ = section?.collectionViewController?.wrap(references: [specialItemsDataReferences[.spacesFolder]!], forSection: sectionID).first {
				section?.collectionViewController?.addActions([
					CollectionViewAction(kind: .select(animated: false, scrollPosition: .centeredVertically), itemReference: personalFolderItemRef)
				])
			}
		}

		if let bookmark = bookmark {
			self.connect(completion: { error in
				if let error = error {
					Log.error("Connected with \(error)")

					let alert = ThemedAlertController(title: NSString(format: "Error opening %@".localized as NSString, bookmark.shortName) as String, message: error.localizedDescription, preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: nil))

					context?.rootViewController?.present(alert, animated: true)
				} else {
					if self.configuration.autoSelectPersonalFolder {
						revealPersonalItem()
					}
				}
			})
		}
		return false
	}
}

// MARK: - Special Side Bar Items
extension AccountController {
	func buildSidebarSpecialItem(with title: String, icon: UIImage?, for specialItem: SpecialItem) -> OCDataItem & OCDataItemVersioning {
		let item = CollectionSidebarAction(with: title, icon: icon, viewControllerProvider: { [weak self] (context, action) in
			return self?.provideViewController(for: specialItem, in: context)
		}, cacheViewControllers: false)

		item.identifier = BrowserNavigationBookmark(type: .specialItem, bookmarkUUID: connection?.bookmark.uuid, specialItem: specialItem).representationSideBarItemRef as? String

		return item
	}
}
