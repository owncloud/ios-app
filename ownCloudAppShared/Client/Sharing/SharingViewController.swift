//
//  SharingViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 17.04.23.
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

public typealias ItemProvider = () -> OCItem?

open class SharingViewController: CollectionViewController {

	var managementClientContext: ClientContext

	var itemSection: CollectionViewSection
	var itemSectionDatasource: OCDataSourceArray

	var recipientsSection: CollectionViewSection?
	var addRecipientDataSource: OCDataSourceArray?
	var recipientsSectionDatasource: OCDataSourceComposition?

	var linksSection: CollectionViewSection?
	var addLinkDataSource: OCDataSourceArray?
	var linksSectionDatasource: OCDataSourceComposition?

	var itemTracker: OCCoreItemTracking?
	public var item: OCItem {
		didSet {
			itemSectionDatasource.setVersionedItems([item])
		}
	}
	public var itemIsDriveRoot: Bool

	var itemSharesQuery: OCShareQuery?
	private var driveManagerCountSubscription: OCDataSourceSubscription?
	private var driveManagerCount: Int = 0

	private var recipientsSubscription: OCDataSourceSubscription?
	private var recipientsIdentifiers: [String]?

	public init(clientContext: ClientContext, item: OCItem) {
		var sections: [CollectionViewSection] = []

		self.item = item
		self.itemIsDriveRoot = item.isRoot && item.driveID != nil && clientContext.core?.drive(withIdentifier: item.driveID!, attachedOnly: true)?.specialType == .space

		// Item section
		let itemSectionContext = ClientContext(with: clientContext, modifier: { context in
			context.permissions = []
		})

		itemSectionDatasource = OCDataSourceArray(items: [item])
		itemSection = CollectionViewSection(identifier: "item", dataSource: itemSectionDatasource, cellStyle: .init(with: .header), cellLayout: .list(appearance: .plain, contentInsets: NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)), clientContext: itemSectionContext)
		sections.append(itemSection)

		// Management section cell style
		let managementCellStyle = SharingViewController.composeManagementCellStyle(allowEditing: canUpdate)

		managementClientContext = ClientContext(with: clientContext)
		managementClientContext.postInitializationModifier = { (owner, context) in
			context.originatingViewController = owner as? UIViewController
		}

		// Invite section
		addRecipientDataSource = OCDataSourceArray(items: [])

		// Recipients section
		itemSharesQuery = OCShareQuery(scope: .itemWithReshares, item: item)
		itemSharesQuery?.refreshInterval = 5

		if let itemSharesQueryDataSource = itemSharesQuery?.dataSource, let addRecipientDataSource {
			recipientsSectionDatasource = OCDataSourceComposition(sources: [
				// Unified solution based on a single data source, not currently possible for oCIS due to to https://github.com/owncloud/ocis/issues/5355
				// with sharedByMeDataSource = clientContext.core?.sharedByMeDataSource in if-clause
				// sharedByMeDataSource,

				itemSharesQueryDataSource,
				addRecipientDataSource
			], applyCustomizations: {  composedDataSource in
				// Filter for non-link shares in results
				composedDataSource.setFilter({ dataSource, dataItemRef in
					if let itemRecord = try? dataSource.record(forItemRef: dataItemRef),
					   let share = itemRecord.item as? OCShare {
						return share.type != .link
					}
					return false
				}, for: itemSharesQueryDataSource)

				/*
				// Unified solution based on a single data source, not currently possible for oCIS due to to https://github.com/owncloud/ocis/issues/5355
				// with let location = item.location in if-clause
				composedDataSource.setFilter({ dataSource, dataItemRef in
					if let itemRecord = try? dataSource.record(forItemRef: dataItemRef),
					   let share = itemRecord.item as? OCShare {
						return share.itemLocation.isEqual(location)
					}
					return false
				}, for: sharedByMeDataSource)
				*/
			})

			recipientsSection = CollectionViewSection(identifier: "recipients", dataSource: recipientsSectionDatasource, cellStyle: managementCellStyle, cellLayout: .list(appearance: .insetGrouped, contentInsets: .insetGroupedSectionInsets), clientContext: managementClientContext)
			recipientsSection?.boundarySupplementaryItems = [
				.mediumTitle(itemIsDriveRoot ? OCLocalizedString("Members", nil) : OCLocalizedString("Shared with", nil))
			]
			sections.append(recipientsSection!)
		}

