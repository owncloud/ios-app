//
//  QueryFileListTableViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 23.05.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
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
import ownCloudAppShared

class QueryFileListTableViewController: FileListTableViewController, SortBarDelegate, OCQueryDelegate, UISearchResultsUpdating {
	var query : OCQuery

	var queryRefreshRateLimiter : OCRateLimiter = OCRateLimiter(minimumTime: 0.2)

	var messageView : MessageView?

	var items : [OCItem] = []

	var selectDeselectAllButtonItem: UIBarButtonItem?
	var exitMultipleSelectionBarButtonItem: UIBarButtonItem?

	var selectedItemIds = Set<OCLocalID>()

	var actions : [Action]?

	let flexibleSpaceBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
	var deleteMultipleBarButtonItem: UIBarButtonItem?
	var moveMultipleBarButtonItem: UIBarButtonItem?
	var duplicateMultipleBarButtonItem: UIBarButtonItem?
	var copyMultipleBarButtonItem: UIBarButtonItem?
	var openMultipleBarButtonItem: UIBarButtonItem?

	public init(core inCore: OCCore, query inQuery: OCQuery) {
		query = inQuery

		super.init(core: inCore)

		allowPullToRefresh = true

		NotificationCenter.default.addObserver(self, selector: #selector(QueryFileListTableViewController.displaySettingsChanged), name: .DisplaySettingsChanged, object: nil)
		self.displaySettingsChanged()

		query.delegate = self

		if query.sortComparator == nil {
			query.sortComparator = self.sortMethod.comparator(direction: sortDirection)
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		NotificationCenter.default.removeObserver(self, name: .DisplaySettingsChanged, object: nil)
	}

	// MARK: - Display settings
	@objc func displaySettingsChanged() {
		query.sortComparator = sortMethod.comparator(direction: sortDirection)
		DisplaySettings.shared.updateQuery(withDisplaySettings: query)
	}

	// MARK: - Sorting
	var sortBar: SortBar?
	var sortMethod: SortMethod {
		set {
			UserDefaults.standard.setValue(newValue.rawValue, forKey: "sort-method")
		}

		get {
			let sort = SortMethod(rawValue: UserDefaults.standard.integer(forKey: "sort-method")) ?? SortMethod.alphabetically
			return sort
		}
	}
	var sortDirection: SortDirection {
		set {
			UserDefaults.standard.setValue(newValue.rawValue, forKey: "sort-direction")
		}

		get {
			let sort = SortDirection(rawValue: UserDefaults.standard.integer(forKey: "sort-direction")) ?? SortDirection.ascendant
			return sort
		}
	}

	// MARK: - Search
	var searchController: UISearchController?

	// MARK: - Search: UISearchResultsUpdating Delegate
	func updateSearchResults(for searchController: UISearchController) {
		let searchText = searchController.searchBar.text!

		let filterHandler: OCQueryFilterHandler = { (_, _, item) -> Bool in
			if let itemName = item?.name {
				return itemName.localizedCaseInsensitiveContains(searchText)
			}
			return false
		}

		if searchText == "" {
			if let filter = query.filter(withIdentifier: "text-search") {
				query.removeFilter(filter)
			}
		} else {
			if let filter = query.filter(withIdentifier: "text-search") {
				query.updateFilter(filter, applyChanges: { filterToChange in
					(filterToChange as? OCQueryFilter)?.filterHandler = filterHandler
				})
			} else {
				query.addFilter(OCQueryFilter.init(handler: filterHandler), withIdentifier: "text-search")
			}
		}
	}

	// MARK: - Query progress reporting
	var showQueryProgress : Bool = true

	var queryProgressSummary : ProgressSummary? {
		willSet {
			if newValue != nil, showQueryProgress {
				progressSummarizer?.pushFallbackSummary(summary: newValue!)
			}
		}

		didSet {
			if oldValue != nil, showQueryProgress {
				progressSummarizer?.popFallbackSummary(summary: oldValue!)
			}
		}
	}

	var queryStateObservation : NSKeyValueObservation?

	// MARK: - Pull-to-refresh handling
	override var pullToRefreshVerticalOffset: CGFloat {
		return searchController?.searchBar.frame.height ?? 0
	}

	override func performPullToRefreshAction() {
		super.performPullToRefreshAction()
		core?.reload(query)
	}

	func updateQueryProgressSummary() {
		let summary : ProgressSummary = ProgressSummary(indeterminate: true, progress: 1.0, message: nil, progressCount: 1)

		switch query.state {
			case .stopped:
				summary.message = "Stopped".localized

			case .started:
				summary.message = "Started…".localized

			case .contentsFromCache:
				summary.message = "Contents from cache.".localized

			case .waitingForServerReply:
				summary.message = "Waiting for server response…".localized

			case .targetRemoved:
				summary.message = "This folder no longer exists.".localized

			case .idle:
				summary.message = "Everything up-to-date.".localized
				summary.progressCount = 0

			default:
				summary.message = "Please wait…".localized
		}

		if pullToRefreshControl != nil {
			if query.state == .idle {
				self.pullToRefreshBegan()
			} else if query.state.isFinal {
				self.pullToRefreshEnded()
			}
		}

		self.queryProgressSummary = summary
	}

	// MARK: - SortBarDelegate
	var shallShowSortBar = true

	func sortBar(_ sortBar: SortBar, didUpdateSortMethod: SortMethod) {
		sortMethod = didUpdateSortMethod
		query.sortComparator = sortMethod.comparator(direction: sortDirection)
	}

	func sortBar(_ sortBar: SortBar, presentViewController: UIViewController, animated: Bool, completionHandler: (() -> Void)?) {
		self.present(presentViewController, animated: animated, completion: completionHandler)
	}

	func toggleSelectMode() {
		if !tableView.isEditing {
			multipleSelectionButtonPressed()
		} else {
			exitMultipleSelection()
		}
	}

	// MARK: - Query Delegate
	func query(_ query: OCQuery, failedWithError error: Error) {
		// Not applicable atm
	}

	func queryHasChangesAvailable(_ query: OCQuery) {
		queryRefreshRateLimiter.runRateLimitedBlock {
			query.requestChangeSet(withFlags: .onlyResults) { (query, changeSet) in
				OnMainThread {
					if query.state.isFinal {
						OnMainThread {
							if self.pullToRefreshControl?.isRefreshing == true {
								self.pullToRefreshControl?.endRefreshing()
							}
						}
					}

					let previousItemCount = self.items.count

					self.items = changeSet?.queryResult ?? []

					switch query.state {
					case .contentsFromCache, .idle, .waitingForServerReply:
						if previousItemCount == 0, self.items.count == 0, query.state == .waitingForServerReply {
							break
						}

						if self.items.count == 0 {
							if self.searchController?.searchBar.text != "" {
								self.messageView?.message(show: true, imageName: "icon-search", title: "No matches".localized, message: "There is no results for this search".localized)
							} else {
								self.messageView?.message(show: true, imageName: "folder", title: "Empty folder".localized, message: "This folder contains no files or folders.".localized)
							}
						} else {
							self.messageView?.message(show: false)
						}

						let indexPath = self.tableView.indexPathForSelectedRow
						self.tableView.reloadData()
						self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
					case .targetRemoved:
						self.messageView?.message(show: true, imageName: "folder", title: "Folder removed".localized, message: "This folder no longer exists on the server.".localized)
						self.tableView.reloadData()

					default:
						self.messageView?.message(show: false)
					}

					self.performUpdatesWithQueryChanges(query: query, changeSet: changeSet)
				}
			}
		}
	}

	func performUpdatesWithQueryChanges(query: OCQuery, changeSet: OCQueryChangeSet?) {
	}

	// MARK: - Themeable
	override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		super.applyThemeCollection(theme: theme, collection: collection, event: event)

		self.searchController?.searchBar.applyThemeCollection(collection)
		tableView.sectionIndexColor = collection.tintColor
	}

	// MARK: - Events
	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.allowsMultipleSelectionDuringEditing = true

		searchController = UISearchController(searchResultsController: nil)
		searchController?.searchResultsUpdater = self
		searchController?.obscuresBackgroundDuringPresentation = false
		searchController?.hidesNavigationBarDuringPresentation = true
		searchController?.searchBar.placeholder = "Search this folder".localized
		searchController?.searchBar.applyThemeCollection(Theme.shared.activeCollection)

		navigationItem.searchController = searchController
		navigationItem.hidesSearchBarWhenScrolling = false

		self.definesPresentationContext = true

		if shallShowSortBar {
			sortBar = SortBar(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 40), sortMethod: sortMethod)
			sortBar?.delegate = self
			sortBar?.sortMethod = self.sortMethod
			sortBar?.updateForCurrentTraitCollection()
			sortBar?.showSelectButton = true

			tableView.tableHeaderView = sortBar
		}

