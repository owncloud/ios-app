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
		public var showSavedSearches: Bool
		public var showQuickAccess: Bool
		public var showActivity: Bool
		public var autoSelectPersonalFolder: Bool
		public var expandQuickAccess: Bool

		public var sectionAppearance: UICollectionLayoutListConfiguration.Appearance = .sidebar

		public static var defaultConfiguration: Configuration {
			return Configuration()
		}

		public static var pickerConfiguration: Configuration {
			var config = Configuration()

			config.showSavedSearches = true
			config.showQuickAccess = true
			config.showActivity = false
			config.expandQuickAccess = true

			config.sectionAppearance = .insetGrouped

			config.autoSelectPersonalFolder = false

			return config
		}

		public init() {
			showAccountPill = true
			showShared = true
			showSavedSearches = true
			showQuickAccess = true
			showActivity = true
			expandQuickAccess = false

			autoSelectPersonalFolder = true
		}
	}

	public enum SpecialItem: String, CaseIterable {
		case sharingFolder
			case sharedWithMe
			case sharedByMe
			case sharedByLink

		case spacesFolder

		case savedSearchesFolder

		case quickAccessFolder
			case favoriteItems
			case availableOfflineItems

			case searchPDFDocuments
			case searchDocuments
			// case searchText
			case searchImages
			case searchVideos
			case searchAudios
			case recents

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
			if configuration.showSavedSearches, savedSearchesDataSource == nil {
				savedSearchesDataSource = OCDataSourceKVO(object: vault, keyPath: "savedSearches", versionedItemUpdateHandler: { [weak self] obj, keypath, newValue in
					if let savedSearches = newValue as? [OCSavedSearch] {
						let searches = savedSearches.filter { savedSearch in return !savedSearch.isTemplate }
						self?.savedSearchesVisible = searches.count > 0
						return searches
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
	var savedSearchesVisible: Bool = true {
		didSet {
			if oldValue != savedSearchesVisible, let savedSearchesFolderDatasource = specialItemsDataSources[.savedSearchesFolder] {
				itemsDataSource.setInclude(savedSearchesVisible, for: savedSearchesFolderDatasource)
			}
		}
	}
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
			if configuration.showSavedSearches, let savedSearchesDataSource = savedSearchesDataSource {
				savedSearchesCondition = DataSourceCondition(.empty, with: savedSearchesDataSource, initial: true, action: { [weak self] condition in
					self?.savedSearchesVisible = condition.fulfilled == false
				})

				let (savedSearchesFolderDataSource, savedSearchesFolderItem) = self.buildFolder(with: savedSearchesDataSource, title: "Saved searches".localized, icon: OCSymbol.icon(forSymbolName: "magnifyingglass"), folderItemRef:specialItemsDataReferences[.savedSearchesFolder]!)

				specialItems[.savedSearchesFolder] = savedSearchesFolderItem
				specialItemsDataSources[.savedSearchesFolder] = savedSearchesFolderDataSource

				sources.append(savedSearchesFolderDataSource)
			}

			// Quick access
			if configuration.showQuickAccess {
				var quickAccessItems: [OCDataItem & OCDataItemVersioning] = []

				// Recents
				if specialItems[.recents] == nil {
					specialItems[.recents] = OCSavedSearch(scope: .account, location: nil, name: "Recents".localized, isTemplate: false, searchTerm: ":recent :file").withCustomIcon(name: "clock.arrow.circlepath").useNameAsTitle(true).useSortDescriptor(SortDescriptor(method: .lastUsed, direction: .ascendant))
				}
				if let sideBarItem = specialItems[.recents] {
					quickAccessItems.append(sideBarItem)
				}

				// Favorites
				if bookmark?.hasCapability(.favorites) == true {
					if specialItems[.favoriteItems] == nil {
						specialItems[.favoriteItems] = buildSidebarSpecialItem(with: "Favorites".localized, icon: OCSymbol.icon(forSymbolName: "star"), for: .favoriteItems)
					}
					if let sideBarItem = specialItems[.favoriteItems] {
						quickAccessItems.append(sideBarItem)
					}
				}

				// Available offline
				if specialItems[.availableOfflineItems] == nil {
					specialItems[.availableOfflineItems] = buildSidebarSpecialItem(with: "Available Offline".localized, icon: OCItem.cloudAvailableOfflineStatusIcon, for: .availableOfflineItems)
				}
				if let sideBarItem = specialItems[.availableOfflineItems] {
					quickAccessItems.append(sideBarItem)
				}

				// Convenience searches
				if specialItems[.searchPDFDocuments] == nil {
					specialItems[.searchPDFDocuments] = OCSavedSearch(scope: .account, location: nil, name: "PDF Documents".localized, isTemplate: false, searchTerm: ":pdf").withCustomIcon(name: "doc.richtext").useNameAsTitle(true)
				}
				if specialItems[.searchDocuments] == nil {
					specialItems[.searchDocuments] = OCSavedSearch(scope: .account, location: nil, name: "Documents".localized, isTemplate: false, searchTerm: ":document").withCustomIcon(name: "doc").useNameAsTitle(true)
				}
				if specialItems[.searchImages] == nil {
					specialItems[.searchImages] = OCSavedSearch(scope: .account, location: nil, name: "Images".localized, isTemplate: false, searchTerm: ":image").withCustomIcon(name: "photo").useNameAsTitle(true)
				}
				if specialItems[.searchVideos] == nil {
					specialItems[.searchVideos] = OCSavedSearch(scope: .account, location: nil, name: "Videos".localized, isTemplate: false, searchTerm: ":video").withCustomIcon(name: "film").useNameAsTitle(true)
				}
				if specialItems[.searchAudios] == nil {
					specialItems[.searchAudios] = OCSavedSearch(scope: .account, location: nil, name: "Audios".localized, isTemplate: false, searchTerm: ":audio").withCustomIcon(name: "waveform").useNameAsTitle(true)
				}

				let addSpecialItemsTypes: [SpecialItem] = [ .searchPDFDocuments, .searchDocuments, .searchImages, .searchVideos, .searchAudios ]

				for specialItemType in addSpecialItemsTypes {
					if let item = specialItems[specialItemType] as? OCSavedSearch {
						if let representationUUID = specialItemsDataReferences[specialItemType] as? String {
							item.uuid = representationUUID
						}
						quickAccessItems.append(item)
					}
				}

				quickAccessItemsDataSource.setVersionedItems(quickAccessItems)

				// Quick access folder
				if specialItems[.quickAccessFolder] == nil {
					let (quickAccessFolderDataSource, quickAccessFolderItem) = self.buildFolder(with: quickAccessItemsDataSource, title: "Quick Access".localized, icon: OCSymbol.icon(forSymbolName: "speedometer"), folderItemRef:specialItemsDataReferences[.quickAccessFolder]!)

					specialItems[.quickAccessFolder] = quickAccessFolderItem
					specialItemsDataSources[.quickAccessFolder] = quickAccessFolderDataSource
				}

				if let quickAccessFolderDataSource = specialItemsDataSources[.quickAccessFolder] {
					sources.append(quickAccessFolderDataSource)
				}
				
				if configuration.expandQuickAccess, let accountControllerSection = accountControllerSection,
				   let expandedItemRefs = accountControllerSection.collectionViewController?.wrap(references: [  specialItemsDataReferences[.quickAccessFolder]! ], forSection: accountControllerSection.identifier) {
					accountControllerSection.expandedItemRefs = expandedItemRefs
				}
			}

			// Extra items (Activity & Co via class extension in the app)
			if let extraItemsSupport = self as? AccountControllerExtraItems {
				extraItemsSupport.updateExtraItems(dataSource: extraItemsDataSource)

				sources.append(extraItemsDataSource)
			}

			itemsDataSource.sources = sources

			if let savedSearchesFolderDataSource = specialItemsDataSources[.savedSearchesFolder], !savedSearchesVisible {
				itemsDataSource.setInclude(savedSearchesVisible, for: savedSearchesFolderDataSource)
			}
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
					// CollectionViewAction(kind: .expand(animated: true), itemReference: spacesFolderItemRef)
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