		// Links section
		if clientContext.core?.connection.capabilities?.publicSharingEnabled == true {
			addLinkDataSource = OCDataSourceArray(items: [])

			if let itemSharesQueryDataSource = itemSharesQuery?.dataSource, let addLinkDataSource {
				linksSectionDatasource = OCDataSourceComposition(sources: [
					// Unified solution based on a single data source, not currently possible for oCIS due to to https://github.com/owncloud/ocis/issues/5355
					// with let sharedByLinkDataSource = clientContext.core?.sharedByLinkDataSource in if-clause
					// sharedByLinkDataSource,

					itemSharesQueryDataSource,
					addLinkDataSource
				], applyCustomizations: { composedDataSource in
					// Filter for link shares in results
					composedDataSource.setFilter({ dataSource, dataItemRef in
						if let itemRecord = try? dataSource.record(forItemRef: dataItemRef),
						   let share = itemRecord.item as? OCShare {
							return share.type == .link
						}
						return false
					}, for: itemSharesQueryDataSource)

					// Unified solution based on a single data source, not currently possible for oCIS due to to https://github.com/owncloud/ocis/issues/5355
					/*
					// with let location = item.location, in if-clause
					composedDataSource.setFilter({ dataSource, dataItemRef in
						if let itemRecord = try? dataSource.record(forItemRef: dataItemRef),
						   let share = itemRecord.item as? OCShare {
							return share.itemLocation.isEqual(location)
						}
						return false
					}, for: sharedByLinkDataSource)
					*/
				})

				linksSection = CollectionViewSection(identifier: "links", dataSource: linksSectionDatasource, cellStyle: managementCellStyle, cellLayout: .list(appearance: .insetGrouped, contentInsets: .insetGroupedSectionInsets), clientContext: managementClientContext)
				linksSection?.boundarySupplementaryItems = [
					.mediumTitle(OCLocalizedString("Public Links", nil))
				]
				linksSection?.hideIfEmptyDataSource = linksSectionDatasource
				sections.append(linksSection!)
			}
		}

