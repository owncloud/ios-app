//
//  UITableViewController+Extension.swift
//  ownCloud
//
//  Created by Matthias Hühne on 26.02.19.
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

extension UITableViewController {
	func addThemableBackgroundView() {
		// UITableView background view is nil for default. Set a UIView with clear color to can insert a subview above
		let backgroundView = UIView.init(frame: self.tableView.frame)
		backgroundView.backgroundColor = UIColor.clear
		self.tableView.backgroundView = backgroundView

		// This view is needed to stop flickering when scrolling (white line between UINavigationBar and UITableView header
		let coloredView = ThemeableColoredView.init(frame: CGRect(x: 0, y: -self.view.frame.size.height, width: self.view.frame.size.width, height: self.view.frame.size.height + 1))
		coloredView.translatesAutoresizingMaskIntoConstraints = false

		self.tableView.insertSubview(coloredView, aboveSubview: self.tableView.backgroundView!)

		NSLayoutConstraint.activate([
			coloredView.topAnchor.constraint(equalTo: self.tableView.topAnchor, constant: -self.view.frame.size.height),
			coloredView.leftAnchor.constraint(equalTo: self.tableView.leftAnchor, constant: 0),
			coloredView.rightAnchor.constraint(equalTo: self.tableView.rightAnchor, constant: 0),
			coloredView.heightAnchor.constraint(equalToConstant: self.view.frame.size.height + 1)
			])
	}
}
