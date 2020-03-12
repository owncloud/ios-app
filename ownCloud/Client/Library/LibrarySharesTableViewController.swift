//
//  LibrarySharesTableViewController.swift
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

public class LibrarySharesTableViewController: FileListTableViewController {

	var shareView : LibraryShareView?

	public var shares : [OCShare] = [] {
		didSet {
			OnMainThread {
				self.reloadTableData()
			}
		}
	}

	override func registerCellClasses() {
		self.tableView.register(ShareClientItemCell.self, forCellReuseIdentifier: "itemCell")
	}

	// MARK: - Table view data source
	func shareAtIndexPath(_ indexPath : IndexPath) -> OCShare {
		return shares[indexPath.row]
	}

	override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.shares.count
	}

	override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as? ShareClientItemCell
		let newItem = shareAtIndexPath(indexPath)

		cell?.accessibilityIdentifier = newItem.name
		cell?.core = self.core
		cell?.share = newItem

		if cell?.delegate == nil {
			cell?.delegate = self
		}

		return cell!
	}
}

extension LibrarySharesTableViewController : LibraryShareList {
	func updateWith(shares: [OCShare]) {
		self.shares = shares
	}
}
