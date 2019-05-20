//
//  SharingTableViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 20.05.19.
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

class SharingTableViewController : StaticTableViewController {

	// MARK: - Instance Variables

	weak var core : OCCore?
	var item : OCItem
	var messageView : MessageView?
	var shareQuery : OCShareQuery?

	// MARK: - Init & Deinit

	public init(core inCore: OCCore, item inItem: OCItem) {
		core = inCore
		item = inItem

		super.init(style: .grouped)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Header View

	func addHeaderView() {
		guard let core = core else { return }
		let containerView = UIView()
		containerView.translatesAutoresizingMaskIntoConstraints = false

		let headerView = MoreViewHeader(for: item, with: core, favorite: false)
		containerView.addSubview(headerView)
		self.tableView.tableHeaderView = containerView

		containerView.centerXAnchor.constraint(equalTo: self.tableView.centerXAnchor).isActive = true
		containerView.widthAnchor.constraint(equalTo: self.tableView.widthAnchor).isActive = true
		containerView.topAnchor.constraint(equalTo: self.tableView.topAnchor).isActive = true
		containerView.heightAnchor.constraint(equalTo: headerView.heightAnchor).isActive = true

		self.tableView.tableHeaderView?.layoutIfNeeded()
		self.tableView.tableHeaderView = self.tableView.tableHeaderView
		self.tableView.tableHeaderView?.backgroundColor = Theme.shared.activeCollection.tableBackgroundColor
	}

	@objc func dismissView() {
		if let query = self.shareQuery {
			self.core?.stop(query)
		}
		dismissAnimated()
	}
}
