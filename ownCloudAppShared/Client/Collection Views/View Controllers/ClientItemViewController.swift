//
//  ClientItemViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 14.04.22.
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

public class ClientItemViewController: CollectionViewController, UISearchControllerDelegate, UISearchResultsUpdating {
	public enum ContentState : String, CaseIterable {
		case loading

		case empty
		case hasContent
	}

	public var query: OCQuery?

	weak public var queryDataSource : OCDataSource?
	public var queryItemDataSourceSection : CollectionViewSection?

	public var driveSection : CollectionViewSection?

	public var driveSectionDataSource : OCDataSourceComposition?
	public var singleDriveDatasource : OCDataSourceComposition?
	private var singleDriveDatasourceSubscription : OCDataSourceSubscription?
	public var driveAdditionalItemsDataSource : OCDataSourceArray = OCDataSourceArray()

	public var emptyItemListDataSource : OCDataSourceArray = OCDataSourceArray()
	public var emptyItemListDecisionSubscription : OCDataSourceSubscription?
	public var emptyItemListItem : OCDataItemPresentable?

	private var stateObservation : NSKeyValueObservation?

	public init(context inContext: ClientContext?, query inQuery: OCQuery, reveal inItem: OCItem? = nil) {
		query = inQuery

		var sections : [ CollectionViewSection ] = []

		let itemControllerContext = ClientContext(with: inContext, modifier: { context in
			context.permissionHandler = { (context, record, interaction) in
				switch interaction {
					case .selection:
						if record?.type == .drive {
							// Do not react to taps on the drive header cells (=> or show image in the future)
							return false
						}

						return true

					default:
						return true
				}
			}
		})
		itemControllerContext.postInitializationModifier = { (owner, context) in
			if context.openItemHandler == nil {
				context.openItemHandler = owner as? OpenItemAction
			}
			if context.moreItemHandler == nil {
				context.moreItemHandler = owner as? MoreItemAction
			}

			context.query = (owner as? ClientItemViewController)?.query

			context.originatingViewController = owner as? UIViewController
		}

		if let queryResultsDatasource = query?.queryResultsDataSource, let core = itemControllerContext.core {
			queryDataSource = queryResultsDatasource
			singleDriveDatasource = OCDataSourceComposition(sources: [core.drivesDataSource])

			if query?.queryLocation?.isRoot == true {
				// Create data source from one drive
				singleDriveDatasource?.filter = OCDataSourceComposition.itemFilter(withItemRetrieval: false, fromRecordFilter: { itemRecord in
					if let drive = itemRecord?.item as? OCDrive {
						if drive.identifier == itemControllerContext.drive?.identifier {
							return true
						}
					}

					return false
				})

				// Create combined data source from drive + additional items
				driveSectionDataSource = OCDataSourceComposition(sources: [ singleDriveDatasource!, driveAdditionalItemsDataSource ])

				// Create drive section from combined data source
				driveSection = CollectionViewSection(identifier: "drive", dataSource: driveSectionDataSource, cellStyle: .header, cellLayout: .list(appearance: .plain))
			}

			queryItemDataSourceSection = CollectionViewSection(identifier: "items", dataSource: queryResultsDatasource, clientContext: itemControllerContext)

			if let driveSection = driveSection {
				sections.append(driveSection)
			}

			if let queryItemDataSourceSection = queryItemDataSourceSection {
				sections.append(queryItemDataSourceSection)
			}
		}

		let emptySection = CollectionViewSection(identifier: "empty", dataSource: emptyItemListDataSource, cellStyle: .fillSpace, cellLayout: .list(appearance: .insetGrouped), clientContext: itemControllerContext)
		sections.append(emptySection)

		super.init(context: itemControllerContext, sections: sections)

		// Track query state and recompute content state when it changes
		stateObservation = queryDataSource?.observe(\OCDataSource.state, options: [], changeHandler: { [weak self] query, change in
			self?.recomputeContentState()
		})

		// Subscribe to singleDriveDatasource for changes, to update driveSectionDataSource
		singleDriveDatasourceSubscription = singleDriveDatasource?.subscribe(updateHandler: { [weak self] (subscription) in
			self?.updateAdditionalDriveItems(from: subscription)
		}, on: .main, trackDifferences: true, performIntialUpdate: true)

		if let queryDatasource = query?.queryResultsDataSource {
			emptyItemListItem = OCDataItemPresentable(reference: "_emptyItemList" as NSString, originalDataItemType: nil, version: nil)
			emptyItemListItem?.title = "This folder is empty. Fill it with content:".localized
			emptyItemListItem?.childrenDataSourceProvider = nil

			emptyItemListDecisionSubscription = queryDatasource.subscribe(updateHandler: { [weak self] (subscription) in
				self?.updateEmptyItemList(from: subscription)
			}, on: .main, trackDifferences: false, performIntialUpdate: true)
		}

		query?.sortComparator = SortMethod.alphabetically.comparator(direction: .ascendant)

		if let navigationTitle = query?.queryLocation?.isRoot == true ? clientContext?.drive?.name : query?.queryLocation?.lastPathComponent {
			navigationItem.title = navigationTitle
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		stateObservation?.invalidate()
		singleDriveDatasourceSubscription?.terminate()
	}

	public override func viewDidLoad() {
		super.viewDidLoad()

		var rightInset : CGFloat = 2
		var leftInset : CGFloat = 0
		if self.view.effectiveUserInterfaceLayoutDirection == .rightToLeft {
			rightInset = 0
			leftInset = 2
		}

		var viewActionButtons : [UIBarButtonItem] = []

		if query?.queryLocation != nil {
			if clientContext?.moreItemHandler != nil {
				let folderActionBarButton = UIBarButtonItem(image: UIImage(named: "more-dots")?.withInset(UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)), style: .plain, target: self, action: #selector(moreBarButtonPressed))
				folderActionBarButton.accessibilityIdentifier = "client.folder-action"
				folderActionBarButton.accessibilityLabel = "Actions".localized

				viewActionButtons.append(folderActionBarButton)
			}

			let plusBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
			plusBarButton.menu = UIMenu(title: "", children: [
				UIDeferredMenuElement.uncached({ [weak self] completion in
					if let self = self, let rootItem = self.query?.rootItem, let clientContext = self.clientContext {
						let contextMenuProvider = rootItem as DataItemContextMenuInteraction

						if let contextMenuElements = contextMenuProvider.composeContextMenuItems(in: self, location: .folderAction, with: clientContext) {
							    completion(contextMenuElements)
						}
					}
				})
			])
			plusBarButton.accessibilityIdentifier = "client.file-add"

			viewActionButtons.append(plusBarButton)
		}

		self.navigationItem.rightBarButtonItems = viewActionButtons

		// Setup search controller
//		searchController = UISearchController(searchResultsController: nil)
//		searchController?.searchResultsUpdater = self
//		searchController?.obscuresBackgroundDuringPresentation = false
//		searchController?.hidesNavigationBarDuringPresentation = true
//		searchController?.searchBar.applyThemeCollection(Theme.shared.activeCollection)
//		searchController?.delegate = self
//
//		navigationItem.searchController = searchController
//		navigationItem.hidesSearchBarWhenScrolling = false
	}

	public override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if let query = query {
			clientContext?.core?.start(query)
		}
	}

