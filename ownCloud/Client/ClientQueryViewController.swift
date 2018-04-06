//
//  ClientQueryViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 05.04.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

class ClientQueryViewController: UITableViewController {
	var core : OCCore?
	var query : OCQuery?

	var items : [OCItem]?

	public init(core inCore: OCCore, query inQuery: OCQuery) {
		super.init(style: .plain)

		core = inCore
		query = inQuery

		query?.delegate = self
		query?.sortComparator = { (left, right) in
			let leftItem = left as? OCItem
			let rightItem = right as? OCItem

			return (leftItem?.name.compare(rightItem!.name))!
		}

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
		core?.stop(query)
	}

	// MARK: - Actions
	@objc func refreshQuery(_: Any) {
		core?.reload(query)
	}

	// MARK: - View controller events
	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "itemCell")

		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false

		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		// self.navigationItem.rightBarButtonItem = self.editButtonItem
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

		// Configure the cell...
		cell.textLabel?.text = rowItem.name
		if rowItem.type == .collection {
			cell.accessoryType = .disclosureIndicator
		} else {
			cell.accessoryType = .none
		}

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
