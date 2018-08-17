//
//  ClientQueryViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 05.04.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2018, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit
import ownCloudSDK

class ClientQueryViewController: UIViewController {

	var sortBar: SortBar
	var tableView: UITableView

	var core : OCCore
	var query : OCQuery

	var items : [OCItem]?

	var queryProgressSummary : ProgressSummary? {
		willSet {
			if newValue != nil {
				progressSummarizer?.pushFallbackSummary(summary: newValue!)
			}
		}

		didSet {
			if oldValue != nil {
				progressSummarizer?.popFallbackSummary(summary: oldValue!)
			}
		}
	}
	var progressSummarizer : ProgressSummarizer?
	var initialAppearance : Bool = true
	private var observerContextValue = 1
	private var observerContext : UnsafeMutableRawPointer
	var refreshController: UIRefreshControl?

	// MARK: - Init & Deinit
	public init(core inCore: OCCore, query inQuery: OCQuery) {
		observerContext = UnsafeMutableRawPointer(&observerContextValue)

		sortBar = SortBar(frame: .zero, sortMethod: SortMethod.alphabeticallyAscendant)
		tableView = UITableView(frame: .zero, style: .plain)

		core = inCore
		query = inQuery

		super.init(nibName: nil, bundle: nil)

		progressSummarizer = ProgressSummarizer.shared(forCore: inCore)

		query.delegate = self

		query.addObserver(self, forKeyPath: "state", options: .initial, context: observerContext)
		core.addObserver(self, forKeyPath: "reachabilityMonitor.available", options: .initial, context: observerContext)

		core.start(query)

		self.navigationItem.title = (query.queryPath as NSString?)!.lastPathComponent
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		query.removeObserver(self, forKeyPath: "state", context: observerContext)
		core.removeObserver(self, forKeyPath: "reachabilityMonitor.available", context: observerContext)

		core.stop(query)
		Theme.shared.unregister(client: self)

		if messageThemeApplierToken != nil {
			Theme.shared.remove(applierForToken: messageThemeApplierToken)
			messageThemeApplierToken = nil
		}

		self.queryProgressSummary = nil
	}

	// MARK: - Actions
	@objc func refreshQuery() {
		UIImpactFeedbackGenerator().impactOccurred()
		core.reload(query)
	}

