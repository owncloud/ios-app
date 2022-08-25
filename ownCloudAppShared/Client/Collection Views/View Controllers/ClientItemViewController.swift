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
import Intents

open class ClientItemViewController: CollectionViewController, SortBarDelegate, DropTargetsProvider, SearchViewControllerDelegate, RevealItemAction {
	public enum ContentState : String, CaseIterable {
		case loading

		case empty
		case hasContent
	}

	public var query: OCQuery?

	public var itemsLeadInDataSource : OCDataSourceArray = OCDataSourceArray()
	public var itemsQueryDataSource : OCDataSource?
	public var itemsTrailingDataSource : OCDataSourceArray = OCDataSourceArray()
	public var itemSectionDataSource : OCDataSourceComposition?
	public var itemSection : CollectionViewSection?

	public var driveSection : CollectionViewSection?

	public var driveSectionDataSource : OCDataSourceComposition?
	public var singleDriveDatasource : OCDataSourceComposition?
	private var singleDriveDatasourceSubscription : OCDataSourceSubscription?
	public var driveAdditionalItemsDataSource : OCDataSourceArray = OCDataSourceArray()

	public var emptyItemListDataSource : OCDataSourceArray = OCDataSourceArray()
	public var emptyItemListDecisionSubscription : OCDataSourceSubscription?
	public var emptyItemListItem : OCDataItemPresentable?
	public var emptySection: CollectionViewSection?

	public var loadingListItem : OCDataItemPresentable?
	public var emptySearchResultsItem: OCDataItemPresentable?

	private var stateObservation : NSKeyValueObservation?
	private var queryRootItemObservation : NSKeyValueObservation?

	public init(context inContext: ClientContext?, query inQuery: OCQuery, highlightItemReference: OCDataItemReference? = nil) {
		query = inQuery

		var sections : [ CollectionViewSection ] = []

		let itemControllerContext = ClientContext(with: inContext, modifier: { context in
			// Add permission handler limiting interactions for specific items and scenarios
			context.add(permissionHandler: { (context, record, interaction) in
				switch interaction {
					case .selection:
						if record?.type == .drive {
							// Do not react to taps on the drive header cells (=> or show image in the future)
							return false
						}

						return true

					case .multiselection:
						if record?.type == .item {
							// Only allow selection of items
							return true
						}

						return false

					case .drag:
						// Do not allow drags when in multi-selection mode
						return (context?.originatingViewController as? ClientItemViewController)?.isMultiSelecting == false

					case .contextMenu:
						// Do not allow context menus when in multi-selection mode
						return (context?.originatingViewController as? ClientItemViewController)?.isMultiSelecting == false

					default:
						return true
				}
			})
		})
		itemControllerContext.postInitializationModifier = { (owner, context) in
			if context.openItemHandler == nil {
				context.openItemHandler = owner as? OpenItemAction
			}
			if context.moreItemHandler == nil {
				context.moreItemHandler = owner as? MoreItemAction
			}
			if context.revealItemHandler == nil {
				context.revealItemHandler = owner as? RevealItemAction
			}
			if context.dropTargetsProvider == nil {
				context.dropTargetsProvider = owner as? DropTargetsProvider
			}

			context.query = (owner as? ClientItemViewController)?.query
			if let sortMethod = (owner as? ClientItemViewController)?.sortMethod,
			   let sortDirection = (owner as? ClientItemViewController)?.sortDirection {
				// Set default sort descriptor
				context.sortDescriptor = SortDescriptor(method: sortMethod, direction: sortDirection)
			}

			context.originatingViewController = owner as? UIViewController
		}

		if let queryResultsDatasource = query?.queryResultsDataSource, let core = itemControllerContext.core {
			itemsQueryDataSource = queryResultsDatasource
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
				driveSection = CollectionViewSection(identifier: "drive", dataSource: driveSectionDataSource, cellStyle: .init(with: .header), cellLayout: .list(appearance: .plain))
			}

			itemSectionDataSource = OCDataSourceComposition(sources: [itemsLeadInDataSource, queryResultsDatasource, itemsTrailingDataSource])
			itemSection = CollectionViewSection(identifier: "items", dataSource: itemSectionDataSource, cellLayout: .list(appearance: .plain, contentInsets: NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)), clientContext: itemControllerContext)

