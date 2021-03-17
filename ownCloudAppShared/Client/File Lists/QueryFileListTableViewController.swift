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

public extension OCQueryState {
	var isFinal: Bool {
		switch self {
		case .idle, .targetRemoved, .contentsFromCache, .stopped:
			return true
		default:
			return false
		}
	}
}

public protocol MultiSelectSupport {
	func setupMultiselection()
	func enterMultiselection()
	func exitMultiselection()
	func updateMultiselection()
	func populateToolbar()
}

open class QueryFileListTableViewController: FileListTableViewController, SortBarDelegate, OCQueryDelegate, UISearchResultsUpdating {

	public var query : OCQuery

	public var queryRefreshRateLimiter : OCRateLimiter = OCRateLimiter(minimumTime: 0.2)

	public var messageView : MessageView?

	public var items : [OCItem] = []

	public var selectedItemIds = [OCLocalID]()

	public var actionContext: ActionContext?
	public var actions : [Action]?

	public var selectDeselectAllButtonItem: UIBarButtonItem?
	public var exitMultipleSelectionBarButtonItem: UIBarButtonItem?

	public var regularLeftBarButtons : [UIBarButtonItem]?
	public var regularRightBarButtons : [UIBarButtonItem]?

	public let flexibleSpaceBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
	public var deleteMultipleBarButtonItem: UIBarButtonItem?
	public var moveMultipleBarButtonItem: UIBarButtonItem?
	public var duplicateMultipleBarButtonItem: UIBarButtonItem?
	public var copyMultipleBarButtonItem: UIBarButtonItem?
	public var openMultipleBarButtonItem: UIBarButtonItem?
	public var isMoreButtonPermanentlyHidden: Bool = false
	public var didSelectCellAction: ((_ completion: @escaping () -> Void) -> Void)?
	public var showSelectButton: Bool = true

