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
	private let maxContentWidth : CGFloat = 500
	private let rowHeight : CGFloat = 44
	private let imageWidth : CGFloat = 30
	private let imageHeight : CGFloat = 30

	// MARK: - Instance Variables
	weak var sortBarDelegate: SortBarDelegate?
	weak var sortBar: SortBar?

	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.isScrollEnabled = false

		var rows : [StaticTableViewRow] = []
		let contentHeight : CGFloat = rowHeight * CGFloat(SortMethod.all.count)
		let contentWidth : CGFloat = (view.frame.size.width < maxContentWidth) ? view.frame.size.width : maxContentWidth
		self.preferredContentSize = CGSize(width: contentWidth, height: contentHeight)

		for method in SortMethod.all {
			var title = method.localizedName()

			if sortBarDelegate?.sortMethod == method {
				if sortBarDelegate?.sortDirection == .descendant {
					title = String(format: "%@ ↓", method.localizedName())
				} else {
					title = String(format: "%@ ↑", method.localizedName())
				}
			}

			let aRow = StaticTableViewRow(rowWithAction: { [weak self] (_, _) in
				guard let self = self else { return }

				self.sortBar?.sortMethod = method

				self.dismiss(animated: false, completion: nil)
				}, title: title)
			rows.append(aRow)
		}

		let section : StaticTableViewSection = StaticTableViewSection(headerTitle: nil, footerTitle: nil, rows: rows)
		self.addSection(section)
	}
}
