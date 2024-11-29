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

open class ClientItemViewController: CollectionViewController, SortBarDelegate, DropTargetsProvider, SearchViewControllerDelegate, RevealItemAction, SearchViewControllerHost {
	public enum ContentState : String, CaseIterable {
		case loading

		case empty
		case removed
		case hasContent

		case searchNonItemContent
	}

	public var query: OCQuery?
	private var _itemsDatasource: OCDataSource? // stores the data source passed to init (if any)

	public var itemsListDataSource: OCDataSource? // typically query.queryResultsDataSource or .itemsDatasource
	public var itemSectionDataSource: OCDataSourceComposition?
	public var itemSection: CollectionViewSection?

	public var footerSectionDataSource: OCDataSourceArray = OCDataSourceArray()
	public var footerSection: CollectionViewSection?

	public var driveSection: CollectionViewSection?

	public var driveSectionDataSource: OCDataSourceComposition?
	public var singleDriveDatasource: OCDataSourceComposition?
	private var singleDriveDatasourceSubscription: OCDataSourceSubscription?
	public var driveAdditionalItemsDataSource: OCDataSourceArray = OCDataSourceArray()

	public var emptyItemListDataSource: OCDataSourceArray = OCDataSourceArray()
	public var emptyItemListDecisionSubscription: OCDataSourceSubscription?
	public var emptyItemListItem: ComposedMessageView?
	public var emptySectionDataSource: OCDataSourceComposition?
	public var emptySection: CollectionViewSection?

	public var loadingListItem: ComposedMessageView?
	public var folderRemovedListItem: ComposedMessageView?
	public var footerItem: UIView?
	public var footerFolderStatisticsLabel: ThemeCSSLabel?

	public var location: OCLocation?

	private var stateObservation: NSKeyValueObservation?
	private var queryStateObservation: NSKeyValueObservation?
	private var queryRootItemObservation: NSKeyValueObservation?

	private var viewControllerUUID: UUID

	private var coreConnectionStatusObservation : NSKeyValueObservation?

	private var refreshControl: UIRefreshControl?

