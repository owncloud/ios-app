//
//  CustomFilelistTableViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 13.05.19.
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

	class CustomFilelistTableViewController: UITableViewController, Themeable {

		weak var core : OCCore?
		var query : OCQuery

		var lastTappedItemLocalID : String?
		var items : [OCItem] = []
		var progressSummarizer : ProgressSummarizer?
		private var _actionProgressHandler : ActionProgressHandler?
		var queryRefreshControl: UIRefreshControl?
		var queryRefreshRateLimiter : OCRateLimiter = OCRateLimiter(minimumTime: 0.2)
		var messageView : MessageView?

		// MARK: - Search
		var searchController: UISearchController?

		// MARK: - Sorting
		private var sortBar: SortBar?
		private var sortMethod: SortMethod {

			set {
				UserDefaults.standard.setValue(newValue.rawValue, forKey: "sort-method")
			}

			get {
				let sort = SortMethod(rawValue: UserDefaults.standard.integer(forKey: "sort-method")) ?? SortMethod.alphabeticallyAscendant
				return sort
			}
		}

		func makeActionProgressHandler() -> ActionProgressHandler {
			if _actionProgressHandler == nil {
				_actionProgressHandler = { [weak self] (progress, publish) in
					if publish {
						self?.progressSummarizer?.startTracking(progress: progress)
					} else {
						self?.progressSummarizer?.stopTracking(progress: progress)
					}
				}
			}

			return _actionProgressHandler!
		}

		// MARK: - View controller events
		private let estimatedTableRowHeight : CGFloat = 80

		// MARK: - Init & Deinit
		public init(core inCore: OCCore, query inQuery: OCQuery) {

			core = inCore
			query = inQuery

			super.init(style: .plain)

			query.sortComparator = self.sortMethod.comparator()

			query.delegate = self

			query.addObserver(self, forKeyPath: "state", options: .initial, context: nil)
			core?.start(query)

			progressSummarizer = ProgressSummarizer.shared(forCore: inCore)
		}

		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}

		override func viewDidLoad() {
			super.viewDidLoad()

			self.navigationController?.navigationBar.prefersLargeTitles = false
			self.tableView.register(ClientItemCell.self, forCellReuseIdentifier: "itemCell")
			Theme.shared.register(client: self, applyImmediately: true)
			self.tableView.estimatedRowHeight = estimatedTableRowHeight

			searchController = UISearchController(searchResultsController: nil)
			searchController?.searchResultsUpdater = self
			searchController?.obscuresBackgroundDuringPresentation = false
			searchController?.hidesNavigationBarDuringPresentation = true
			searchController?.searchBar.placeholder = "Search this folder".localized
			searchController?.searchBar.applyThemeCollection(Theme.shared.activeCollection)

			navigationItem.searchController =  searchController
			navigationItem.hidesSearchBarWhenScrolling = false

			self.definesPresentationContext = true

			queryRefreshControl = UIRefreshControl()
			queryRefreshControl?.addTarget(self, action: #selector(self.refreshQuery), for: .valueChanged)
			self.tableView.insertSubview(queryRefreshControl!, at: 0)
			tableView.contentOffset = CGPoint(x: 0, y: searchController!.searchBar.frame.height)
			tableView.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)

			sortBar = SortBar(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 40), sortMethod: sortMethod)
			sortBar?.delegate = self
			sortBar?.sortMethod = self.sortMethod

			tableView.tableHeaderView = sortBar
			messageView = MessageView(add: self.view)
		}

		deinit {
			query.removeObserver(self, forKeyPath: "state", context: nil)

			core?.stop(query)
			Theme.shared.unregister(client: self)
			//self.queryProgressSummary = nil
		}

		override func viewWillAppear(_ animated: Bool) {
			super.viewWillAppear(animated)

			self.tableView.reloadData()
		}

		override func viewWillDisappear(_ animated: Bool) {
			super.viewWillDisappear(animated)

			searchController?.searchBar.text = ""
			searchController?.dismiss(animated: true, completion: nil)
		}

		// MARK: - Theme support

		func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
			self.tableView.applyThemeCollection(collection)
			self.searchController?.searchBar.applyThemeCollection(collection)
			if event == .update {
				self.tableView.reloadData()
			}
		}

		// MARK: - Table view data source
		func itemAtIndexPath(_ indexPath : IndexPath) -> OCItem {
			return items[indexPath.row]
		}

		override func numberOfSections(in tableView: UITableView) -> Int {
			return 1
		}

		override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
			return self.items.count
		}

		override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
			let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as? ClientItemCell
			let newItem = itemAtIndexPath(indexPath)

			cell?.accessibilityIdentifier = newItem.name
			cell?.core = self.core

			if cell?.delegate == nil {
				cell?.delegate = self
			}

			// UITableView can call this method several times for the same cell, and .dequeueReusableCell will then return the same cell again.
			// Make sure we don't request the thumbnail multiple times in that case.
			if (cell?.item?.itemVersionIdentifier != newItem.itemVersionIdentifier) || (cell?.item?.name != newItem.name) || (cell?.item?.syncActivity != newItem.syncActivity) || (cell?.item?.cloudStatus != newItem.cloudStatus) {
				cell?.item = newItem
			}

			return cell!
		}

		override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
			// If not in multiple-selection mode, just navigate to the file or folder (collection)
			if !self.tableView.isEditing {
				let rowItem : OCItem = itemAtIndexPath(indexPath)

				if let core = self.core {
					switch rowItem.type {
					case .collection:
						if let path = rowItem.path {
							self.navigationController?.pushViewController(ClientQueryViewController(core: core, query: OCQuery(forPath: path)), animated: true)
						}

					case .file:
						if lastTappedItemLocalID != rowItem.localID {
							lastTappedItemLocalID = rowItem.localID

							core.downloadItem(rowItem, options: [ .returnImmediatelyIfOfflineOrUnavailable : true ]) { [weak self] (error, core, item, _) in

								guard let self = self else { return }
								OnMainThread { [weak core] in
									if (error == nil) || (error as NSError?)?.isOCError(withCode: .itemNotAvailableOffline) == true {
										if let item = item, let core = core, let path = rowItem.path {
											if item.localID == self.lastTappedItemLocalID {
												let itemViewController = DisplayHostViewController(core: core, selectedItem: item, query: OCQuery(forPath: path))
												itemViewController.hidesBottomBarWhenPushed = true
												self.navigationController?.pushViewController(itemViewController, animated: true)
											}
										}
									}

									if self.lastTappedItemLocalID == item?.localID {
										self.lastTappedItemLocalID = nil
									}
								}
							}
						}
					}
				}

				tableView.deselectRow(at: indexPath, animated: true)
			}
		}

		override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
			if sortMethod == .alphabeticallyAscendant || sortMethod == .alphabeticallyDescendant {
				return Array( Set( self.items.map { String(( $0.name?.first!.uppercased() )!) } ) ).sorted()
			}

			return []
		}

		override open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
			let firstItem = self.items.filter { (( $0.name?.uppercased().hasPrefix(title) ?? nil)! ) }.first

			if let firstItem = firstItem {
				if let itemIndex = self.items.index(of: firstItem) {
					OnMainThread {
						tableView.scrollToRow(at: IndexPath(row: itemIndex, section: 0), at: UITableView.ScrollPosition.top , animated: false)
					}
				}
			}

			return 0
		}

	}