		messageView = MessageView(add: self.view)

		selectDeselectAllButtonItem = UIBarButtonItem(title: "Select All".localized, style: .done, target: self, action: #selector(selectAllItems))
		exitMultipleSelectionBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(exitMultipleSelection))

		// Create bar button items for the toolbar
		deleteMultipleBarButtonItem = UIBarButtonItem(image: UIImage(named:"trash"), target: self as AnyObject, action: #selector(actOnMultipleItems), dropTarget: self, actionIdentifier: DeleteAction.identifier!)
		deleteMultipleBarButtonItem?.accessibilityLabel = "Delete".localized
		deleteMultipleBarButtonItem?.isEnabled = false

		moveMultipleBarButtonItem = UIBarButtonItem(image: UIImage(named:"folder"), target: self as AnyObject, action: #selector(actOnMultipleItems), dropTarget: self, actionIdentifier: MoveAction.identifier!)
		moveMultipleBarButtonItem?.accessibilityLabel = "Move".localized
		moveMultipleBarButtonItem?.isEnabled = false

		duplicateMultipleBarButtonItem = UIBarButtonItem(image: UIImage(named: "duplicate-file"), target: self as AnyObject, action: #selector(actOnMultipleItems), dropTarget: self, actionIdentifier: DuplicateAction.identifier!)
		duplicateMultipleBarButtonItem?.accessibilityLabel = "Duplicate".localized
		duplicateMultipleBarButtonItem?.isEnabled = false

		copyMultipleBarButtonItem = UIBarButtonItem(image: UIImage(named: "copy-file"), target: self as AnyObject, action: #selector(actOnMultipleItems), dropTarget: self, actionIdentifier: CopyAction.identifier!)
		copyMultipleBarButtonItem?.accessibilityLabel = "Copy".localized
		copyMultipleBarButtonItem?.isEnabled = false

		openMultipleBarButtonItem = UIBarButtonItem(image: UIImage(named: "open-in"), target: self as AnyObject, action: #selector(actOnMultipleItems), dropTarget: self, actionIdentifier: OpenInAction.identifier!)
		openMultipleBarButtonItem?.accessibilityLabel = "Open in".localized
		openMultipleBarButtonItem?.isEnabled = false
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		core?.start(query)

		queryStateObservation = query.observe(\OCQuery.state, options: .initial, changeHandler: { [weak self] (_, _) in
			self?.updateQueryProgressSummary()
		})

		updateQueryProgressSummary()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		queryStateObservation?.invalidate()
		queryStateObservation = nil

		core?.stop(query)

		queryProgressSummary = nil

		searchController?.searchBar.text = ""
		searchController?.dismiss(animated: true, completion: nil)
	}

	// MARK: - Item retrieval
	override func itemAt(indexPath : IndexPath) -> OCItem? {
		return items[indexPath.row]
	}

	// MARK: - Single item query creation
	override func query(forItem: OCItem) -> OCQuery? {
		return query
	}

	// MARK: - Table view data source
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.items.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as? ClientItemCell
		if let newItem = itemAt(indexPath: indexPath) {

			cell?.accessibilityIdentifier = newItem.name
			cell?.core = self.core

			if cell?.delegate == nil {
				cell?.delegate = self
			}

			// UITableView can call this method several times for the same cell, and .dequeueReusableCell will then return the same cell again.
			// Make sure we don't request the thumbnail multiple times in that case.
			if newItem.displaysDifferent(than: cell?.item, in: core) {
				cell?.item = newItem
			}
		}

		return cell!
	}

	// MARK: - Table view delegate

	override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
		if sortMethod == .alphabetically {
			var indexTitles = Array( Set( self.items.map { String(( $0.name?.first!.uppercased())!) })).sorted()
			if sortDirection == .descendant {
				indexTitles.reverse()
			}
			if Int(tableView.estimatedRowHeight) * self.items.count > Int(tableView.visibleSize.height), indexTitles.count > 1 {
				return indexTitles
			}
		}

		return []
	}

	override open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
		let firstItem = self.items.filter { (( $0.name?.uppercased().hasPrefix(title) ?? nil)! ) }.first

		if let firstItem = firstItem {
			if let itemIndex = self.items.index(of: firstItem) {
				OnMainThread {
					tableView.scrollToRow(at: IndexPath(row: itemIndex, section: 0), at: UITableView.ScrollPosition.top, animated: false)
				}
			}
		}

		return 0
	}

 	override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		guard let core = self.core, let item : OCItem = itemAt(indexPath: indexPath), let cell = tableView.cellForRow(at: indexPath) else {
			return nil
		}

		let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .tableRow)
		let actionContext = ActionContext(viewController: self, core: core, items: [item], location: actionsLocation, sender: cell)
		let actions = Action.sortedApplicableActions(for: actionContext)
		actions.forEach({
			$0.progressHandler = makeActionProgressHandler()
		})

