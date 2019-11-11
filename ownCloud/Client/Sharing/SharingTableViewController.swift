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

	var shareQuery : OCShareQuery?
	var shares : [OCShare] = []
	var showActivityIndicator : Bool = false

	var messageView : MessageView?

	// MARK: - Init & Deinit

	public init(core inCore: OCCore, item inItem: OCItem) {
		core = inCore
		item = inItem

		super.init(style: .grouped)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		if let shareQuery = shareQuery {
			core?.stop(shareQuery)
		}
	}

	// MARK: - View events
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		navigationController?.isToolbarHidden = true
	}

	// MARK: - Header View
	func addHeaderView() {
		guard let core = core else { return }

		let headerView = MoreViewHeader(for: item, with: core, favorite: false, adaptBackgroundColor: true, showActivityIndicator: showActivityIndicator)
		self.tableView.tableHeaderView = headerView
		self.tableView.layoutTableHeaderView()
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		if size.width != self.view.frame.size.width {
			DispatchQueue.main.async {
				self.tableView.layoutTableHeaderView()
			}
		}
	}

	// MARK: - Sharing Helper
	func canEdit(share: OCShare) -> Bool {
		if core?.connection.loggedInUser?.userName == share.owner?.userName || core?.connection.loggedInUser?.userName == share.itemOwner?.userName {
			return true
		}

		return false
	}

	func shares(ofTypes types: [OCShareType]) -> [OCShare] {
		return shares.filter { (share) -> Bool in
			return types.contains(share.type)
		}
	}

	func share(at indexPath: IndexPath) -> OCShare? {
		return staticRowForIndexPath(indexPath).representedObject as? OCShare
	}
}
