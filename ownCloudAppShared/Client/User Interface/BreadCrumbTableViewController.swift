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

open class BreadCrumbTableViewController: StaticTableViewController {

	// MARK: - Constants
	private let maxContentWidth : CGFloat = 500
	private let rowHeight : CGFloat = 44
	private let imageWidth : CGFloat = 30
	private let imageHeight : CGFloat = 30

	// MARK: - Instance Variables
	open var parentNavigationController : UINavigationController?
	open var queryPath : NSString = ""
	open var bookmarkShortName : String?
	open var navigationHandler : ((_ path: String) -> Void)?

	open override func viewDidLoad() {
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

		for (idx, currentPath) in pathComp.enumerated().reversed() {
			var stackIndex = stackViewControllers.count - currentViewContollerIndex
			if stackIndex < 0 {
				stackIndex = 0
			}
			var pathTitle = currentPath
			if currentPath.isRootPath, let shortName = self.bookmarkShortName {
				pathTitle = shortName
			}
			var fullPath = ((pathComp as NSArray).subarray(with: NSRange(location: 1, length: idx)) as NSArray).componentsJoined(by: "/") + "/"
			if !fullPath.hasPrefix("/") {
				fullPath = "/" + fullPath
			}
			let aRow = StaticTableViewRow(rowWithAction: { [weak self] (_, _) in
				guard let self = self else { return }
				if let navigationHandler = self.navigationHandler {
					navigationHandler(fullPath)
				} else {
					if stackViewControllers.indices.contains(stackIndex) {
						self.parentNavigationController?.popToViewController((stackViewControllers[stackIndex]), animated: true)
					}
				}
				self.dismiss(animated: false, completion: nil)
			}, title: pathTitle, image: Theme.shared.image(for: "folder", size: CGSize(width: imageWidth, height: imageHeight)))

			rows.append(aRow)
			currentViewContollerIndex += 1
		}

		let section : StaticTableViewSection = StaticTableViewSection(headerTitle: nil, footerTitle: nil, rows: rows)
		self.addSection(section)
	}
}
