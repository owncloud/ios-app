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

public extension OCDataItemType {
	static let accountController = OCDataItemType(rawValue: "accountController")
}

public class AccountController: NSObject, OCDataItem, OCDataItemVersioning, AccountConnectionStatusObserver {
	public struct Configuration {
		public static var defaultConfiguration: Configuration {
			return Configuration()
		}

		public init() {

		}
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
	typealias CompletionHandler = (_ error: Error?) -> Void

	func connect(completion: CompletionHandler?) {
		connection?.connect(consumer: consumer, completion: completion)
	}

	func disconnect(completion: CompletionHandler?) {
		connection?.disconnect(consumer: consumer, completion: completion)
	}

	// MARK: - Status handling
	public func account(connection: AccountConnection, changedStatusTo status: AccountConnection.Status, initial: Bool) {
		if status == .coreAvailable || status == .online {
			// Begin to show account items
			showAccountItems = true
			showDisconnectButton = true
		} else {
			// Do not show account items
			showAccountItems = false
			showDisconnectButton = false
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

	func composeItemsDataSource() {
		if let core = connection?.core {
			if core.useDrives {
				let (spacesDataSource, spacesFolderItem) = self.buildFolder(with: core.projectDrivesDataSource, title: "Spaces".localized, icon: UIImage(systemName: "square.grid.2x2"))

				if let accountControllerSection = accountControllerSection,
				   let expandedItemRefs = accountControllerSection.collectionViewController?.wrap(references: [ spacesFolderItem.dataItemReference ], forSection: accountControllerSection.identifier) {
					accountControllerSection.expandedItemRefs = expandedItemRefs
				}

				itemsDataSource.sources = [
					core.hierarchicDrivesDataSource,
					spacesDataSource
				]
			} else {
				let accountRootLocation = OCLocation.legacyRoot

				itemsDataSource.sources = [
					OCDataSourceArray(items: [accountRootLocation])
				]
			}
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
	open var dataItemVersion: OCDataItemVersion = NSNumber(0)
}

extension AccountController: DataItemSelectionInteraction {
	public func allowSelection(in viewController: UIViewController?, with context: ClientContext?) -> Bool {
		self.connect(completion: { error in
			Log.debug("Connected with \(error.debugDescription)")
		})
		return false
	}
}
