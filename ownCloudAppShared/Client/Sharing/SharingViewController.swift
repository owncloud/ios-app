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

	public init(clientContext: ClientContext, item: OCItem) {
		var sections: [CollectionViewSection] = []

		self.item = item

		// Item section
		let itemSectionContext = ClientContext(with: clientContext, modifier: { context in
			context.permissions = []
		})

		itemSectionDatasource = OCDataSourceArray(items: [item])
		itemSection = CollectionViewSection(identifier: "item", dataSource: itemSectionDatasource, cellStyle: .init(with: .header), cellLayout: .list(appearance: .plain, contentInsets: NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)), clientContext: itemSectionContext)
		sections.append(itemSection)

		// Managament section cell style
		let managementCellStyle: CollectionViewCellStyle = .init(with: .tableCell)
		managementCellStyle.options = [
			.showManagementView : true
		]

		let managementClientContext = ClientContext(with: clientContext)
		managementClientContext.postInitializationModifier = { (owner, context) in
			context.originatingViewController = owner as? UIViewController
		}

		// Invite section
		addRecipientDataSource = OCDataSourceArray(items: [])

		// Recipients section
		if let sharedByMeDataSource = clientContext.core?.sharedByMeDataSource, let location = item.location, let addRecipientDataSource {
			recipientsSectionDatasource = OCDataSourceComposition(sources: [
				sharedByMeDataSource,
				addRecipientDataSource
			], applyCustomizations: { composedDataSource in
				composedDataSource.setFilter({ dataSource, dataItemRef in
					if let itemRecord = try? dataSource.record(forItemRef: dataItemRef),
					   let share = itemRecord.item as? OCShare {
						return share.itemLocation.isEqual(location)
					}
					return false
				}, for: sharedByMeDataSource)
			})

			recipientsSection = CollectionViewSection(identifier: "recipients", dataSource: recipientsSectionDatasource, cellStyle: managementCellStyle, cellLayout: .list(appearance: .insetGrouped, contentInsets: .insetGroupedSectionInsets), clientContext: managementClientContext)
			recipientsSection?.boundarySupplementaryItems = [
				.mediumTitle("Shared with".localized)
			]
			sections.append(recipientsSection!)
		}

		// Links section
		if clientContext.core?.connection.capabilities?.publicSharingEnabled == true {
			addLinkDataSource = OCDataSourceArray(items: [])

			if let sharedByLinkDataSource = clientContext.core?.sharedByLinkDataSource, let location = item.location, let addLinkDataSource {
				linksSectionDatasource = OCDataSourceComposition(sources: [
					sharedByLinkDataSource,
					addLinkDataSource
				], applyCustomizations: { composedDataSource in
					composedDataSource.setFilter({ dataSource, dataItemRef in
						if let itemRecord = try? dataSource.record(forItemRef: dataItemRef),
						   let share = itemRecord.item as? OCShare {
							return share.itemLocation.isEqual(location)
						}
						return false
					}, for: sharedByLinkDataSource)
				})

				linksSection = CollectionViewSection(identifier: "links", dataSource: linksSectionDatasource, cellStyle: managementCellStyle, cellLayout: .list(appearance: .insetGrouped, contentInsets: .insetGroupedSectionInsets), clientContext: managementClientContext)
				linksSection?.boundarySupplementaryItems = [
					.mediumTitle("Links".localized)
				]
				sections.append(linksSection!)
			}
		}

		// Init
		super.init(context: managementClientContext, sections: sections, useStackViewRoot: true)
		navigationItem.titleLabelText = "Sharing".localized
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
			OCAction(title: "Invite".localized, icon: OCSymbol.icon(forSymbolName: "plus.circle.fill"), action: { [weak self] action, options, completion in
				self?.createShare(type: .share)
				completion(nil)
			})
		])

		var linkActions = [
			OCAction(title: "Create link".localized, icon: OCSymbol.icon(forSymbolName: "plus.circle.fill"), action: { [weak self] (action, options, completion) in
				self?.createShare(type: .link)
				completion(nil)
			})
		]

		if managementClientContext.core?.connection.capabilities?.supportsPrivateLinks == true {
			linkActions.append(
				OCAction(title: "Copy Private Link", icon: OCSymbol.icon(forSymbolName: "list.clipboard"), action: { [weak self] _, _, completion in
					if let item = self?.item, let core = self?.clientContext?.core {
						core.retrievePrivateLink(for: item, completionHandler: { (error, url) in
							guard let url = url else { return }
							if error == nil, let presentationViewController = self?.clientContext?.presentationViewController {
								OnMainThread {
									UIPasteboard.general.url = url

									_ = NotificationHUDViewController(on: presentationViewController, title: "Private Link".localized, subtitle: "URL was copied to the clipboard".localized, completion: nil)
								}
							}
						})
					}

					completion(nil)
				})
			)
		}

		addLinkDataSource?.setVersionedItems(linkActions)
	}

	func createShare(type: ShareViewController.ShareType) {
		guard let clientContext else { return }

		let shareViewController = ShareViewController(type: type, mode: .create, item: item, clientContext: clientContext, completion: { _ in
		})
		let navigationController = ThemeNavigationController(rootViewController: shareViewController)
		self.present(navigationController, animated: true)
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

public extension CollectionViewCellStyle.StyleOptionKey {
	static let showManagementView = CollectionViewCellStyle.StyleOptionKey(rawValue: "showManagementView")
	static let withoutDisclosure = CollectionViewCellStyle.StyleOptionKey(rawValue: "withoutDisclosure")
	static let sharedItemProvider = CollectionViewCellStyle.StyleOptionKey(rawValue: "sharedItemProvider")
}
