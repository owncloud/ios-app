//
//  UITableView+Extension.swift
//  ownCloud
//
//  Created by Matthias Hühne on 19.03.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
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

extension UITableView {

	//Variable-height UITableView tableHeaderView with autolayout
	func layoutTableHeaderView() {

		guard let headerView = self.tableHeaderView else { return }
		headerView.translatesAutoresizingMaskIntoConstraints = false

		let headerWidth = headerView.bounds.size.width
		let temporaryWidthConstraints = NSLayoutConstraint.constraints(withVisualFormat: "[headerView(width)]", options: NSLayoutConstraint.FormatOptions(rawValue: UInt(0)), metrics: ["width": headerWidth], views: ["headerView": headerView])

		headerView.addConstraints(temporaryWidthConstraints)

		headerView.setNeedsLayout()
		headerView.layoutIfNeeded()

		let headerSize = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
		let height = headerSize.height
		var frame = headerView.frame

		frame.size.height = height
		headerView.frame = frame

		self.tableHeaderView = headerView

		headerView.removeConstraints(temporaryWidthConstraints)
		headerView.translatesAutoresizingMaskIntoConstraints = true
	}
}
