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
		public var showSavedSearches: Bool
		public var showActivity: Bool
		public var showAccountPill: Bool
		public var autoSelectPersonalFolder: Bool

		public var sectionAppearance: UICollectionLayoutListConfiguration.Appearance = .sidebar

		public static var defaultConfiguration: Configuration {
			return Configuration()
		}

		public static var pickerConfiguration: Configuration {
			var config = Configuration()

			config.showActivity = false
			config.showSavedSearches = false
			config.sectionAppearance = .insetGrouped
			config.autoSelectPersonalFolder = false

			return config
		}

		public init() {
			showSavedSearches = true
			showActivity = true
			showAccountPill = true
			autoSelectPersonalFolder = true
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

		spacesFolderDataItemRef = UUID().uuidString as NSString
		quickAccessFolderDataItemRef = UUID().uuidString as NSString
		savedSearchesFolderDataItemRef = UUID().uuidString as NSString

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

	open var specialItems: [SpecialItem : OCDataItem] = [:]
	open var specialItemsDataSource: OCDataSourceArray = OCDataSourceArray(items: [])

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

	open var spacesFolderDataItemRef: OCDataItemReference
	open var quickAccessFolderDataItemRef: OCDataItemReference
	open var savedSearchesFolderDataItemRef: OCDataItemReference

	private var legacyAccountRootLocation: OCLocation

	func composeItemsDataSource() {
		if let core = connection?.core {
			var sources : [OCDataSource] = []

			if core.useDrives {
				let (spacesDataSource, spacesFolderItem) = self.buildActionFolder(with: core.projectDrivesDataSource, title: "Spaces".localized, icon: OCSymbol.icon(forSymbolName: "square.grid.2x2"), folderItemRef: spacesFolderDataItemRef, viewControllerProvider: { context, action in
					if let context {
						return AccountControllerSpacesGridViewController(with: context)
					}

					return nil
				})

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
				specialItems[.accountRoot] = legacyAccountRootLocation

				sources = [
					OCDataSourceArray(items: [legacyAccountRootLocation])
				]
			}

			if configuration.showSavedSearches, let savedSearchesDataSource = savedSearchesDataSource {
				let (savedSearchesFolderDataSource, savedSearchesFolderItem) = self.buildFolder(with: savedSearchesDataSource, title: "Saved searches".localized, icon: OCSymbol.icon(forSymbolName: "magnifyingglass"), folderItemRef: savedSearchesFolderDataItemRef)

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

	func buildActionFolder(with contentsDataSource: OCDataSource, title: String, icon: UIImage?, folderItemRef: OCDataItemReference = "_folder_\(UUID().uuidString)" as NSString, viewControllerProvider: @escaping CollectionSidebarAction.ViewControllerProvider) -> (OCDataSource, CollectionSidebarAction) {
		let folderAction = CollectionSidebarAction(with: title, icon: icon, viewControllerProvider: viewControllerProvider)
		folderAction.childrenDataSource = contentsDataSource
//
//		let folderItem = OCDataItemPresentable(reference: folderItemRef, originalDataItemType: .presentable, version: "1" as NSString)
//		folderItem.title = title
//		folderItem.image = icon
//
//		folderItem.hasChildrenProvider = { (dataSource, item) in
//			return true
//		}
//
//		folderItem.childrenDataSourceProvider = { (parentItemDataSource, parentItem) in
//			return contentsDataSource
//		}

		let titleSource = OCDataSourceArray()
		titleSource.setVersionedItems([ folderAction ])

		return (titleSource, folderAction)
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

extension AccountController: DataItemSelectionInteraction {
	public func allowSelection(in viewController: UIViewController?, section: CollectionViewSection?, with context: ClientContext?) -> Bool {
		func revealPersonalItem() {
			if let personalSpaceDataItemRef = self.personalSpaceDataItemRef,
			   let sectionID = section?.identifier,
			   let personalFolderItemRef = section?.collectionViewController?.wrap(references: [personalSpaceDataItemRef], forSection: sectionID).first,
			   let /* spacesFolderItemRef */ _ = section?.collectionViewController?.wrap(references: [spacesFolderDataItemRef], forSection: sectionID).first {
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
