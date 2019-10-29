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

class QueryFileListTableViewController: FileListTableViewController, SortBarDelegate, OCQueryDelegate, UISearchResultsUpdating {
	var query : OCQuery

	var queryRefreshRateLimiter : OCRateLimiter = OCRateLimiter(minimumTime: 0.2)

	var messageView : MessageView?

	var items : [OCItem] = []

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

		core?.start(query)

		queryStateObservation = query.observe(\OCQuery.state, options: .initial, changeHandler: { [weak self] (_, _) in
			self?.updateQueryProgressSummary()
		})
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		NotificationCenter.default.removeObserver(self, name: .DisplaySettingsChanged, object: nil)

		queryProgressSummary = nil

		core?.stop(query)
	}

	// MARK: - Display settings
	@objc func displaySettingsChanged() {
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
		tableView.setEditing(!tableView.isEditing, animated: true)
	}

	// MARK: - Query Delegate
	func query(_ query: OCQuery, failedWithError error: Error) {
		// Not applicable atm
	}

	func queryHasChangesAvailable(_ query: OCQuery) {
		queryRefreshRateLimiter.runRateLimitedBlock {
			query.requestChangeSet(withFlags: OCQueryChangeSetRequestFlag(rawValue: 0)) { (query, changeSet) in
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

			tableView.tableHeaderView = sortBar
		}

		messageView = MessageView(add: self.view)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		updateQueryProgressSummary()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

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
			if #available(iOS 12.0, *) {
				if Int(tableView.estimatedRowHeight) * self.items.count > Int(tableView.visibleSize.height), indexTitles.count > 1 {
					return indexTitles
				}
			} else {
				if indexTitles.count > 1 {
					return indexTitles
				}
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
}