	// swiftlint:disable block_based_kvo
	// Would love to use the block-based KVO, but it doesn't seem to work when used on the .state property of the query :-(
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if (object as? OCQuery) === query {
			self.updateQueryProgressSummary()
		}
	}
	// swiftlint:enable block_based_kvo

	// MARK: - View controller events
	override func viewDidLoad() {
		super.viewDidLoad()

		render()

		tableView.register(ClientItemCell.self, forCellReuseIdentifier: "itemCell")

		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false

		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		// self.navigationItem.rightBarButtonItem = self.editButtonItem

		searchController = UISearchController(searchResultsController: nil)
		searchController?.searchResultsUpdater = self
		searchController?.obscuresBackgroundDuringPresentation = false
		searchController?.hidesNavigationBarDuringPresentation = true
		searchController?.searchBar.placeholder = "Search this folder".localized

		navigationItem.searchController =  searchController
		navigationItem.hidesSearchBarWhenScrolling = false

		self.extendedLayoutIncludesOpaqueBars = true
		self.definesPresentationContext = true

		sortBar.delegate = self
		sortBar.sortMethod = sortMethod
		sortBar.updateSortMethod()

		refreshController = UIRefreshControl()
		refreshController?.addTarget(self, action: #selector(self.refreshQuery), for: .valueChanged)
		tableView.insertSubview(refreshController!, at: 0)
//		tableView.contentOffset = CGPoint(x: 0, y: searchController!.searchBar.frame.height)

		Theme.shared.register(client: self, applyImmediately: true)
	}

	private func render() {

		sortBar.translatesAutoresizingMaskIntoConstraints = false
		tableView.translatesAutoresizingMaskIntoConstraints = false

		view.addSubview(sortBar)
		NSLayoutConstraint.activate([
			sortBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			sortBar.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
			sortBar.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
			sortBar.heightAnchor.constraint(equalToConstant: 40)
		])

		view.addSubview(tableView)
		NSLayoutConstraint.activate([
			tableView.topAnchor.constraint(equalTo: sortBar.bottomAnchor),
			tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
			tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
			tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
			])

		tableView.delegate = self
		tableView.dataSource = self

		self.navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")

	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		self.queryProgressSummary = nil
		searchController?.searchBar.text = ""
		searchController?.dismiss(animated: true, completion: nil)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		// Refresh when navigating back to us
		if initialAppearance == false {
			if query.state == .idle {
				core.reload(query)
			}
		}

		initialAppearance = false

		updateQueryProgressSummary()

		sortBar.sortMethod = self.sortMethod
		query.sortComparator = self.sortMethod.comparator()
	}

	func updateQueryProgressSummary() {
		var summary : ProgressSummary = ProgressSummary(indeterminate: true, progress: 1.0, message: nil, progressCount: 1)

		switch query.state {
		case .stopped:
			summary.message = "Stopped".localized

		case .started:
			summary.message = "Started…".localized

		case .contentsFromCache:
			if core.reachabilityMonitor?.available == true {
				summary.message = "Contents from cache.".localized
			} else {
				summary.message = "Offline. Contents from cache.".localized
			}

		case .waitingForServerReply:
			summary.message = "Waiting for server response…".localized

		case .targetRemoved:
			summary.message = "This folder no longer exists.".localized

		case .idle:
			summary.message = "Everything up-to-date.".localized
			summary.progressCount = 0
		}

		switch query.state {
		case .idle:
			DispatchQueue.main.async {
				if !self.refreshController!.isRefreshing {
					self.refreshController?.beginRefreshing()
				}
			}

		case .contentsFromCache, .stopped:
			DispatchQueue.main.async {
				self.tableView.refreshControl = nil
			}

		default:
			break
		}

		self.queryProgressSummary = summary
	}

	// MARK: - Message
	var messageView : UIView?
	var messageContainerView : UIView?
	var messageImageView : VectorImageView?
	var messageTitleLabel : UILabel?
	var messageMessageLabel : UILabel?
	var messageThemeApplierToken : ThemeApplierToken?

	func message(show: Bool, imageName : String? = nil, title : String? = nil, message : String? = nil) {
		if !show {
			if messageView?.superview != nil {
				messageView?.removeFromSuperview()
			}
			return
		}

		if messageView == nil {
			var rootView : UIView
			var containerView : UIView
			var imageView : VectorImageView
			var titleLabel : UILabel
			var messageLabel : UILabel

			rootView = UIView()
			rootView.translatesAutoresizingMaskIntoConstraints = false

			containerView = UIView()
			containerView.translatesAutoresizingMaskIntoConstraints = false

			imageView = VectorImageView()
			imageView.translatesAutoresizingMaskIntoConstraints = false

			titleLabel = UILabel()
			titleLabel.translatesAutoresizingMaskIntoConstraints = false

			messageLabel = UILabel()
			messageLabel.translatesAutoresizingMaskIntoConstraints = false
			messageLabel.numberOfLines = 0
			messageLabel.textAlignment = .center

			containerView.addSubview(imageView)
			containerView.addSubview(titleLabel)
			containerView.addSubview(messageLabel)

			containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[imageView]-(20)-[titleLabel]-[messageLabel]|",
																		options: NSLayoutFormatOptions(rawValue: 0),
																		metrics: nil,
																		views: ["imageView" : imageView, "titleLabel" : titleLabel, "messageLabel" : messageLabel])
			)

			imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
			imageView.widthAnchor.constraint(equalToConstant: 96).isActive = true
			imageView.heightAnchor.constraint(equalToConstant: 96).isActive = true

			titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
			titleLabel.leftAnchor.constraint(greaterThanOrEqualTo: containerView.leftAnchor).isActive = true
			titleLabel.rightAnchor.constraint(lessThanOrEqualTo: containerView.rightAnchor).isActive = true

			messageLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
			messageLabel.leftAnchor.constraint(greaterThanOrEqualTo: containerView.leftAnchor).isActive = true
			messageLabel.rightAnchor.constraint(lessThanOrEqualTo: containerView.rightAnchor).isActive = true

			rootView.addSubview(containerView)

			containerView.centerXAnchor.constraint(equalTo: rootView.centerXAnchor).isActive = true
			containerView.centerYAnchor.constraint(equalTo: rootView.centerYAnchor).isActive = true

			containerView.leftAnchor.constraint(greaterThanOrEqualTo: rootView.leftAnchor, constant: 20).isActive = true
			containerView.rightAnchor.constraint(lessThanOrEqualTo: rootView.rightAnchor, constant: -20).isActive = true
			containerView.topAnchor.constraint(greaterThanOrEqualTo: rootView.topAnchor, constant: 20).isActive = true
			containerView.bottomAnchor.constraint(lessThanOrEqualTo: rootView.bottomAnchor, constant: -20).isActive = true

			messageView = rootView
			messageContainerView = containerView
			messageImageView = imageView
			messageTitleLabel = titleLabel
			messageMessageLabel = messageLabel

			messageThemeApplierToken = Theme.shared.add(applier: { [weak self] (_, collection, _) in
				self?.messageView?.backgroundColor = collection.tableBackgroundColor

				self?.messageTitleLabel?.applyThemeCollection(collection, itemStyle: .bigTitle)
				self?.messageMessageLabel?.applyThemeCollection(collection, itemStyle: .bigMessage)
			})
		}

		if messageView?.superview == nil {
			if let rootView = self.messageView, let containerView = self.messageContainerView {
				containerView.alpha = 0
				containerView.transform = CGAffineTransform(translationX: 0, y: 15)

				rootView.alpha = 0

				self.tableView.addSubview(rootView)

				rootView.leftAnchor.constraint(equalTo: self.tableView.safeAreaLayoutGuide.leftAnchor).isActive = true
				rootView.rightAnchor.constraint(equalTo: self.tableView.safeAreaLayoutGuide.rightAnchor).isActive = true
				rootView.topAnchor.constraint(equalTo: self.tableView.safeAreaLayoutGuide.topAnchor).isActive = true
				rootView.bottomAnchor.constraint(equalTo: self.tableView.safeAreaLayoutGuide.bottomAnchor).isActive = true

				UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
					rootView.alpha = 1
				}, completion: { (_) in
					UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
						containerView.alpha = 1
						containerView.transform = CGAffineTransform.identity
					})
				})
			}
		}

		if imageName != nil {
			messageImageView?.vectorImage = Theme.shared.tvgImage(for: imageName!)
		}
		if title != nil {
			messageTitleLabel?.text = title!
		}
		if message != nil {
			messageMessageLabel?.text = message!
		}
	}

	// MARK: - Sorting
	private var sortMethod: SortMethod {

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
}

