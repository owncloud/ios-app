//
//  BreadCrumbTableViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 09.04.19.
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

class BreadCrumbTableViewController: StaticTableViewController {

	// MARK: - Constants
	private let maxContentWidth : CGFloat = 500
	private let rowHeight : CGFloat = 44
	private let imageWidth : CGFloat = 30
	private let imageHeight : CGFloat = 30

	// MARK: - Instance Variables
	var parentNavigationController : UINavigationController?
	var queryPath : NSString = ""
	var bookmarkShortName : String?

	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.isScrollEnabled = false
		guard let stackViewControllers = parentNavigationController?.viewControllers else { return }
		var pathComp = queryPath.pathComponents

		if queryPath.hasSuffix("/") {
			pathComp.removeLast()
		}
		if pathComp.count > 1 {
			pathComp.removeLast()
		}

		var rows : [StaticTableViewRow] = []
		let pathCount = pathComp.count
		var currentViewContollerIndex = 2
		let contentHeight : CGFloat = rowHeight * CGFloat(pathCount)
		let contentWidth : CGFloat = (view.frame.size.width < maxContentWidth) ? view.frame.size.width : maxContentWidth
		self.preferredContentSize = CGSize(width: contentWidth, height: contentHeight)

		for (_, currentPath) in pathComp.enumerated().reversed() {
			let stackIndex = stackViewControllers.count - currentViewContollerIndex
			var pathTitle = currentPath
			if currentPath == "/", let shortName = self.bookmarkShortName {
				pathTitle = shortName
			}
			let aRow = StaticTableViewRow(rowWithAction: { (_, _) in
				self.parentNavigationController?.popToViewController((stackViewControllers[stackIndex]), animated: true)
				self.dismiss(animated: false, completion: nil)
			}, title: pathTitle, image: Theme.shared.image(for: "folder", size: CGSize(width: imageWidth, height: imageHeight)))

			rows.append(aRow)
			currentViewContollerIndex += 1
		}

		let section : StaticTableViewSection = StaticTableViewSection(headerTitle: nil, footerTitle: nil, rows: rows)
		self.addSection(section)
	}
}
