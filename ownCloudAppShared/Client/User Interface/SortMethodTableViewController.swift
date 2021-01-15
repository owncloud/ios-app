//
//  SortMethodTableViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 06.08.19.
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

class SortMethodTableViewController: StaticTableViewController {

	// MARK: - Constants
	private let maxContentWidth : CGFloat = 150
	private let rowHeight : CGFloat = 44

	// MARK: - Instance Variables
	weak var sortBarDelegate: SortBarDelegate?
	weak var sortBar: SortBar?

	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.isScrollEnabled = false
		self.tableView.rowHeight = rowHeight

		var rows : [StaticTableViewRow] = []
		let contentHeight : CGFloat = rowHeight * CGFloat(SortMethod.all.count) - 1
		let contentWidth : CGFloat = maxContentWidth
		self.preferredContentSize = CGSize(width: contentWidth, height: contentHeight)

		for method in SortMethod.all {
			let title = method.localizedName()
			var sortDirectionTitle = ""

			if sortBarDelegate?.sortMethod == method {
				if sortBarDelegate?.sortDirection == .ascendant { // Show arrows opposite to the current sort direction to show what choosing them will lead to
					sortDirectionTitle = "↓"
				} else {
					sortDirectionTitle = "↑"
				}
			}

			let aRow = StaticTableViewRow(subtitleRowWithAction: { [weak self] (_, _) in
				guard let self = self else { return }

				self.sortBar?.sortMethod = method

				self.dismiss(animated: false, completion: nil)
			}, title: title, subtitle: sortDirectionTitle, style: .value1, accessoryType: .none, identifier: nil, withButtonStyle: true)
			rows.append(aRow)
		}

		let section : StaticTableViewSection = StaticTableViewSection(headerTitle: nil, footerTitle: nil, rows: rows)
		self.addSection(section)
	}
}