		let contextualActions = actions.compactMap({$0.provideContextualAction()})
		let configuration = UISwipeActionsConfiguration(actions: contextualActions)
		return configuration
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		// If not in multiple-selection mode, just navigate to the file or folder (collection)
		if !self.tableView.isEditing {
			super.tableView(tableView, didSelectRowAt: indexPath)
		} else {
			updateMultiSelectionUI()
		}
	}

	override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		if tableView.isEditing {
			updateMultiSelectionUI()
		}
	}

	// MARK: - Toolbar actions handling multiple selected items
	fileprivate func updateSelectDeselectAllButton() {
		var selectedCount = 0
		if let selectedIndexPaths = self.tableView.indexPathsForSelectedRows {
			selectedCount = selectedIndexPaths.count
		}

		if selectedCount == self.items.count {
			selectDeselectAllButtonItem?.title = "Deselect All".localized
			selectDeselectAllButtonItem?.target = self
			selectDeselectAllButtonItem?.action = #selector(deselectAllItems)
		} else {
			selectDeselectAllButtonItem?.title = "Select All".localized
			selectDeselectAllButtonItem?.target = self
			selectDeselectAllButtonItem?.action = #selector(selectAllItems)
		}
	}

	fileprivate func updateActions(for selectedItems:[OCItem]) {
		guard let tabBarController = self.tabBarController as? ClientRootViewController else { return }

		guard let toolbarItems = tabBarController.toolbar?.items else { return }

		if selectedItems.count > 0 {
			if let core = self.core {
				// Get possible associated actions
				let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .toolbar)
				let actionContext = ActionContext(viewController: self, core: core, query: query, items: selectedItems, location: actionsLocation)

				self.actions = Action.sortedApplicableActions(for: actionContext)

				// Enable / disable tool-bar items depending on action availability
				for item in toolbarItems {
					if self.actions?.contains(where: {type(of:$0).identifier == item.actionIdentifier}) ?? false {
						item.isEnabled = true
					} else {
						item.isEnabled = false
					}
				}
			}

		} else {
			self.actions = nil
			for item in toolbarItems {
				item.isEnabled = false
			}
		}

	}

	fileprivate func updateMultiSelectionUI() {

		updateSelectDeselectAllButton()

		var selectedItems = [OCItem]()

		// Do we have selected items?
		if let selectedIndexPaths = self.tableView.indexPathsForSelectedRows {
			if selectedIndexPaths.count > 0 {

				// Get array of OCItems from selected table view index paths
				selectedItemIds.removeAll()
				for indexPath in selectedIndexPaths {
					if let item = itemAt(indexPath: indexPath) {
						selectedItems.append(item)

						if let localID = item.localID as OCLocalID? {
							selectedItemIds.insert(localID)
						}
					}
				}
			}
		}

		updateActions(for: selectedItems)
	}

	func leaveMultipleSelection() {
		self.tableView.setEditing(false, animated: true)
		self.navigationItem.rightBarButtonItems = nil
		self.navigationItem.leftBarButtonItem = nil
		selectedItemIds.removeAll()
		removeToolbar()
		sortBar?.showSelectButton = true

		if #available(iOS 13, *) {
			self.tableView.overrideUserInterfaceStyle = .unspecified
		}
	}

	func populateToolbar() {
		self.populateToolbar(with: [
			openMultipleBarButtonItem!,
			flexibleSpaceBarButton,
			moveMultipleBarButtonItem!,
			flexibleSpaceBarButton,
			copyMultipleBarButtonItem!,
			flexibleSpaceBarButton,
			duplicateMultipleBarButtonItem!,
			flexibleSpaceBarButton,
			deleteMultipleBarButtonItem!])
	}

	@objc func actOnMultipleItems(_ sender: UIButton) {
		// Find associated action
		if let action = self.actions?.first(where: {type(of:$0).identifier == sender.actionIdentifier}) {
			// Configure progress handler
			action.context.sender = self.tabBarController
			action.progressHandler = makeActionProgressHandler()

			action.completionHandler = { [weak self] (_, _) in
				OnMainThread {
					self?.leaveMultipleSelection()
				}
			}

			// Execute the action
			action.perform()
		}
	}

	// MARK: Multiple Selection

	@objc func multipleSelectionButtonPressed() {

		if #available(iOS 13, *) {
			self.tableView.overrideUserInterfaceStyle = Theme.shared.activeCollection.interfaceStyle.userInterfaceStyle
		}

		updateMultiSelectionUI()
		self.tableView.setEditing(true, animated: true)
		sortBar?.showSelectButton = false

		populateToolbar()

		self.navigationItem.leftBarButtonItem = selectDeselectAllButtonItem!
		self.navigationItem.rightBarButtonItems = [exitMultipleSelectionBarButtonItem!]

		updateMultiSelectionUI()
	}

	@objc func exitMultipleSelection() {
		leaveMultipleSelection()
	}

	@objc func selectAllItems(_ sender: UIBarButtonItem) {
		(0..<self.items.count).map { (item) -> IndexPath in
			return IndexPath(item: item, section: 0)
			}.forEach { (indexPath) in
				self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
		}
		updateMultiSelectionUI()
	}

	@objc func deselectAllItems(_ sender: UIBarButtonItem) {

		self.tableView.indexPathsForSelectedRows?.forEach({ (indexPath) in
			self.tableView.deselectRow(at: indexPath, animated: true)
		})
		updateMultiSelectionUI()
	}
}

@available(iOS 13, *) extension QueryFileListTableViewController {
	override func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
		return !DisplaySettings.shared.preventDraggingFiles
	}

	override func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
		multipleSelectionButtonPressed()
	}
}