			if let driveSection = driveSection {
				sections.append(driveSection)
			}

			if let queryItemDataSourceSection = itemSection {
				sections.append(queryItemDataSourceSection)
			}
		}

		emptySection = CollectionViewSection(identifier: "empty", dataSource: emptyItemListDataSource, cellStyle: .init(with: .fillSpace), cellLayout: .fullWidth(itemHeightDimension: .estimated(54), groupHeightDimension: .estimated(54), edgeSpacing: NSCollectionLayoutEdgeSpacing(leading: .fixed(0), top: .fixed(10), trailing: .fixed(0), bottom: .fixed(10)), contentInsets: NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)), clientContext: itemControllerContext)
		sections.append(emptySection!)

		super.init(context: itemControllerContext, sections: sections, useStackViewRoot: true, highlightItemReference: highlightItemReference)

		// Track query state and recompute content state when it changes
		stateObservation = itemsQueryDataSource?.observe(\OCDataSource.state, options: [], changeHandler: { [weak self] query, change in
			self?.recomputeContentState()
		})

		queryRootItemObservation = query?.observe(\OCQuery.rootItem, options: [], changeHandler: { [weak self] query, change in
			OnMainThread(inline: true) {
				self?.clientContext?.rootItem = query.rootItem
			}
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

			loadingListItem = OCDataItemPresentable(reference: "_loadingListItem" as NSString, originalDataItemType: nil, version: nil)
			loadingListItem?.title = "Loading…".localized
			loadingListItem?.childrenDataSourceProvider = nil

			emptyItemListDecisionSubscription = queryDatasource.subscribe(updateHandler: { [weak self] (subscription) in
				self?.updateEmptyItemList(from: subscription)
			}, on: .main, trackDifferences: false, performIntialUpdate: true)
		}

		// Initialize sort method
		handleSortMethodChange()

		if let navigationTitle = query?.queryLocation?.isRoot == true ? clientContext?.drive?.name : query?.queryLocation?.lastPathComponent {
			navigationItem.title = navigationTitle
		}
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		stateObservation?.invalidate()
		queryRootItemObservation?.invalidate()
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

		// Add search button
		let searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(startSearch))
		viewActionButtons.append(searchButton)

		self.navigationItem.rightBarButtonItems = viewActionButtons

		// Setup sort bar
		sortBar = SortBar(sortMethod: sortMethod)
		sortBar?.translatesAutoresizingMaskIntoConstraints = false
		sortBar?.heightAnchor.constraint(equalToConstant: 40).isActive = true
		sortBar?.delegate = self
		sortBar?.sortMethod = sortMethod
		sortBar?.searchScope = searchScope
		sortBar?.showSelectButton = true

		itemsLeadInDataSource.setVersionedItems([ sortBar! ])

		// Setup multiselect
		collectionView.allowsSelectionDuringEditing = true
		collectionView.allowsMultipleSelectionDuringEditing = true
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
		guard let context = clientContext, let core = context.core, let item = context.query?.rootItem else {
			return nil
		}
		let locationIdentifier: OCExtensionLocationIdentifier = .emptyFolder
		let originatingViewController : UIViewController = context.originatingViewController ?? self
		let actionsLocation = OCExtensionLocation(ofType: .action, identifier: locationIdentifier)
		let actionContext = ActionContext(viewController: originatingViewController, core: core, query: context.query, items: [item], location: actionsLocation, sender: self)

		let emptyFolderActions = Action.sortedApplicableActions(for: actionContext)
		let actions = emptyFolderActions.map({ action in action.provideOCAction() })

		return (actions.count > 0) ? actions : nil
	}

	func updateEmptyItemList(from subscription: OCDataSourceSubscription) {
		recomputeContentState()
	}

	func recomputeContentState() {
		OnMainThread {
			switch self.itemsQueryDataSource?.state {
				case .loading:
					self.contentState = .loading

				case .idle:
					self.contentState = (self.emptyItemListDecisionSubscription?.snapshotResettingChangeTracking(true).numberOfItems == 0) ? .empty : .hasContent

				default: break
			}
		}
	}

	private var hadRootItem: Bool = false
	public var contentState : ContentState = .loading {
		didSet {
			let hasRootItem = (query?.rootItem != nil)

			if (contentState == oldValue) && (hadRootItem == hasRootItem) {
				return
			}

			hadRootItem = hasRootItem

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
					itemsLeadInDataSource.setVersionedItems([ ])

				case .loading:
					var loadingItems : [OCDataItem] = [ ]

					if let loadingListItem = loadingListItem {
						loadingItems.append(loadingListItem)
					}
					emptyItemListDataSource.setItems(loadingItems, updated: nil)
					itemsLeadInDataSource.setVersionedItems([ ])

				case .hasContent:
					emptyItemListDataSource.setItems(nil, updated: nil)
					if let sortBar = sortBar {
						itemsLeadInDataSource.setVersionedItems([ sortBar ])
					}
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

	// MARK: - Sorting
	open var sortBar: SortBar?
	open var sortMethod: SortMethod {
		set {
			UserDefaults.standard.setValue(newValue.rawValue, forKey: "sort-method")
			handleSortMethodChange()
		}

		get {
			let sort = SortMethod(rawValue: UserDefaults.standard.integer(forKey: "sort-method")) ?? SortMethod.alphabetically
			return sort
		}
	}
	open var searchScope: SortBarSearchScope = .local // only for SortBarDelegate protocol conformance
	open var sortDirection: SortDirection {
		set {
			UserDefaults.standard.setValue(newValue.rawValue, forKey: "sort-direction")
		}

		get {
			let direction = SortDirection(rawValue: UserDefaults.standard.integer(forKey: "sort-direction")) ?? SortDirection.ascendant
			return direction
		}
	}
	open func handleSortMethodChange() {
		let sortDescriptor = SortDescriptor(method: sortMethod, direction: sortDirection)

		clientContext?.sortDescriptor = sortDescriptor
		query?.sortComparator = sortDescriptor.comparator
	}

	public func sortBar(_ sortBar: SortBar, didUpdateSortMethod: SortMethod) {
 		sortMethod = didUpdateSortMethod

 		let comparator = sortMethod.comparator(direction: sortDirection)

 		query?.sortComparator = comparator
// 		customSearchQuery?.sortComparator = comparator
//
//		if (customSearchQuery?.queryResults?.count ?? 0) >= maxResultCount {
//	 		updateCustomSearchQuery()
//		}
	}

	public func sortBar(_ sortBar: SortBar, didUpdateSearchScope: SortBarSearchScope) {
		 // only for SortBarDelegate protocol conformance
	}

	public func sortBar(_ sortBar: SortBar, presentViewController: UIViewController, animated: Bool, completionHandler: (() -> Void)?) {
		self.present(presentViewController, animated: animated, completion: completionHandler)
	}

	// MARK: - Multiselect
	public func toggleSelectMode() {
		if let clientContext = clientContext, clientContext.hasPermission(for: .multiselection) {
			isMultiSelecting = !isMultiSelecting
		}
	}

	var multiSelectionActionContext: ActionContext?
	var multiSelectionActionsDatasource: OCDataSourceArray?

	public var isMultiSelecting : Bool = false {
		didSet {
			if oldValue != isMultiSelecting {
				collectionView.isEditing = isMultiSelecting

				if isMultiSelecting {
					// Setup new action context
					if let core = clientContext?.core {
						let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .multiSelection)

						multiSelectionActionContext = ActionContext(viewController: self, core: core, query: query, items: [OCItem](), location: actionsLocation)
					}

					// Setup multi selection action datasource
					multiSelectionActionsDatasource = OCDataSourceArray()
					refreshMultiselectActions()
					showActionsBar(with: multiSelectionActionsDatasource!)
				} else {
					closeActionsBar()
					multiSelectionActionsDatasource = nil
					multiSelectionActionContext = nil
				}
			}
		}
	}

	private var noActionsTextItem : OCDataItemPresentable?

	func refreshMultiselectActions() {
		if let multiSelectionActionContext = multiSelectionActionContext {
			var actionItems : [OCDataItem & OCDataItemVersioning] = []

			if multiSelectionActionContext.items.count == 0 {
				if noActionsTextItem == nil {
					noActionsTextItem = OCDataItemPresentable(reference: "_emptyActionList" as NSString, originalDataItemType: nil, version: nil)
					noActionsTextItem?.title = "Select one or more items.".localized
					noActionsTextItem?.childrenDataSourceProvider = nil
				}

				if let noActionsTextItem = noActionsTextItem {
					actionItems = [ noActionsTextItem ]
					OnMainThread {
						self.actionsBarViewControllerSection?.animateDifferences = true
					}
				}
			} else {
				let actions = Action.sortedApplicableActions(for: multiSelectionActionContext)
				let actionCompletionHandler : ActionCompletionHandler = { [weak self] action, error in
					OnMainThread {
						self?.isMultiSelecting = false
					}
				}

				for action in actions {
					action.completionHandler = actionCompletionHandler
					actionItems.append(action.provideOCAction(singleVersion: true))
				}
			}

			multiSelectionActionsDatasource?.setVersionedItems(actionItems)
		}
	}

	public override func handleMultiSelection(of record: OCDataItemRecord, at indexPath: IndexPath, isSelected: Bool) -> Bool {
		if !super.handleMultiSelection(of: record, at: indexPath, isSelected: isSelected),
		   let multiSelectionActionContext = multiSelectionActionContext {

			retrieveItem(at: indexPath, synchronous: true, action: { [weak self] record, indexPath in
				if record.type == .item, let item = record.item as? OCItem {
					if isSelected {
						multiSelectionActionContext.add(item: item)
					} else {
						multiSelectionActionContext.remove(item: item)
					}

					self?.refreshMultiselectActions()
				}
			})
		}

		return true
	}

	// MARK: - Drag & Drop
	public override func targetedDataItem(for indexPath: IndexPath?, interaction: ClientItemInteraction) -> OCDataItem? {
		var dataItem: OCDataItem? = super.targetedDataItem(for: indexPath, interaction: interaction)

		if interaction == .acceptDrop {
			if let indexPath = indexPath {
				if let section = section(at: indexPath.section) {
					if (section == emptySection) || (section == driveSection) || ((dataItem as? OCItem)?.type == .file), clientContext?.hasPermission(for: interaction) == true {
						// Return root item of view controller if a drop operation targets
						// - the empty section
						// - the drive (header) section
						// - a file
						// and drops are permitted
						dataItem = clientContext?.rootItem
					}
				}
			}
		}

		return dataItem
	}

	// MARK: Drop Targets
	var dropTargetsActionContext: ActionContext?

	public func canProvideDropTargets(for dropSession: UIDropSession, target: UIView) -> Bool {
		for item in dropSession.items {
			if item.localObject == nil, item.itemProvider.hasItemConformingToTypeIdentifier("public.folder") {
				// folders can't be imported from other apps
				return false
			} else if let localDataItem = item.localObject as? LocalDataItem,
				  clientContext?.core?.bookmark.uuid != localDataItem.bookmarkUUID,
				  (localDataItem.dataItem as? OCItem)?.type == .collection {
				// folders from other accounts can't be dropped
				return false
			}
		}

		if dropSession.localDragSession != nil {
			if provideDropItems(from: dropSession, target: target).count == 0 {
				return false
			}
		}

		return true
	}

	public func provideDropItems(from dropSession: UIDropSession, target view: UIView) -> [OCItem] {
		var items : [OCItem] = []
		var allItemsFromSameAccount = true

		if let bookmarkUUID = clientContext?.core?.bookmark.uuid {
			for dragItem in dropSession.items {
				if let localDataItem = dragItem.localObject as? LocalDataItem {
					if localDataItem.bookmarkUUID != bookmarkUUID {
						allItemsFromSameAccount = false
						break
					} else {
						if let item = localDataItem.dataItem as? OCItem {
							items.append(item)
						}
					}
				} else {
					allItemsFromSameAccount = false
					break
				}
			}
		}

		if !allItemsFromSameAccount {
			items.removeAll()
		}

		return items
	}

	public func provideDropTargets(for dropSession: UIDropSession, target view: UIView) -> [OCDataItem & OCDataItemVersioning]? {
		let items = provideDropItems(from: dropSession, target: view)

		if items.count > 0, let core = clientContext?.core {
			dropTargetsActionContext = ActionContext(viewController: self, core: core, items: items, location: OCExtensionLocation(ofType: .action, identifier: .dropAction))

			if let dropTargetsActionContext = dropTargetsActionContext {
				let actions = Action.sortedApplicableActions(for: dropTargetsActionContext)

				return actions.map { action in action.provideOCAction(singleVersion: true) }
			}
		}

		return nil
	}

	public func cleanupDropTargets(for dropSession: UIDropSession, target view: UIView) {
		dropTargetsActionContext = nil
	}

	// MARK: - Reveal
	public func reveal(item: OCDataItem, context: ClientContext, sender: AnyObject?) -> Bool {
		if let revealInteraction = item as? DataItemSelectionInteraction {
			if revealInteraction.revealItem?(from: self, with: clientContext, animated: true, pushViewController: true, completion: nil) != nil {
				return true
			}
		}
		return false
	}

	// MARK: - Search
	open var searchController: UISearchController?
	var searchViewController: SearchViewController?

	@objc open func startSearch() {
		if searchViewController == nil {
			if let clientContext = clientContext, let cellStyle = itemSection?.cellStyle {
				var scopes : [SearchScope] = [
					// In this folder
					.modifyingQuery(with: clientContext, localizedName: "Folder".localized)

					// + Folder and subfolders
				]

				// Drive
				if clientContext.core?.useDrives == true {
					let driveName = clientContext.drive?.name ?? "Drive".localized
					scopes.append(.driveSearch(with: clientContext, cellStyle: cellStyle, localizedName: driveName))
				}

				// Account
				scopes.append(.accountSearch(with: clientContext, cellStyle: cellStyle, localizedName: "Account".localized))

				searchViewController = SearchViewController(with: clientContext, scopes: scopes, delegate: self)

				if let searchViewController = searchViewController {
					self.addStacked(child: searchViewController, position: .top)
				}
			}
		}
	}

	func endSearch() {
		if let searchViewController = searchViewController {
			self.removeStacked(child: searchViewController)
		}
		searchResultsDataSource = nil
		searchViewController = nil
	}

	// MARK: - SearchViewControllerDelegate
	var searchResultsDataSource: OCDataSource? {
		willSet {
			if let oldDataSource = searchResultsDataSource, let itemsQueryDataSource = itemsQueryDataSource, oldDataSource != itemsQueryDataSource {
				itemSectionDataSource?.removeSources([ oldDataSource ])
				itemSectionDataSource?.setInclude(true, for: itemsQueryDataSource)
			}
		}

		didSet {
			if let newDataSource = searchResultsDataSource, let itemsQueryDataSource = itemsQueryDataSource, newDataSource != itemsQueryDataSource {
				itemSectionDataSource?.setInclude(false, for: itemsQueryDataSource)
				itemSectionDataSource?.insertSources([ newDataSource ], after: itemsQueryDataSource)
			}
		}
	}

	private var preSearchCellStyle : CollectionViewCellStyle?

	public func searchBegan(for viewController: SearchViewController) {
		preSearchCellStyle = itemSection?.cellStyle

		updateSections(with: { sections in
			self.driveSection?.hidden = true
		}, animated: true)
	}

	public func search(for viewController: SearchViewController, withResults resultsDataSource: OCDataSource?, style: CollectionViewCellStyle?) {
		if searchResultsDataSource != resultsDataSource {
			searchResultsDataSource = resultsDataSource
		}

		if let style = style ?? preSearchCellStyle, style != itemSection?.cellStyle {
			itemSection?.cellStyle = style
		}
	}

	public func searchEnded(for viewController: SearchViewController) {
		updateSections(with: { sections in
			self.driveSection?.hidden = false
		}, animated: true)

		if let preSearchCellStyle = preSearchCellStyle {
			itemSection?.cellStyle = preSearchCellStyle
		}

		endSearch()
	}
}