// MARK: - UISearchResultsUpdating Delegate
extension CustomFilelistTableViewController: UISearchResultsUpdating {
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
}

	// MARK: - ClientItemCell Delegate
	extension CustomFilelistTableViewController: ClientItemCellDelegate {
		func moreButtonTapped(cell: ClientItemCell) {
			guard let indexPath = self.tableView.indexPath(for: cell), let core = self.core else {
				return
			}

			let item = self.itemAtIndexPath(indexPath)

			let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .moreItem)
			let actionContext = ActionContext(viewController: self, core: core, items: [item], location: actionsLocation)

			if let moreViewController = Action.cardViewController(for: item, with: actionContext, progressHandler: makeActionProgressHandler()) {
				self.present(asCard: moreViewController, animated: true)
			}
		}

		// MARK: - Actions
		@objc func refreshQuery() {
			if core?.connectionStatus == OCCoreConnectionStatus.online {
				UIImpactFeedbackGenerator().impactOccurred()
				core?.reload(query)
			} else {
				if self.queryRefreshControl?.isRefreshing == true {
					self.queryRefreshControl?.endRefreshing()
				}
			}
		}
}

// MARK: - Query Delegate
extension CustomFilelistTableViewController : OCQueryDelegate {
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
				}
			}
		}
	}
}

// MARK: - SortBar Delegate
extension CustomFilelistTableViewController : SortBarDelegate {
	func sortBar(_ sortBar: SortBar, didUpdateSortMethod: SortMethod) {
		sortMethod = didUpdateSortMethod
		query.sortComparator = sortMethod.comparator()
	}

	func sortBar(_ sortBar: SortBar, presentViewController: UIViewController, animated: Bool, completionHandler: (() -> Void)?) {
		self.present(presentViewController, animated: animated, completion: completionHandler)
	}
}
