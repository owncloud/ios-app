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

class QueryFileListTableViewController: FileListTableViewController, SortBarDelegate, OCQueryDelegate, UISearchResultsUpdating {
	var query : OCQuery
	var queryRefreshControl: UIRefreshControl?
	var queryRefreshRateLimiter : OCRateLimiter = OCRateLimiter(minimumTime: 0.2)

	var messageView : MessageView?

	var items : [OCItem] = []

	var refreshActionHandler: (() -> Void)?

	public init(core inCore: OCCore, query inQuery: OCQuery) {
		query = inQuery
		super.init(core: inCore)

		query.delegate = self

		if query.sortComparator == nil {
			query.sortComparator = self.sortMethod.comparator()
		}

		core?.start(query)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		core?.stop(query)
	}

	// MARK: - Sorting
	var sortBar: SortBar?
	var sortMethod: SortMethod {

		set {
			UserDefaults.standard.setValue(newValue.rawValue, forKey: "sort-method")
		}

		get {
			let sort = SortMethod(rawValue: UserDefaults.standard.integer(forKey: "sort-method")) ?? SortMethod.alphabeticallyDescendant
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

	// MARK: - Actions
	@objc func refreshQuery() {
		if core?.connectionStatus == OCCoreConnectionStatus.online {
			UIImpactFeedbackGenerator().impactOccurred()
			refreshActionHandler?()
			core?.reload(query)
		} else {
			if self.queryRefreshControl?.isRefreshing == true {
				self.queryRefreshControl?.endRefreshing()
			}
		}
	}

	// MARK: - SortBarDelegate
	var shallShowSortBar = true

	func sortBar(_ sortBar: SortBar, didUpdateSortMethod: SortMethod) {
		sortMethod = didUpdateSortMethod
		query.sortComparator = sortMethod.comparator()
	}

	func sortBar(_ sortBar: SortBar, presentViewController: UIViewController, animated: Bool, completionHandler: (() -> Void)?) {
		self.present(presentViewController, animated: animated, completion: completionHandler)
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
							if self.queryRefreshControl!.isRefreshing {
								self.queryRefreshControl?.endRefreshing()
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
	}

	// MARK: - Events
	override func viewDidLoad() {
		super.viewDidLoad()

		searchController = UISearchController(searchResultsController: nil)
		searchController?.searchResultsUpdater = self
		searchController?.obscuresBackgroundDuringPresentation = false
		searchController?.hidesNavigationBarDuringPresentation = true
		searchController?.searchBar.placeholder = "Search this folder".localized

		navigationItem.searchController =  searchController
		navigationItem.hidesSearchBarWhenScrolling = false

		self.definesPresentationContext = true

		if shallShowSortBar {
			sortBar = SortBar(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 40), sortMethod: sortMethod)
			sortBar?.delegate = self
			sortBar?.sortMethod = self.sortMethod

			tableView.tableHeaderView = sortBar
		}

		queryRefreshControl = UIRefreshControl()
		queryRefreshControl?.addTarget(self, action: #selector(self.refreshQuery), for: .valueChanged)
		self.tableView.insertSubview(queryRefreshControl!, at: 0)
		tableView.contentOffset = CGPoint(x: 0, y: searchController!.searchBar.frame.height)
		tableView.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)

		messageView = MessageView(add: self.view)

		self.addThemableBackgroundView()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		searchController?.searchBar.text = ""
		searchController?.dismiss(animated: true, completion: nil)
	}

	// MARK: - Table view data source
	override func itemAt(indexPath : IndexPath) -> OCItem? {
		return items[indexPath.row]
	}

	override func query(forItem: OCItem) -> OCQuery? {
		return query
	}

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

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
			if newItem.displaysDifferent(than: cell?.item) {
				cell?.item = newItem
			}
		}

		return cell!
	}
}