// MARK: - TableView Delegate
extension ClientQueryViewController: UITableViewDelegate {

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		guard let rowItem : OCItem = self.items?[indexPath.row] else {
			return
		}

		switch rowItem.type {
		case .collection:
			self.navigationController?.pushViewController(ClientQueryViewController(core: self.core, query: OCQuery(forPath: rowItem.path)), animated: true)

		case .file:
			let fallbackSummary = ProgressSummary(indeterminate: true, progress: 1.0, message: "Downloading \(rowItem.name!)", progressCount: 1)

			if let downloadProgress = self.core.downloadItem(rowItem, options: nil, resultHandler: { (error, _, item, file) in
				OnMainThread {
					if error != nil {
						// TODO: Handle error
					} else {
						let itemViewController : ClientItemViewController = ClientItemViewController()

						itemViewController.file = file
						itemViewController.item = item

						self.navigationController?.pushViewController(itemViewController, animated: true)
					}

					self.progressSummarizer?.popFallbackSummary(summary: fallbackSummary)
				}
			}) {
				Log.log("Downloading \(rowItem.name!): \(downloadProgress)")

				progressSummarizer?.pushFallbackSummary(summary: fallbackSummary)

				// TODO: Use progress as soon as it works SDK-wise
				// progressSummarizer?.startTracking(progress: downloadProgress)
			}
		}
	}

	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

		guard let item: OCItem = items?[indexPath.row] else {
			return nil
		}

		let presentationStyle: UIAlertControllerStyle = UIDevice.current.isIpad() ? UIAlertControllerStyle.alert : UIAlertControllerStyle.actionSheet

		let deleteContextualAction: UIContextualAction = UIContextualAction(style: .destructive, title: "Delete".localized) { (_, _, actionPerformed) in

			let alertController =
				UIAlertController(with: item.name!,
								  message: "Are you sure you want to delete this file from the server?".localized,
								  destructiveLabel: "Delete".localized,
								  preferredStyle: presentationStyle,
								  destructiveAction: {
									if let progress = self.core.delete(item, requireMatch: true, resultHandler: { (error, _, _, _) in
										if error != nil {
											Log.log("Error \(String(describing: error)) deleting \(String(describing: item.path))")
										}
									}) {
										self.progressSummarizer?.startTracking(progress: progress)
									}
				}
			)

			self.present(alertController, animated: true, completion: {
				actionPerformed(false)
			})
		}

		let renameContextualAction = UIContextualAction(style: .normal, title: "Rename") { (_, _, actionPerformed) in
			let renamevc = NamingViewController(with: item, core: self.core, stringValidator: { name in
				if name.contains("/") || name.contains("\\") {
					return (false, "File name cannot contain / or \\")
				} else {
					return (true, nil)
				}
			}, completion: { newName, _ in

				guard newName != nil else {
					return
				}

				if let progress = self.core.move(item, to: self.query.rootItem, withName: newName, options: nil, resultHandler: { (error, _, _, _) in
					if error != nil {
						Log.log("Error \(String(describing: error)) renaming \(String(describing: item.path))")
					}
				}) {
					self.progressSummarizer?.startTracking(progress: progress)
				}
			})

			let renameNavigationVC = ThemeNavigationController(rootViewController: renamevc)
			renameNavigationVC.modalPresentationStyle = .overFullScreen
			self.navigationController?.present(renameNavigationVC, animated: true)

			actionPerformed(false)
		}

		let actions: [UIContextualAction] = [deleteContextualAction, renameContextualAction]
		let actionsConfigurator: UISwipeActionsConfiguration = UISwipeActionsConfiguration(actions: actions)

		return actionsConfigurator
	}

}

