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

class ClientQueryViewController: UITableViewController, Themeable {
	var core : OCCore?
	var query : OCQuery?

	var items : [OCItem]?

	private var _queryProgressSummary : ProgressSummary?
	var queryProgressSummary : ProgressSummary? {
		set(newProgressSummary) {
			if newProgressSummary != nil {
				progressSummarizer?.pushFallbackSummary(summary: newProgressSummary!)
			}

			if _queryProgressSummary != nil {
				progressSummarizer?.popFallbackSummary(summary: _queryProgressSummary!)
			}

			_queryProgressSummary = newProgressSummary
		}

		get {
			return _queryProgressSummary
		}
	}
	var progressSummarizer : ProgressSummarizer?
	private var observerContextValue = 1
	private var observerContext : UnsafeMutableRawPointer

	public init(core inCore: OCCore, query inQuery: OCQuery) {
		observerContext = UnsafeMutableRawPointer(&observerContextValue)

		super.init(style: .plain)

		core = inCore
		query = inQuery

		progressSummarizer = ProgressSummarizer.shared(forCore: inCore)

		query?.delegate = self
		query?.sortComparator = { (left, right) in
			let leftItem = left as? OCItem
			let rightItem = right as? OCItem

			return (leftItem?.name.compare(rightItem!.name))!
		}

		query?.addObserver(self, forKeyPath: "state", options: .initial, context: observerContext)

		core?.start(query)

		self.navigationItem.title = (query?.queryPath as NSString?)!.lastPathComponent
		self.tableView.contentInsetAdjustmentBehavior = .always
		self.tableView.refreshControl = UIRefreshControl()

		self.tableView.refreshControl?.addTarget(self, action: #selector(refreshQuery(_:)), for: .valueChanged)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		query?.removeObserver(self, forKeyPath: "state", context: observerContext)

		core?.stop(query)
		Theme.shared.unregister(client: self)

		self.queryProgressSummary = nil
	}

	// MARK: - Actions
	@objc func refreshQuery(_: Any) {
		core?.reload(query)
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

		self.tableView.register(ClientItemCell.self, forCellReuseIdentifier: "itemCell")

		Theme.shared.register(client: self, applyImmediately: true)

		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false

		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		// self.navigationItem.rightBarButtonItem = self.editButtonItem
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		self.queryProgressSummary = nil
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		updateQueryProgressSummary()
	}

	func updateQueryProgressSummary() {
		var summary : ProgressSummary = ProgressSummary(indeterminate: true, progress: 1.0, message: nil, progressCount: 1)

		switch query?.state {
			case .stopped?:
				summary.message = "Stopped"

			case .started?:
				summary.message = "Started…"

			case .contentsFromCache?:
				summary.message = "Contents from cache."

			case .waitingForServerReply?:
				summary.message = "Waiting for server…"

			case .targetRemoved?:
				summary.message = "This folder no longer exists."

			case .idle?:
				summary.message = "Everything up-to-date."
				summary.progressCount = 0

			case .none:
				summary.message = "Please wait…"
		}

		self.queryProgressSummary = summary
	}

	// MARK: - Theme support

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.tableView.applyThemeCollection(collection)

		if event == .update {
			self.tableView.reloadData()
		}
	}

	// MARK: - Table view data source
	override func numberOfSections(in tableView: UITableView) -> Int {
		// #warning Incomplete implementation, return the number of sections
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// #warning Incomplete implementation, return the number of rows
		if self.items != nil {
			return self.items!.count
		}

		return 0
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath)
		let rowItem : OCItem = self.items![indexPath.row]

		(cell as? ClientItemCell)?.item = rowItem

		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let rowItem : OCItem = self.items![indexPath.row]

		if rowItem.type == .collection {
			self.navigationController?.pushViewController(ClientQueryViewController.init(core: self.core!, query: OCQuery.init(forPath: rowItem.path)), animated: true)
		}
	}
}

extension ClientQueryViewController : OCQueryDelegate {

	func query(_ query: OCQuery!, failedWithError error: Error!) {

	}

	func queryHasChangesAvailable(_ query: OCQuery!) {
		query.requestChangeSet(withFlags: OCQueryChangeSetRequestFlag.init(rawValue: 0)) { (_, changeSet) in
			DispatchQueue.main.async {
				self.items = changeSet?.queryResult
				self.tableView.reloadData()

				if query.state == .idle {
					if self.refreshControl?.isRefreshing ?? false {
						self.refreshControl?.endRefreshing()
					}
				}
			}
		}
	}
}