	public init(context inContext: ClientContext?, query inQuery: OCQuery?, itemsDatasource inDataSource: OCDataSource? = nil, location: OCLocation? = nil, highlightItemReference: OCDataItemReference? = nil, showRevealButtonForItems: Bool = false, emptyItemListIcon: UIImage? = nil, emptyItemListTitleLocalized: String? = nil, emptyItemListMessageLocalized: String? = nil) {
		inQuery?.queryResultsDataSourceIncludesStatistics = true
		query = inQuery
		_itemsDatasource = inDataSource

		self.location = location

		var sections : [ CollectionViewSection ] = []

		let vcUUID = UUID()
		viewControllerUUID = vcUUID

		sortDescriptor = inContext?.sortDescriptor ?? .defaultSortDescriptor

		let itemControllerContext = ClientContext(with: inContext, modifier: { context in
			// Add permission handler limiting interactions for specific items and scenarios
			context.add(permissionHandler: { (context, record, interaction, viewController) in
				guard  let viewController = viewController as? ClientItemViewController, viewController.viewControllerUUID == vcUUID else {
					// Only apply this permission handler to this view controller, otherwise -> just pass through
					return true
				}

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

			// Set .drive based on location.driveID
			if let driveID = location?.driveID, let core = context.core {
				context.drive = core.drive(withIdentifier: driveID, attachedOnly: false)
			}

			// Use inDataSource as queryDatasource if no query was provided
			if inQuery == nil, let inDataSource {
				context.queryDatasource = inDataSource
			}
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
			if let sortDescriptor = (owner as? ClientItemViewController)?.sortDescriptor {
				context.sortDescriptor = sortDescriptor
			}

			context.originatingViewController = owner as? UIViewController
		}

		if let contentsDataSource = query?.queryResultsDataSource ?? _itemsDatasource, let core = itemControllerContext.core {
			itemsListDataSource = contentsDataSource

			if query?.queryLocation?.isRoot == true, core.useDrives {
				// Create data source from one drive
				singleDriveDatasource = OCDataSourceComposition(sources: [core.drivesDataSource])
				singleDriveDatasource?.filter = OCDataSourceComposition.itemFilter(withItemRetrieval: false, fromRecordFilter: { itemRecord in
					if let drive = itemRecord?.item as? OCDrive,
					   drive.identifier == itemControllerContext.drive?.identifier {
						return true
					}

					return false
				})

				if itemControllerContext.drive?.specialType == .space { // limit to spaces, do not show header for f.ex. the personal space or the Shares Jail space
					// Create combined data source from drive + additional items
					driveSectionDataSource = OCDataSourceComposition(sources: [ singleDriveDatasource!, driveAdditionalItemsDataSource ])

					// Create drive section from combined data source
					driveSection = CollectionViewSection(identifier: "drive", dataSource: driveSectionDataSource, cellStyle: .init(with: .header), cellLayout: .list(appearance: .plain))
				}
			}

			itemSectionDataSource = OCDataSourceComposition(sources: [contentsDataSource])

			let itemLayout = itemControllerContext.itemLayout ?? .list
			let itemSectionCellStyle = CollectionViewCellStyle(from: itemLayout.cellStyle, changing: { cellStyle in
				if showRevealButtonForItems {
					cellStyle.showRevealButton = true
				}
			})

			itemSection = CollectionViewSection(identifier: "items", dataSource: itemSectionDataSource, cellStyle: itemSectionCellStyle, cellLayout: itemLayout.sectionCellLayout(for: .current), clientContext: itemControllerContext)

			footerSection = CollectionViewSection(identifier: "items-footer", dataSource: footerSectionDataSource, cellStyle: ItemLayout.list.cellStyle, cellLayout: ItemLayout.list.sectionCellLayout(for: .current), clientContext: itemControllerContext)

			if let driveSection {
				sections.append(driveSection)
			}

			if let itemSection {
				sections.append(itemSection)
			}

			if let footerSection {
				sections.append(footerSection)
			}
		}

		emptySectionDataSource = OCDataSourceComposition(sources: [ emptyItemListDataSource ])

		emptySection = CollectionViewSection(identifier: "empty", dataSource: emptySectionDataSource, cellStyle: .init(with: .fillSpace), cellLayout: .fullWidth(itemHeightDimension: .estimated(54), groupHeightDimension: .estimated(54), edgeSpacing: NSCollectionLayoutEdgeSpacing(leading: .fixed(0), top: .fixed(10), trailing: .fixed(0), bottom: .fixed(10)), contentInsets: NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)), clientContext: itemControllerContext)
		sections.append(emptySection!)

		super.init(context: itemControllerContext, sections: sections, useStackViewRoot: true, compressForKeyboard: true, highlightItemReference: highlightItemReference)

		// Track query state and recompute content state when it changes
		stateObservation = itemsListDataSource?.observe(\OCDataSource.state, options: [], changeHandler: { [weak self] query, change in
			self?.recomputeContentState()
		})

		queryStateObservation = query?.observe(\OCQuery.state, options: [], changeHandler: { [weak self] query, change in
			if query.state == .idle || self?.clientContext?.core?.connectionStatus != .online {
				OnMainThread {
					if self?.refreshControl?.isRefreshing == true {
						self?.refreshControl?.endRefreshing()
					}
				}
			}

			self?.recomputeContentState()
		})

		queryRootItemObservation = query?.observe(\OCQuery.rootItem, options: [], changeHandler: { [weak self] query, change in
			OnMainThread(inline: true) {
				self?.clientContext?.rootItem = query.rootItem
				if self?.location != nil {
					self?.location = query.rootItem?.location
					self?.updateLocationBarViewController()
				}
				self?.updateNavigationTitleFromContext()
				self?.refreshEmptyActions()
			}
			self?.recomputeContentState()
		})

		// Subscribe to singleDriveDatasource for changes, to update driveSectionDataSource
		singleDriveDatasourceSubscription = singleDriveDatasource?.subscribe(updateHandler: { [weak self] (subscription) in
			self?.updateAdditionalDriveItems(from: subscription)
		}, on: .main, trackDifferences: true, performInitialUpdate: true)

		if let queryDatasource = query?.queryResultsDataSource ?? inDataSource {
			let emptyFolderMessage = emptyItemListMessageLocalized ?? OCLocalizedString("This folder is empty.", nil) // OCLocalizedString("This folder is empty. Fill it with content:", nil)

			emptyItemListItem = ComposedMessageView(elements: [
				.image(emptyItemListIcon ?? OCSymbol.icon(forSymbolName: "folder.fill")!, size: CGSize(width: 64, height: 48), alignment: .centered),
				.title(emptyItemListTitleLocalized ?? OCLocalizedString("No contents", nil), alignment: .centered),
				.spacing(5),
				.subtitle(emptyFolderMessage, alignment: .centered)
			])

			emptyItemListItem?.elementInsets = NSDirectionalEdgeInsets(top: 20, leading: 0, bottom: 2, trailing: 0)
			emptyItemListItem?.backgroundView = nil

			let indeterminateProgress: Progress = .indeterminate()
			indeterminateProgress.isCancellable = false

			loadingListItem = ComposedMessageView(elements: [
				.spacing(25),
				.progressCircle(with: indeterminateProgress),
				.spacing(25),
				.title(OCLocalizedString("Loading…", nil), alignment: .centered)
			])

			folderRemovedListItem = ComposedMessageView(elements: [
				.image(OCSymbol.icon(forSymbolName: "nosign")!, size: CGSize(width: 64, height: 48), alignment: .centered),
				.title(OCLocalizedString("Folder removed", nil), alignment: .centered),
				.spacing(5),
				.subtitle(OCLocalizedString("This folder no longer exists on the server.", nil), alignment: .centered)
			])

			footerItem = UIView()
			footerItem?.translatesAutoresizingMaskIntoConstraints = false

			footerFolderStatisticsLabel = ThemeCSSLabel(withSelectors: [.sectionFooter, .statistics])
			footerFolderStatisticsLabel?.translatesAutoresizingMaskIntoConstraints = false
			footerFolderStatisticsLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
			footerFolderStatisticsLabel?.textAlignment = .center
			footerFolderStatisticsLabel?.setContentHuggingPriority(.required, for: .vertical)
			footerFolderStatisticsLabel?.setContentCompressionResistancePriority(.required, for: .vertical)
			footerFolderStatisticsLabel?.numberOfLines = 0
			footerFolderStatisticsLabel?.text = "-"

			footerItem?.embed(toFillWith: footerFolderStatisticsLabel!, insets: NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
			footerItem?.separatorLayoutGuideCustomizer = SeparatorLayoutGuideCustomizer(with: { viewCell, view in
				return [ viewCell.separatorLayoutGuide.leadingAnchor.constraint(equalTo: viewCell.contentView.trailingAnchor) ]
			})
			footerItem?.accessibilityRespondsToUserInteraction = false
			footerItem?.layoutIfNeeded()

			emptyItemListDecisionSubscription = queryDatasource.subscribe(updateHandler: { [weak self] (subscription) in
				self?.updateEmptyItemList(from: subscription)
			}, on: .main, trackDifferences: false, performInitialUpdate: true)
		}

		// Initialize sort method
		applySortDescriptor()

		// Update title
		updateNavigationTitleFromContext()

		// Observe connection status
		if let core = itemControllerContext.core {
			coreConnectionStatusObservation = core.observe(\OCCore.connectionStatus, options: .initial) { [weak self, weak core] (_, _) in
				OnMainThread { [weak self, weak core] in
					if let connectionStatus = core?.connectionStatus {
						self?.coreConnectionStatus = connectionStatus
					}
				}
			}
		}
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		stateObservation?.invalidate()
		queryRootItemObservation?.invalidate()
		queryStateObservation?.invalidate()
		singleDriveDatasourceSubscription?.terminate()
	}

	public override func viewDidLoad() {
		super.viewDidLoad()

		// Add navigation bar button items
		updateNavigationBarButtonItems()

		// Setup sort bar
		sortBar = SortBar(sortDescriptor: sortDescriptor)
		sortBar?.translatesAutoresizingMaskIntoConstraints = false
		sortBar?.delegate = self
		sortBar?.itemLayout = clientContext?.itemLayout ?? .list
		sortBar?.showSelectButton = true

		if let sortBar {
			itemSection?.boundarySupplementaryItems = [
				.view(sortBar, pinned: true)
			]
		}

		// Setup multiselect
		collectionView.allowsSelectionDuringEditing = true
		collectionView.allowsMultipleSelectionDuringEditing = true

		// Implement drag to refresh
		if supportsDragToRefresh {
			refreshControl = UIRefreshControl(frame: .zero, primaryAction: UIAction(handler: { [weak self] _ in
				self?.performDragToRefresh()
			}))

			collectionView.refreshControl = refreshControl
		}
	}

	var locationBarViewController: ClientLocationBarController? {
		willSet {
			if let locationBarViewController {
				removeStacked(child: locationBarViewController)
			}
		}
		didSet {
			if let locationBarViewController {
				addStacked(child: locationBarViewController, position: .bottom)
			}
		}
	}

	public override func addStacked(child viewController: UIViewController, position: CollectionViewController.StackedPosition, relativeTo: UIView? = nil) {
		var relativeToView = relativeTo
		var stackedPosition = position

		if viewController == actionsBarViewController, let locationBarView = locationBarViewController?.view {
			stackedPosition = .top
			relativeToView = locationBarView
		}

		super.addStacked(child: viewController, position: stackedPosition, relativeTo: relativeToView)
	}

	func updateLocationBarViewController() {
		if let location, let clientContext {
			self.locationBarViewController = ClientLocationBarController(clientContext: clientContext, location: location)
		} else {
			self.locationBarViewController = nil
		}
	}

	public override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if let query {
			clientContext?.core?.start(query)
		}

		if locationBarViewController == nil {
			updateLocationBarViewController()
		}
	}

	open override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		if let query {
			clientContext?.core?.stop(query)
		}
	}

	public func updateAdditionalDriveItems(from subscription: OCDataSourceSubscription) {
		let snapshot = subscription.snapshotResettingChangeTracking(true)

		guard let core = clientContext?.core,
		      let firstItemRef = snapshot.items.first,
		      let itemRecord = try? subscription.source?.record(forItemRef: firstItemRef),
		      let drive = itemRecord.item as? OCDrive else { return }

		driveQuota = drive.quota

		guard drive.specialType == .space else { return } // limit to spaces, do not show header for f.ex. the personal space or the Shares Jail space

		if let driveRepresentation = OCDataRenderer.default.renderItem(drive, asType: .presentable, error: nil) as? OCDataItemPresentable,
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

	// MARK: - Connection status
	var coreConnectionStatus: OCCoreConnectionStatus? {
		didSet {
			if coreConnectionStatus != oldValue {
				recomputeContentState()
			}
		}
	}

	// MARK: - Empty item list handling
	func emptyActions() -> [OCAction]? {
		guard let context = clientContext, let core = context.core, let item = context.query?.rootItem ?? (context.rootItem as? OCItem), clientContext?.hasPermission(for: .addContent) == true else {
			return nil
		}
		let locationIdentifier: OCExtensionLocationIdentifier = .emptyFolder
		let originatingViewController : UIViewController = context.originatingViewController ?? self
		let actionsLocation = OCExtensionLocation(ofType: .action, identifier: locationIdentifier)
		let actionContext = ActionContext(viewController: originatingViewController, clientContext: clientContext, core: core, query: context.query, items: [item], location: actionsLocation, sender: self)

		let emptyFolderActions = Action.sortedApplicableActions(for: actionContext)
		let actions = emptyFolderActions.map({ action in action.provideOCAction() })

		return (actions.count > 0) ? actions : nil
	}

	func updateEmptyItemList(from subscription: OCDataSourceSubscription) {
		recomputeContentState()
	}

	func recomputeContentState() {
		OnMainThread {
			if self.searchActive == true {
				// Search is active, adapt state to either results (.hasContent) or noResults/suggestions (.searchNonItemContent)
				if let searchResultsContent = self.searchResultsContent {
					if searchResultsContent.type != .results {
						self.contentState = .searchNonItemContent
					} else {
						self.contentState = .hasContent
					}
				} else {
					self.contentState = .searchNonItemContent
				}
			} else {
				// Regular usage, use itemsQueryDataSource to determine state
				switch self.itemsListDataSource?.state {
					case .loading:
						self.contentState = .loading

					case .idle:
						let snapshot = self.emptyItemListDecisionSubscription?.snapshotResettingChangeTracking(true)
						let numberOfItems = snapshot?.numberOfItems

						if self.query?.state == .targetRemoved {
							self.contentState = .removed
						} else if let numberOfItems, numberOfItems > 0 {
							self.contentState = .hasContent
							self.folderStatistics = snapshot?.specialItems?[.folderStatistics] as? OCStatistic
						} else if (numberOfItems == nil) ||
						          ((self.query != nil) && (self.query?.rootItem == nil) && (self.query?.isCustom != true)) ||
						          ((self.query != nil) && (self.query?.state == .started)) ||
						          ((self.query != nil) && (self.query?.state == .waitingForServerReply) && self.clientContext?.core?.connectionStatus == .online) {
							self.contentState = .loading
						} else {
							self.contentState = .empty
						}

					default: break
				}
			}
		}
	}

	private var hadRootItem: Bool = false
	private var hadSearchActive: Bool?
	public var contentState : ContentState = .loading {
		didSet {
			let hasRootItem = (query?.rootItem != nil)
			let itemSectionHidden = itemSection?.hidden
			var itemSectionHiddenNew = false
			let emptySectionHidden = emptySection?.hidden
			var emptySectionHiddenNew = false
			let changeFromOrToRemoved = ((contentState == .removed) || (oldValue == .removed)) && (oldValue != contentState)

			if (contentState == oldValue) && (hadRootItem == hasRootItem) && (hadSearchActive == searchActive) {
				return
			}

			hadRootItem = hasRootItem
			hadSearchActive = searchActive

			switch contentState {
				case .empty:
					refreshEmptyActions()
					sortBar?.isHidden = true
					footerSectionDataSource.setVersionedItems([ ])

				case .loading:
					var loadingItems : [OCDataItem] = [ ]

					if let loadingListItem = loadingListItem {
						loadingItems.append(loadingListItem)
					}
					emptyItemListDataSource.setItems(loadingItems, updated: nil)
					sortBar?.isHidden = true
					footerSectionDataSource.setVersionedItems([ ])

				case .removed:
					var folderRemovedItems : [OCDataItem] = [ ]

					if let folderRemovedListItem = folderRemovedListItem {
						folderRemovedItems.append(folderRemovedListItem)
					}
					emptyItemListDataSource.setItems(folderRemovedItems, updated: nil)
					sortBar?.isHidden = true
					footerSectionDataSource.setVersionedItems([ ])

				case .hasContent:
					emptyItemListDataSource.setItems(nil, updated: nil)
					sortBar?.isHidden = false

					if searchActive == true {
						footerSectionDataSource.setVersionedItems([ ])
					} else {
						if let footerItem {
							footerSectionDataSource.setVersionedItems([ footerItem ])
						}
					}

					emptySectionHiddenNew = true

				case .searchNonItemContent:
					emptyItemListDataSource.setItems(nil, updated: nil)
					sortBar?.isHidden = true
					footerSectionDataSource.setVersionedItems([ ])
					itemSectionHiddenNew = true
			}

			if changeFromOrToRemoved {
				updateNavigationBarButtonItems()
			}

			if (itemSectionHidden != itemSectionHiddenNew) || (emptySectionHidden != emptySectionHiddenNew) {
				updateSections(with: { sections in
					self.itemSection?.hidden = itemSectionHiddenNew
					self.emptySection?.hidden = emptySectionHiddenNew
				}, animated: false)
			}
		}
	}

	// MARK: - Navigation Bar
	open func updateNavigationBarButtonItems() {
		var rightInset : CGFloat = 2
		var leftInset : CGFloat = 0
		if self.view.effectiveUserInterfaceLayoutDirection == .rightToLeft {
			rightInset = 0
			leftInset = 2
		}

		var viewActionButtons : [UIBarButtonItem] = []

		if contentState != .removed {
			if query?.queryLocation != nil {
				// More menu for folder
				if clientContext?.moreItemHandler != nil, clientContext?.hasPermission(for: .moreOptions) == true {
					let folderActionBarButton = UIBarButtonItem(image: UIImage(named: "more-dots")?.withInset(UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)), style: .plain, target: self, action: #selector(moreBarButtonPressed))
					folderActionBarButton.accessibilityIdentifier = "client.folder-action"
					folderActionBarButton.accessibilityLabel = OCLocalizedString("Actions", nil)

					viewActionButtons.append(folderActionBarButton)
				}

				// Plus button for folder
				if clientContext?.hasPermission(for: .addContent) == true {
					let plusBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
					plusBarButton.menu = UIMenu(title: "", children: [
						UIDeferredMenuElement.uncached({ [weak self] completion in
							if let self = self, let rootItem = self.query?.rootItem, let clientContext = self.clientContext {
								let contextMenuProvider = rootItem as DataItemContextMenuInteraction

								if let contextMenuElements = contextMenuProvider.composeContextMenuItems(in: self, location: .folderAction, with: clientContext) {
									if contextMenuElements.count == 0 {
										completion([UIAction(title: OCLocalizedString("No actions available", nil), image: nil, attributes: .disabled, handler: {_ in })])
									} else {
										completion(contextMenuElements)
									}
								}
							}
						})
					])
					plusBarButton.accessibilityIdentifier = "client.file-add"
					plusBarButton.accessibilityLabel = OCLocalizedString("Add item", nil)

					viewActionButtons.append(plusBarButton)
				}

				// Add search button
				if clientContext?.hasPermission(for: .search) == true {
					let searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(startSearch))
					searchButton.accessibilityIdentifier = "client.search"
					searchButton.accessibilityLabel = OCLocalizedString("Search", nil)
					viewActionButtons.append(searchButton)
				}
			}
		}

		navigationItem.navigationContent.add(items: [
			NavigationContentItem(identifier: "client-actions-right", area: .right, priority: .standard, position: .trailing, items: viewActionButtons)
		])
	}

	@objc open func moreBarButtonPressed(_ sender: UIBarButtonItem) {
		guard let rootItem = query?.rootItem else {
			return
		}

		if let moreItemHandler = clientContext?.moreItemHandler, let clientContext = clientContext {
			moreItemHandler.moreOptions(for: rootItem, at: .moreFolder, context: clientContext, sender: sender)
		}
	}

	// MARK: - Navigation title
	var navigationTitle: String? {
		get {
			return navigationItem.titleLabel?.text
		}

		set {
			navigationItem.navigationContent.remove(itemsWithIdentifier: "navigation-location")
			navigationItem.titleLabelText = newValue
			navigationItem.title = newValue
		}
	}

	var useNavigationLocationBreadcrumbDropdown: Bool {
		return UIDevice.current.userInterfaceIdiom == .pad
	}

	var navigationLocation: OCLocation? {
		didSet {
			if let clientContext, let navigationLocation, !navigationLocation.isRoot {
				navigationItem.navigationContent.add(items: [NavigationContentItem(identifier: "navigation-location", area: .title, priority: .standard, position: .leading, titleView:
					ClientLocationPopupButton(clientContext: clientContext, location: navigationLocation)
				)])
			} else {
				navigationItem.navigationContent.remove(itemsWithIdentifier: "navigation-location")
			}
		}
	}

	func updateNavigationTitleFromContext() {
		var navigationTitle: String?
		var navigationLocation: OCLocation?

		// Set navigation title from location (if provided)
		if let location {
			navigationTitle = location.displayName(in: clientContext)
			navigationLocation = location
		}

		// Set navigation title from queryLocation
		if navigationTitle == nil, let queryLocation = query?.queryLocation {
			navigationTitle = queryLocation.displayName(in: clientContext)
			navigationLocation = queryLocation
		}

		// Set navigation title from rootItem.name
		if navigationTitle == nil, let queryRootItem = self.clientContext?.rootItem as? OCItem {
			navigationTitle = queryRootItem.name
			navigationLocation = queryRootItem.location
		}

		// Compose navigation title
		if useNavigationLocationBreadcrumbDropdown {
			self.navigationLocation = navigationLocation
		}

		if navigationLocation == nil || !useNavigationLocationBreadcrumbDropdown || navigationLocation?.isRoot == true {
			if let navigationTitle {
				self.navigationTitle = navigationTitle.redacted()
			} else {
				self.navigationTitle = navigationItem.title?.redacted()
			}
		}
	}

	// MARK: - Sorting
	open var sortBar: SortBar?
	open var sortDescriptor: SortDescriptor

	public func sortBar(_ sortBar: SortBar, didChangeSortDescriptor newSortDescriptor: SortDescriptor) {
		sortDescriptor = newSortDescriptor

		clientContext?.sortDescriptor = newSortDescriptor
		itemSection?.clientContext?.sortDescriptor = newSortDescriptor // Also needs to change the sortDescriptor for the itemSection's clientContext, since that is what will be used when creating ClientItemViewControllers for subfolders, etc.

		SortDescriptor.defaultSortDescriptor = newSortDescriptor // Change default ONLY for user-initiated changes

		applySortDescriptor()
	}

	open func applySortDescriptor() {
		query?.sortComparator = sortDescriptor.comparator
	}

	public func sortBar(_ sortBar: SortBar, itemLayout: ItemLayout) {
		if itemLayout != clientContext?.itemLayout {
			clientContext?.itemLayout = itemLayout

			itemSection?.clientContext?.itemLayout = itemLayout
			itemSection?.adopt(itemLayout: itemLayout)
		}
	}

	// MARK: - Multiselect
	public func sortBarToggleSelectMode(_ sortBar: SortBar) {
		if let clientContext = clientContext, clientContext.hasPermission(for: .multiselection) {
			isMultiSelecting = !isMultiSelecting
		}
	}

	var multiSelectionActionContext: ActionContext?
	var multiSelectionActionsDatasource: OCDataSourceArray?

	var multiSelectionToggleSelectionBarButtonItem: UIBarButtonItem? {
		didSet {
			if let multiSelectionToggleSelectionBarButtonItem {
				navigationItem.navigationContent.add(items: [
					NavigationContentItem(identifier: "multiselect-toggle", area: .left, priority: .high, position: .trailing, items: [ multiSelectionToggleSelectionBarButtonItem ])
				])
			} else {
				navigationItem.navigationContent.remove(itemsWithIdentifier: "multiselect-toggle")
			}
		}
	}

	public var isMultiSelecting : Bool = false {
		didSet {
			if oldValue != isMultiSelecting {
				collectionView.isEditing = isMultiSelecting
				sortBar?.multiselectActive = isMultiSelecting

				if isMultiSelecting {
					// Setup new action context
					if let core = clientContext?.core {
						let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .multiSelection)
						multiSelectionActionContext = ActionContext(viewController: self, clientContext: clientContext, core: core, query: query, items: [OCItem](), location: actionsLocation)
					}

					// Setup select all / deselect all in navigation item
					multiSelectionToggleSelectionBarButtonItem = UIBarButtonItem(title: OCLocalizedString("Select All", nil), primaryAction: UIAction(handler: { [weak self] action in
						self?.selectDeselectAll()
					}))

					// Setup multi selection action datasource
					multiSelectionActionsDatasource = OCDataSourceArray()
					refreshMultiselectActions()
					showActionsBar(with: multiSelectionActionsDatasource!)
				} else {
					// Restore navigation item
					closeActionsBar()
					multiSelectionToggleSelectionBarButtonItem = nil
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
					noActionsTextItem?.title = OCLocalizedString("Select one or more items.", nil)
					noActionsTextItem?.childrenDataSourceProvider = nil
				}

				if let noActionsTextItem = noActionsTextItem {
					actionItems = [ noActionsTextItem ]
					OnMainThread {
						self.actionsBarViewControllerSection?.animateDifferences = true
					}
				}

				multiSelectionToggleSelectionBarButtonItem?.title = OCLocalizedString("Select All", nil)
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

				multiSelectionToggleSelectionBarButtonItem?.title = OCLocalizedString("Deselect All", nil)
			}

			multiSelectionActionsDatasource?.setVersionedItems(actionItems)
		}
	}