// MARK: - Theme support
extension ClientQueryViewController: Themeable {
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.tableView.applyThemeCollection(collection)
		self.sortBar.backgroundColor = Theme.shared.activeCollection.navigationBarColors.backgroundColor
		self.searchController?.searchBar.applyThemeCollection(collection)

		if event == .update {
			self.tableView.reloadData()
		}
	}
}

// MARK: - TableView DataSource
extension ClientQueryViewController: UITableViewDataSource {
	func numberOfSections(in tableView: UITableView) -> Int {
		// #warning Incomplete implementation, return the number of sections
		return 1
	}

 	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// #warning Incomplete implementation, return the number of rows
		if self.items != nil {
			return self.items!.count
		}

		return 0
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as? ClientItemCell
		let newItem = self.items![indexPath.row]

		cell?.core = self.core

		// UITableView can call this method several times for the same cell, and .dequeueReusableCell will then return the same cell again.
		// Make sure we don't request the thumbnail multiple times in that case.
		if (cell?.item?.itemVersionIdentifier != newItem.itemVersionIdentifier) || (cell?.item?.name != newItem.name) {
			cell?.item = newItem
		}

		return cell!
	}
}

// MARK: - Query Delegate
extension ClientQueryViewController : OCQueryDelegate {

	func query(_ query: OCQuery!, failedWithError error: Error!) {

	}

	func queryHasChangesAvailable(_ query: OCQuery!) {
		query.requestChangeSet(withFlags: OCQueryChangeSetRequestFlag(rawValue: 0)) { (_, changeSet) in
			DispatchQueue.main.async {

				switch query.state {
				case .idle, .targetRemoved, .contentsFromCache, .stopped:
					if self.refreshController!.isRefreshing {
						self.refreshController?.endRefreshing()
					}
				default: break
				}

				self.items = changeSet?.queryResult

				switch query.state {
				case .contentsFromCache, .idle:
					if self.items?.count == 0 {
						if self.searchController?.searchBar.text != "" {
							self.message(show: true, imageName: "icon-search", title: "No matches".localized, message: "There is no results for this search".localized)
						} else {
							self.message(show: true, imageName: "folder", title: "Empty folder".localized, message: "This folder contains no files or folders.".localized)
						}
					} else {
						self.message(show: false)
					}

					self.tableView.reloadData()

				case .targetRemoved:
					self.message(show: true, imageName: "folder", title: "Folder removed".localized, message: "This folder no longer exists on the server.".localized)
					self.tableView.reloadData()

				default:
					self.message(show: false)
				}
			}
		}
	}
}

// MARK: - SortBar Delegate
extension ClientQueryViewController : SortBarDelegate {
	func sortBar(_ sortBar: SortBar, leftButtonPressed: UIButton) {
		print("LOG ---> left button pressed")
	}

	func sortBar(_ sortBar: SortBar, rightButtonPressed: UIButton) {
		print("LOG ---> right button pressed")
	}

	func sortBar(_ sortBar: SortBar, didUpdateSortMethod: SortMethod) {
		sortMethod = didUpdateSortMethod
		query.sortComparator = sortMethod.comparator()

	}
}

// MARK: - UISearchResultsUpdating Delegate
extension ClientQueryViewController: UISearchResultsUpdating {
	func updateSearchResults(for searchController: UISearchController) {
		let searchText = searchController.searchBar.text!

		let filterHandler: OCQueryFilterHandler = { (_, _, item) -> Bool in
			if let item = item {
				if item.name.localizedCaseInsensitiveContains(searchText) {return true}

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

	func sortBar(_ sortBar: SortBar, presentViewController: UIViewController, animated: Bool, completionHandler: (() -> Void)?) {

		self.present(presentViewController, animated: animated, completion: completionHandler)
	}
}