	open override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		if let query = query {
			clientContext?.core?.stop(query)
		}
	}

	public func updateAdditionalDriveItems(from subscription: OCDataSourceSubscription) {
		let snapshot = subscription.snapshotResettingChangeTracking(true)

		if let core = clientContext?.core,
		   let firstItemRef = snapshot.items.first,
	  	   let itemRecord = try? subscription.source?.record(forItemRef: firstItemRef),
		   let drive = itemRecord.item as? OCDrive,
		   let driveRepresentation = OCDataRenderer.default.renderItem(drive, asType: .presentable, error: nil) as? OCDataItemPresentable,
		   let descriptionResourceRequest = try? driveRepresentation.provideResourceRequest(.coverDescription) {
			descriptionResourceRequest.lifetime = .singleRun
			descriptionResourceRequest.changeHandler = { [weak self] (request, error, isOngoing, previousResource, newResource) in
				// Log.debug("REQ_Readme request: \(String(describing: request)) | error: \(String(describing: error)) | isOngoing: \(isOngoing) | newResource: \(String(describing: newResource))")
				if let textResource = newResource as? OCResourceText {
					self?.driveAdditionalItemsDataSource.setItems([textResource], updated: [textResource])
				}
			}

			core.vault.resourceManager?.start(descriptionResourceRequest)
		}
	}

	var _actionProgressHandler : ActionProgressHandler?

	// MARK: - Empty item list handling
	func emptyActions() -> [OCAction]? {
		guard let context = clientContext, let core = context.core, let item = query?.rootItem else {
			return nil
		}
		let locationIdentifier: OCExtensionLocationIdentifier = .emptyFolder
		let originatingViewController : UIViewController = context.originatingViewController ?? self
		let actionsLocation = OCExtensionLocation(ofType: .action, identifier: locationIdentifier)
		let actionContext = ActionContext(viewController: originatingViewController, core: core, query: context.query, items: [item], location: actionsLocation, sender: self)

		let emptyFolderActions = Action.sortedApplicableActions(for: actionContext)
		var actions : [OCAction] = []

		for emptyFolderAction in emptyFolderActions {
			if let action = emptyFolderAction.provideOCAction() {
				actions.append(action)
			}
		}

		return (actions.count > 0) ? actions : nil
	}

	func updateEmptyItemList(from subscription: OCDataSourceSubscription) {
		recomputeContentState()
	}

	func recomputeContentState() {
		OnMainThread {
			switch self.queryDataSource?.state {
				case .loading:
					self.contentState = .loading

				case .idle:
					self.contentState = (self.emptyItemListDecisionSubscription?.snapshotResettingChangeTracking(true).numberOfItems == 0) ? .empty : .hasContent

				default: break
			}
		}
	}

	public var contentState : ContentState = .loading {
		didSet {
			if contentState == oldValue {
				return
			}

			switch contentState {
				case .empty:
					var emptyItems : [OCDataItem] = [ ]

					if let emptyItemListItem = emptyItemListItem {
						emptyItems.append(emptyItemListItem)
					}

					if let emptyActions = emptyActions() {
						emptyItems.append(contentsOf: emptyActions)
					}

					emptyItemListDataSource.setItems(emptyItems, updated: nil)

				case .hasContent, .loading:
					emptyItemListDataSource.setItems(nil, updated: nil)
			}
		}
	}

	// MARK: - Navigation Bar Actions
	@objc open func moreBarButtonPressed(_ sender: UIBarButtonItem) {
		guard let rootItem = query?.rootItem else {
			return
		}

		if let moreItemHandler = clientContext?.moreItemHandler, let clientContext = clientContext {
			moreItemHandler.moreOptions(for: rootItem, at: .moreFolder, context: clientContext, sender: sender)
		}
	}

	// MARK: - Search
	open var searchController: UISearchController?

	// MARK: - Search: UISearchResultsUpdating Delegate
	open func updateSearchResults(for searchController: UISearchController) {
		let searchText = searchController.searchBar.text ?? ""

//		applySearchFilter(for: (searchText == "") ? nil : searchText, to: query)
	}

	open func willPresentSearchController(_ searchController: UISearchController) {
//		self.sortBar?.showSelectButton = false
	}

	open func willDismissSearchController(_ searchController: UISearchController) {
//		self.sortBar?.showSelectButton = true
	}

	open func applySearchFilter(for searchText: String?, to query: OCQuery) {
 		if let searchText = searchText {
			let queryCondition = OCQueryCondition.fromSearchTerm(searchText)
 			let filterHandler: OCQueryFilterHandler = { (_, _, item) -> Bool in
 				if let item = item, let queryCondition = queryCondition {
	 				return queryCondition.fulfilled(by: item)
				}
 				return false
 			}

 			if let filter = query.filter(withIdentifier: "text-search") {
 				query.updateFilter(filter, applyChanges: { filterToChange in
 					(filterToChange as? OCQueryFilter)?.filterHandler = filterHandler
 				})
 			} else {
 				query.addFilter(OCQueryFilter.init(handler: filterHandler), withIdentifier: "text-search")
 			}
 		} else {
 			if let filter = query.filter(withIdentifier: "text-search") {
 				query.removeFilter(filter)
 			}
 		}
 	}
}