	public override func handleMultiSelection(of record: OCDataItemRecord, at indexPath: IndexPath, isSelected: Bool, clientContext: ClientContext) -> Bool {
		if !super.handleMultiSelection(of: record, at: indexPath, isSelected: isSelected, clientContext: clientContext),
		   let multiSelectionActionContext = multiSelectionActionContext {
			retrieveItem(at: indexPath, synchronous: true, action: { [weak self] record, indexPath, _ in
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

	func itemRefs(for items: [OCItem]) -> [ItemRef] {
		return items.map { item in
			return item.dataItemReference
		}
	}

	private var selectAllSubscription: OCDataSourceSubscription?

	open func selectDeselectAll() {
		if let selectedItems = multiSelectionActionContext?.items, selectedItems.count > 0 {
			// Deselect all
			let selectedIndexPaths = retrieveIndexPaths(for: itemRefs(for: selectedItems))

			for indexPath in selectedIndexPaths {
				collectionView.deselectItem(at: indexPath, animated: false)
				self.collectionView(collectionView, didDeselectItemAt: indexPath)
			}
		} else {
			// Select all
			selectAllSubscription = itemsListDataSource?.subscribe(updateHandler: { (subscription) in
				let snapshot = subscription.snapshotResettingChangeTracking(true)
				let selectIndexPaths = self.retrieveIndexPaths(for: snapshot.items)

				for indexPath in selectIndexPaths {
					self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
					self.collectionView(self.collectionView, didSelectItemAt: indexPath)
				}

				subscription.terminate()
				self.selectAllSubscription = nil
			}, on: .main, trackDifferences: false, performInitialUpdate: true)
		}
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
			dropTargetsActionContext = ActionContext(viewController: self, clientContext: clientContext, core: core, items: items, location: OCExtensionLocation(ofType: .action, identifier: .dropAction))

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
			if revealInteraction.revealItem?(from: self, with: context, animated: true, pushViewController: true, completion: nil) != nil {
				return true
			}
		}
		return false
	}

	// MARK: - Search
	open var searchViewController: SearchViewController?

	open func searchScopes(for clientContext: ClientContext, cellStyle: CollectionViewCellStyle) -> ([SearchScope], SearchScope?) {
		return SearchScope.availableScopes(for: clientContext, cellStyle: cellStyle)
	}

	@objc open func startSearch() {
		if searchViewController == nil {
			if let clientContext = clientContext, let cellStyle = itemSection?.cellStyle {
				// Scopes
				let (scopes, defaultScope) = searchScopes(for: clientContext, cellStyle: cellStyle)

				// No results
				let noResultContent = SearchViewController.Content(type: .noResults, source: OCDataSourceArray(), style: emptySection!.cellStyle)
				let noResultsView = ComposedMessageView.infoBox(image: OCSymbol.icon(forSymbolName: "magnifyingglass"), title: OCLocalizedString("No matches", nil), subtitle: OCLocalizedString("The search term you entered did not match any item in the selected scope.", nil))

				(noResultContent.source as? OCDataSourceArray)?.setVersionedItems([
					noResultsView
				])

				// Suggestion view
				let suggestionsSource = OCDataSourceArray()
				suggestionsSource.trackItemVersions = true

				let suggestionsContent = SearchViewController.Content(type: .suggestion, source: suggestionsSource, style: emptySection!.cellStyle)

				if clientContext.core?.vault != nil {
					startProvidingSearchSuggestions(to: suggestionsSource, in: clientContext)
				}

				// Create and install SearchViewController
				searchViewController = SearchViewController(with: clientContext, scopes: scopes, defaultScope: defaultScope, suggestionContent: suggestionsContent, noResultContent: noResultContent, delegate: self)

				if let searchViewController = searchViewController {
					self.addStacked(child: searchViewController, position: .top)
				}
			}
		}
	}

	func startProvidingSearchSuggestions(to suggestionsSource: OCDataSourceArray, in clientContext: ClientContext) {
		if let vault = clientContext.core?.vault {
			// Observe saved searches for changes and trigger updates accordingly
			// This observer will automatically be removed once suggestionsSource is deallocated
			vault.addSavedSearchesObserver(suggestionsSource, withInitial: true) { [weak clientContext, weak self] suggestionsSource, savedSearches, isInitial in
				guard let suggestionsSource = suggestionsSource as? OCDataSourceArray, let self, let clientContext else {
					return
				}

				var suggestionItems : [OCDataItem & OCDataItemVersioning] = []

				suggestionItems = self.composeSuggestionContents(from: vault.savedSearches, clientContext: clientContext, includingFallbacks: true)

				// Provide "Enter a search term" placeholder if there is no other content available
				if suggestionItems.count == 0 {
					suggestionItems.append( ComposedMessageView.infoBox(image: nil, subtitle: OCLocalizedString("Enter a search term", nil)) )
				}

				suggestionsSource.setVersionedItems(suggestionItems)
			}
		}
	}

	open func composeSuggestionContents(from savedSearches: [OCSavedSearch]?, clientContext: ClientContext, includingFallbacks: Bool) -> [OCDataItem & OCDataItemVersioning] {
		var suggestionItems : [OCDataItem & OCDataItemVersioning] = []

		// Offer saved search templates
		if let savedTemplates = savedSearches?.filter({ savedSearch in
			return savedSearch.isTemplate
		}), savedTemplates.count > 0 {
			let savedSearchTemplatesHeaderView = ComposedMessageView.sectionHeader(titled: OCLocalizedString("Search templates", nil))
			savedSearchTemplatesHeaderView.elementInsets = .zero

			suggestionItems.append(savedSearchTemplatesHeaderView)
			suggestionItems.append(contentsOf: savedTemplates)
		}

		// Offer saved searches
		if let savedSearches = savedSearches?.filter({ savedSearch in
			return !savedSearch.isTemplate
		}), savedSearches.count > 0 {
			let savedSearchTemplatesHeaderView = ComposedMessageView.sectionHeader(titled: OCLocalizedString("Saved searches", nil))
			savedSearchTemplatesHeaderView.elementInsets = .zero

			suggestionItems.append(savedSearchTemplatesHeaderView)
			suggestionItems.append(contentsOf: savedSearches)
		}

		// Provide "Enter a search term" placeholder if there is no other content available
		if suggestionItems.count == 0, includingFallbacks {
			suggestionItems.append( ComposedMessageView.infoBox(image: nil, subtitle: OCLocalizedString("Enter a search term", nil)) )
		}

		return suggestionItems
	}

	func endSearch() {
		if let searchViewController = searchViewController {
			self.removeStacked(child: searchViewController)
		}
		searchResultsContent = nil
		searchViewController = nil
		sortBar?.isHidden = false
	}

	// MARK: - SearchViewControllerDelegate
	var searchResultsContent: SearchViewController.Content? {
		didSet {
			if let content = searchResultsContent {
				let contentSource = content.source
				let contentStyle = content.style

				switch content.type {
					case .results:
						if searchResultsDataSource != contentSource {
							searchResultsDataSource = contentSource
						}

						if let style = contentStyle ?? preSearchCellStyle, style != itemSection?.cellStyle {
							itemSection?.cellStyle = style
						}

						searchNonItemDataSource = nil

					case .noResults, .suggestion:
						searchResultsDataSource = nil
						searchNonItemDataSource = contentSource
				}
			} else {
				searchResultsDataSource = nil
				searchNonItemDataSource = nil
			}

			recomputeContentState()
		}
	}

	var searchResultsDataSource: OCDataSource? {
		willSet {
			if let oldDataSource = searchResultsDataSource, let itemsQueryDataSource = itemsListDataSource, oldDataSource != itemsQueryDataSource {
				itemSectionDataSource?.removeSources([ oldDataSource ])

				if (newValue == nil) || (newValue == itemsQueryDataSource) {
					itemSectionDataSource?.setInclude(true, for: itemsQueryDataSource)
				}
			}
		}

		didSet {
			if let newDataSource = searchResultsDataSource, let itemsQueryDataSource = itemsListDataSource, newDataSource != itemsQueryDataSource {
				itemSectionDataSource?.setInclude(false, for: itemsQueryDataSource)
				itemSectionDataSource?.insertSources([ newDataSource ], after: itemsQueryDataSource)
			}
		}
	}

	var searchNonItemDataSource: OCDataSource? {
		willSet {
			if let oldDataSource = searchNonItemDataSource, oldDataSource != newValue {
				emptySectionDataSource?.removeSources([ oldDataSource ])
			}
		}

		didSet {
			if let newDataSource = searchNonItemDataSource, newDataSource != oldValue {
				emptySectionDataSource?.addSources([ newDataSource ])
			}
		}
	}

	private var preSearchCellStyle : CollectionViewCellStyle?
	var searchActive : Bool?

	public func searchBegan(for viewController: SearchViewController) {
		preSearchCellStyle = itemSection?.cellStyle
		searchActive = true

		updateSections(with: { sections in
			self.driveSection?.hidden = true
		}, animated: true)
	}

	public func search(for viewController: SearchViewController, content: SearchViewController.Content?) {
		searchResultsContent = content
	}

	public func searchEnded(for viewController: SearchViewController) {
		searchActive = false

		updateSections(with: { sections in
			self.driveSection?.hidden = false
		}, animated: true)

		if let preSearchCellStyle = preSearchCellStyle {
			itemSection?.cellStyle = preSearchCellStyle
		}

		endSearch()

		recomputeContentState()
	}

	// MARK: - Statistics
	var folderStatistics: OCStatistic? {
		didSet {
			self.updateStatisticsFooter()
		}
	}

	var driveQuota: GAQuota? {
		didSet {
			self.updateStatisticsFooter()
		}
	}

	func updateStatisticsFooter() {
		var folderStatisticsText: String = ""
		var quotaInfoText: String = ""

		if let folderStatistics = folderStatistics {
			folderStatisticsText = OCLocalizedFormat("{{itemCount}} items with {{totalSize}} total ({{fileCount}} files, {{folderCount}} folders)", [
				"itemCount" : NumberFormatter.localizedString(from: NSNumber(value: folderStatistics.itemCount?.intValue ?? 0), number: .decimal),
				"fileCount" : NumberFormatter.localizedString(from: NSNumber(value: folderStatistics.fileCount?.intValue ?? 0), number: .decimal),
				"folderCount" : NumberFormatter.localizedString(from: NSNumber(value: folderStatistics.folderCount?.intValue ?? 0), number: .decimal),
				"totalSize" : folderStatistics.localizedSize ?? "-"
			])
		}

		if let driveQuota = driveQuota, let remainingBytes = driveQuota.remaining {
			quotaInfoText = OCLocalizedFormat("{{remaining}} available", [
				"remaining" : ByteCountFormatter.string(fromByteCount: remainingBytes.int64Value, countStyle: .file)
			])

			if folderStatisticsText.count > 0 {
				folderStatisticsText += "\n" + quotaInfoText
			} else {
				folderStatisticsText = quotaInfoText
			}
		}

		OnMainThread {
			if let footerFolderStatisticsLabel = self.footerFolderStatisticsLabel {
				footerFolderStatisticsLabel.text = folderStatisticsText
			}
		}
	}

	// MARK: - Empty actions
	func refreshEmptyActions() {
		guard contentState == .empty else { return }

		var emptyItems : [OCDataItem] = [ ]

		if let emptyItemListItem = emptyItemListItem {
			emptyItems.append(emptyItemListItem)
		}

		if let emptyActions = emptyActions() {
			emptyItems.append(contentsOf: emptyActions)
		}

		emptyItemListDataSource.setItems(emptyItems, updated: nil)
	}

	// MARK: - Drag to refresh
	open var supportsDragToRefresh: Bool {
		return clientContext?.query != nil
	}

	open func performDragToRefresh() {
		if let core = clientContext?.core, let query = clientContext?.query {
			if core.connectionStatus == .online {
				core.reload(query)
			} else {
				refreshControl?.endRefreshing()
			}
		}
	}
}

extension ThemeCSSSelector {
	static let statistics = ThemeCSSSelector(rawValue: "statistics")
}