		// Init
		super.init(context: managementClientContext, sections: sections, useStackViewRoot: true)
		navigationItem.titleLabelText = itemIsDriveRoot ? OCLocalizedString("Members", nil) : OCLocalizedString("Sharing", nil)
		navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .done, primaryAction: UIAction(handler: { [weak self] action in
			self?.dismiss(animated: true)
		}))

		let itemProvider: ItemProvider = { [weak self] in
			return self?.item
		}
		managementCellStyle.options[.sharedItemProvider] = itemProvider

		self.cssSelector = .grouped

		if let location = item.location {
			itemTracker = clientContext.core?.trackItem(at: location, trackingHandler: { [weak self] error, latestItem, initial in
				if let latestItem {
					self?.item = latestItem
				}
			})
		}

		addRecipientDataSource?.setVersionedItems([
			OCAction(title: OCLocalizedString("Invite", nil), icon: OCSymbol.icon(forSymbolName: "plus.circle.fill"), action: { [weak self] action, options, completion in
				self?.createShare(type: .share)
				completion(nil)
			})
		])

		var linkActions = [
			OCAction(title: OCLocalizedString("Create link", nil), icon: OCSymbol.icon(forSymbolName: "plus.circle.fill"), action: { [weak self] (action, options, completion) in
				self?.createShare(type: .link)
				completion(nil)
			})
		]

		if managementClientContext.core?.connection.capabilities?.supportsPrivateLinks == true {
			linkActions.append(
				OCAction(title: OCLocalizedString("Copy Private Link", nil), icon: OCSymbol.icon(forSymbolName: "list.clipboard"), action: { [weak self] _, _, completion in
					if let item = self?.item, let core = self?.clientContext?.core {
						core.retrievePrivateLink(for: item, completionHandler: { (error, url) in
							guard let url = url else { return }
							if error == nil, let presentationViewController = self?.clientContext?.presentationViewController {
								OnMainThread {
									UIPasteboard.general.url = url

									_ = NotificationHUDViewController(on: presentationViewController, title: OCLocalizedString("Private Link", nil), subtitle: OCLocalizedString("URL was copied to the clipboard", nil), completion: nil)
								}
							}
						})
					}

					completion(nil)
				})
			)
		}

		addLinkDataSource?.setVersionedItems(linkActions)

		revoke(in: clientContext, when: [ .connectionClosed, .connectionOffline ])

		itemSharesQuery?.changesAvailableNotificationHandler = { [weak self] query in
			// Called when populated the first time - query.allowedPermissionActions should now be available
			self?.allowedPermissionActions = query.allowedPermissionActions
		}

		if let itemSharesQueryDataSource = itemSharesQuery?.dataSource {
			// Subscribe to shares query data source to compile list of identity identifiers for existing recipients
			recipientsSubscription = itemSharesQueryDataSource.subscribe(updateHandler: { [weak self] subscription in
				let snapshot = subscription.snapshotResettingChangeTracking(true)
				var identityIdentifiers: [String] = []

				// Add recipients of existing shares
				for itemRef in snapshot.items {
					if let itemRecord = try? subscription.source?.record(forItemRef: itemRef),
					   let share = itemRecord.item as? OCShare,
					   let identity = share.recipient {
					   	if let identifier = identity.identifier {
						   	identityIdentifiers.append(identifier)
						}
					}
				}

				// Add currently logged in user
				if let loggedInUser = self?.clientContext?.core?.connection.loggedInUser,
				   let loggedInUserIdentifier = loggedInUser.identifier {
					identityIdentifiers.append(loggedInUserIdentifier)
				}

				if let self {
					OCSynchronized(self) {
						self.recipientsIdentifiers = identityIdentifiers
					}
				}
			}, on: .main, trackDifferences: true, performInitialUpdate: true)
		}

		if let core = clientContext.core, let itemSharesQuery {
			core.start(itemSharesQuery)
		}

		managementClientContext.add(permissionHandler: { [weak self] context, dataItemRecord, checkInteraction, inViewController in
			if dataItemRecord?.type == .share, let self {
				switch checkInteraction {
					case .selection, .contextMenu, .leadingSwipe, .trailingSwipe:
						// Detect and block editing of last manager member, showing an alert
						if self.canUpdate, self.itemIsDriveRoot {
							let driveRole = (dataItemRecord?.item as? OCShare)?.sharePermissions?.first(where: { permission in
								permission.driveRole != .none
							})?.driveRole

							if driveRole == .manager, self.driveManagerCount <= 1 {
								let alert = ThemedAlertController(title: OCLocalizedString("Can't edit only manager", nil), message: OCLocalizedString("If only one member is a manager, that member's permissions can't be edited.", nil), preferredStyle: .alert)

								alert.addAction(UIAlertAction(title: OCLocalizedString("OK", nil), style: .default, handler: nil))
								context?.present(alert, animated: true)

								return false
							}
						}

						// Only allow selection and contextmenu (editing), leading and trailing swipes (delete) if user has update permission
						return self.canUpdate

					default: break
				}
			}

			return true
		})

		if itemIsDriveRoot {
			driveManagerCountSubscription = itemSharesQuery?.dataSource.subscribe(updateHandler: { [weak self] subscription in
				let snapshot = subscription.snapshotResettingChangeTracking(true)
				var managerCount = 0
				for itemRef in snapshot.items {
					if let itemRecord = try? subscription.source?.record(forItemRef: itemRef), itemRecord.type == .share,
					   let share = itemRecord.item as? OCShare,
					   let driveRole = share.sharePermissions?.first(where: { permission in permission.driveRole != .none })?.driveRole,
					   driveRole == .manager {
						managerCount += 1
					}
				}
				self?.driveManagerCount = managerCount
			}, on: .main, trackDifferences: true, performInitialUpdate: true)
		}

		// Disable dragging of items, so keyboard control does
		// not include "Drag Item" in the accessibility actions
		// invoked with Tab + Z
		defer { // needed so dragInteractionEnabled.didSet is called despite being set in the initializer
			dragInteractionEnabled = false
		}
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		driveManagerCountSubscription?.terminate()
		recipientsSubscription?.terminate()

		if let core = clientContext?.core, let itemSharesQuery {
			core.stop(itemSharesQuery)
		}
	}

	static func composeManagementCellStyle(allowEditing: Bool) -> CollectionViewCellStyle {
		let managementCellStyle: CollectionViewCellStyle = .init(with: .tableCell)
		managementCellStyle.options = [
			.showManagementView : true,
			.withoutDisclosure : !allowEditing
		]
		return managementCellStyle
	}

	func createShare(type: ShareViewController.ShareType) {
		guard let clientContext else { return }

		let shareViewController = ShareViewController(type: type, mode: .create, item: item, clientContext: clientContext, identityFilter: { [weak self] identity in
			// Filter out all users that have already been added
			guard let self else { return false }

			if let identityIdentifier = identity.identifier {
				var includeIdentity: Bool = true

				OCSynchronized(self) {
					includeIdentity = self.recipientsIdentifiers?.contains(identityIdentifier) != true
				}

				return includeIdentity
			}

			return true
		}, completion: { _ in
		})

		let navigationController = ThemeNavigationController(rootViewController: shareViewController)
		self.present(navigationController, animated: true)
	}

	var allowedPermissionActions: [OCShareActionID]? {
		didSet {
			if let allowedPermissionActions {
				canCreate = allowedPermissionActions.contains(.createPermissions)
				canUpdate = allowedPermissionActions.contains(.updatePermissions)
			}
		}
	}

	var canCreate: Bool = true {
		didSet {
			if let addLinkDataSource, let addRecipientDataSource {
				linksSectionDatasource?.setInclude(canCreate, for: addLinkDataSource)
				recipientsSectionDatasource?.setInclude(canCreate, for: addRecipientDataSource)
			}
		}
	}
	var canUpdate: Bool = true {
		didSet {
			let managementCellStyle = SharingViewController.composeManagementCellStyle(allowEditing: canUpdate)
			recipientsSection?.cellStyle = managementCellStyle
			linksSection?.cellStyle = managementCellStyle
		}
	}
}

public extension CollectionViewCellStyle.StyleOptionKey {
	static let showManagementView = CollectionViewCellStyle.StyleOptionKey(rawValue: "showManagementView")
	static let withoutDisclosure = CollectionViewCellStyle.StyleOptionKey(rawValue: "withoutDisclosure")
	static let sharedItemProvider = CollectionViewCellStyle.StyleOptionKey(rawValue: "sharedItemProvider")
}