	public init(core inCore: OCCore, query inQuery: OCQuery) {
		query = inQuery
		searchScope = .global

		super.init(core: inCore)

		allowPullToRefresh = true

		NotificationCenter.default.addObserver(self, selector: #selector(QueryFileListTableViewController.displaySettingsChanged), name: .DisplaySettingsChanged, object: nil)
		self.displaySettingsChanged()

		query.delegate = self

		if query.sortComparator == nil {
			query.sortComparator = self.sortMethod.comparator(direction: sortDirection)
		}
	}

	required public init?(coder aDecoder: NSCoder) {
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
	open var sortBar: SortBar?
	open var sortMethod: SortMethod {
		set {
			UserDefaults.standard.setValue(newValue.rawValue, forKey: "sort-method")
		}

		get {
			let sort = SortMethod(rawValue: UserDefaults.standard.integer(forKey: "sort-method")) ?? SortMethod.alphabetically
			return sort
		}
	}
	open var searchScope: SearchScope = .local
	open var sortDirection: SortDirection {
		set {
			UserDefaults.standard.setValue(newValue.rawValue, forKey: "sort-direction")
		}

		get {
			let direction = SortDirection(rawValue: UserDefaults.standard.integer(forKey: "sort-direction")) ?? SortDirection.ascendant
			return direction
		}
	}

	// MARK: - Search
	open var searchController: UISearchController?

	// MARK: - Search: UISearchResultsUpdating Delegate
	open func updateSearchResults(for searchController: UISearchController) {
		let searchText = searchController.searchBar.text!

		applySearchFilter(for: (searchText == "") ? nil : searchText, to: query)
	}

	open func applySearchFilter(for searchText: String?, to query: OCQuery) {
 		if let searchText = searchText {
 			let filterHandler: OCQueryFilterHandler = { (_, _, item) -> Bool in
 				if let itemName = item?.name {
 					return itemName.localizedCaseInsensitiveContains(searchText)
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

	// MARK: - Query progress reporting
	open var showQueryProgress : Bool = true

	open var queryProgressSummary : ProgressSummary? {
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

	open var queryStateObservation : NSKeyValueObservation?

	// MARK: - Pull-to-refresh handling
	override open var pullToRefreshVerticalOffset: CGFloat {
		return searchController?.searchBar.frame.height ?? 0
	}

	override open func performPullToRefreshAction() {
		super.performPullToRefreshAction()
		core?.reload(query)
	}

	open func updateQueryProgressSummary() {
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
	open var shallShowSortBar = true

	open func sortBar(_ sortBar: SortBar, didUpdateSortMethod: SortMethod) {
		sortMethod = didUpdateSortMethod
		query.sortComparator = sortMethod.comparator(direction: sortDirection)
	}

	open func sortBar(_ sortBar: SortBar, presentViewController: UIViewController, animated: Bool, completionHandler: (() -> Void)?) {
		self.present(presentViewController, animated: animated, completion: completionHandler)
	}

	// MARK: - Query Delegate
	open func query(_ query: OCQuery, failedWithError error: Error) {
		// Not applicable atm
	}

	open func queryHasChangesAvailable(_ query: OCQuery) {
		queryRefreshRateLimiter.runRateLimitedBlock {
			query.requestChangeSet(withFlags: .onlyResults) { (query, changeSet) in
				OnMainThread {
//					if query.state.isFinal {
//						OnMainThread {
//							if self.pullToRefreshControl?.isRefreshing == true {
//								self.pullToRefreshControl?.endRefreshing()
//							}
//						}
//					}
//
//					let previousItemCount = self.items.count
//
//					self.items = changeSet?.queryResult ?? []
//
//					// Setup new action context
//					if let core = self.core {
//						let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .toolbar)
//						self.actionContext = ActionContext(viewController: self, core: core, query: query, items: [OCItem](), location: actionsLocation)
//					}
//
//					switch query.state {
//					case .contentsFromCache, .idle, .waitingForServerReply:
//						if previousItemCount == 0, self.items.count == 0, query.state == .waitingForServerReply {
//							break
//						}
//
//						if self.items.count == 0 {
//							if self.searchController?.searchBar.text != "" {
//								self.messageView?.message(show: true, imageName: "icon-search", title: "No matches".localized, message: "There is no results for this search".localized)
//							} else {
//								self.messageView?.message(show: true, imageName: "folder", title: "Empty folder".localized, message: "This folder contains no files or folders.".localized)
//							}
//						} else {
//							self.messageView?.message(show: false)
//						}
//
//						self.tableView.reloadData()
//					case .targetRemoved:
//						self.messageView?.message(show: true, imageName: "folder", title: "Folder removed".localized, message: "This folder no longer exists on the server.".localized)
//						self.tableView.reloadData()
//
//					default:
//						self.messageView?.message(show: false)
//					}

					self.performUpdatesWithQueryChanges(query: query, changeSet: changeSet)
				}
			}
		}
	}

	open func performUpdatesWithQueryChanges(query: OCQuery, changeSet: OCQueryChangeSet?) {
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

 				self.tableView.reloadData()
 			case .targetRemoved:
 				self.messageView?.message(show: true, imageName: "folder", title: "Folder removed".localized, message: "This folder no longer exists on the server.".localized)
 				self.tableView.reloadData()

 			default:
 				self.messageView?.message(show: false)
 		}
	}

	// MARK: - Themeable
	open override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		super.applyThemeCollection(theme: theme, collection: collection, event: event)

		self.searchController?.searchBar.applyThemeCollection(collection)
		tableView.sectionIndexColor = collection.tintColor
	}

	// MARK: - Events
	open override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.allowsMultipleSelectionDuringEditing = true

		searchController = UISearchController(searchResultsController: nil)
		searchController?.searchResultsUpdater = self
		searchController?.obscuresBackgroundDuringPresentation = false
		searchController?.hidesNavigationBarDuringPresentation = true
		searchController?.searchBar.applyThemeCollection(Theme.shared.activeCollection)

		navigationItem.searchController = searchController
		navigationItem.hidesSearchBarWhenScrolling = false

		self.definesPresentationContext = true

		if shallShowSortBar {
			sortBar = SortBar(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 40), sortMethod: sortMethod)
			sortBar?.delegate = self
			sortBar?.sortMethod = self.sortMethod
			sortBar?.searchScope = self.searchScope
			sortBar?.updateForCurrentTraitCollection()
			sortBar?.showSelectButton = showSelectButton

			tableView.tableHeaderView = sortBar
		}

		messageView = MessageView(add: self.view)

		if let multiSelectSupport = self as? MultiSelectSupport {
			multiSelectSupport.setupMultiselection()
		}
	}

	open override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		// Needs to be done here, because of an iOS 13 bug. Do not move to viewDidLoad!
		if #available(iOS 13.0, *) {
			let attributedStringColor = [NSAttributedString.Key.foregroundColor : Theme.shared.activeCollection.searchBarColors.secondaryLabelColor]
			let attributedString = NSAttributedString(string: "Search this folder".localized, attributes: attributedStringColor)
			searchController?.searchBar.searchTextField.attributedPlaceholder = attributedString
		} else {
			// Fallback on earlier versions
			searchController?.searchBar.placeholder = "Search this folder".localized
		}
	}

	open override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		core?.start(query)

		queryStateObservation = query.observe(\OCQuery.state, options: .initial, changeHandler: { [weak self] (_, _) in
			self?.updateQueryProgressSummary()
		})

		updateQueryProgressSummary()
	}

	open override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		queryStateObservation?.invalidate()
		queryStateObservation = nil

		core?.stop(query)

		queryProgressSummary = nil

		searchController?.searchBar.text = ""
		searchController?.dismiss(animated: true, completion: nil)
	}

	// MARK: - Item retrieval
	open override func itemAt(indexPath : IndexPath) -> OCItem? {
		return items[indexPath.row]
	}

	// MARK: - Single item query creation
	open override func query(forItem: OCItem) -> OCQuery? {
		return query
	}

	// MARK: - Table view data source
	open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.items.count
	}

	open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

			if let localID = newItem.localID as OCLocalID?, self.selectedItemIds.contains(localID) {
				cell?.setSelected(true, animated: false)
			}

			if isMoreButtonPermanentlyHidden {
				cell?.isMoreButtonPermanentlyHidden = true
			}
		}

		return cell!
	}

	// MARK: - Table view delegate

	open override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
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

	open func sortBar(_ sortBar: SortBar, didUpdateSearchScope: SearchScope) {
 	}

	open func toggleSelectMode() {
		if let multiSelectionSupport = self as? MultiSelectSupport {
			if !tableView.isEditing {
				multiSelectionSupport.enterMultiselection()
			} else {
				multiSelectionSupport.exitMultiselection()
			}
		}
	}

	open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		// If not in multiple-selection mode, just navigate to the file or folder (collection)
		if !self.tableView.isEditing {
			if let item = itemAt(indexPath: indexPath), item.type != .collection, isMoreButtonPermanentlyHidden {
				return
			}
			if didSelectCellAction != nil {
				didSelectCellAction?({ })
			} else {
				super.tableView(tableView, didSelectRowAt: indexPath)
			}
		} else {
			if let multiSelectionSupport = self as? MultiSelectSupport {
				if let item = itemAt(indexPath: indexPath), let itemLocalID = item.localID {
					if !selectedItemIds.contains(itemLocalID as OCLocalID) {
						selectedItemIds.append(itemLocalID as OCLocalID)
					}
					self.actionContext?.add(item: item)
				}
				multiSelectionSupport.updateMultiselection()
			}
		}
	}

	open override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		if tableView.isEditing {
			if let multiSelectionSupport = self as? MultiSelectSupport {
				if let item = itemAt(indexPath: indexPath), let itemLocalID = item.localID {
					selectedItemIds.removeAll(where: {$0 as String == itemLocalID})
					self.actionContext?.remove(item: item)
				}
				multiSelectionSupport.updateMultiselection()
			}
		}
	}

	@available(iOS 13.0, *)
	open override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		if isMoreButtonPermanentlyHidden {
			return nil
		}

		return super.tableView(tableView, contextMenuConfigurationForRowAt: indexPath, point: point)
	}

	open override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		if isMoreButtonPermanentlyHidden {
			return nil
		}

		return super.tableView(tableView, trailingSwipeActionsConfigurationForRowAt: indexPath)
	}
}

@available(iOS 13, *) public extension QueryFileListTableViewController {
	override func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
		return !DisplaySettings.shared.preventDraggingFiles
	}

	override func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
		if let multiSelectionSupport = self as? MultiSelectSupport {
			multiSelectionSupport.enterMultiselection()
		}
	}
}
