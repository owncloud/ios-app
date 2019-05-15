//
//  SharesFilelistTableViewController.swift
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

class SharesFilelistTableViewController: UITableViewController, Themeable {

	weak var core : OCCore?
	var itemTracker : OCCoreItemTracking?

	var lastTappedItemLocalID : String?
	var items : [OCItem] = []
	var shares : [OCShare] = [] {
		didSet {
			let waitGroup = DispatchGroup()
			for share in shares {
				waitGroup.enter()
				itemTracker = core?.trackItem(atPath: share.itemPath, trackingHandler: { (error, item, isInitial) in
					if error == nil, let item = item, isInitial {
						self.items.append(item)
						waitGroup.leave()
					}
				})
				waitGroup.wait()
			}

			OnMainThread {
				self.tableView.reloadData()
			}
		}
	}
	var progressSummarizer : ProgressSummarizer?
	private var _actionProgressHandler : ActionProgressHandler?

	func makeActionProgressHandler() -> ActionProgressHandler {
		if _actionProgressHandler == nil {
			_actionProgressHandler = { [weak self] (progress, publish) in
				if publish {
					self?.progressSummarizer?.startTracking(progress: progress)
				} else {
					self?.progressSummarizer?.stopTracking(progress: progress)
				}
			}
		}

		return _actionProgressHandler!
	}

	// MARK: - View controller events
	private let estimatedTableRowHeight : CGFloat = 80

	// MARK: - Init & Deinit
	public init(core inCore: OCCore) {
		core = inCore
		super.init(style: .plain)

		progressSummarizer = ProgressSummarizer.shared(forCore: inCore)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

    override func viewDidLoad() {
        super.viewDidLoad()

		self.navigationController?.navigationBar.prefersLargeTitles = false
		self.tableView.register(ClientItemCell.self, forCellReuseIdentifier: "itemCell")
		Theme.shared.register(client: self, applyImmediately: true)
		self.tableView.estimatedRowHeight = estimatedTableRowHeight
    }

	deinit {
		Theme.shared.unregister(client: self)
		itemTracker = nil
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.tableView.reloadData()
	}

	// MARK: - Theme support

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.tableView.applyThemeCollection(collection)
		if event == .update {
			self.tableView.reloadData()
		}
	}

	// MARK: - Table view data source
	func itemAtIndexPath(_ indexPath : IndexPath) -> OCItem {
		return items[indexPath.row]
	}

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.items.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as? ClientItemCell
		let newItem = itemAtIndexPath(indexPath)

		cell?.accessibilityIdentifier = newItem.name
		cell?.core = self.core

		if cell?.delegate == nil {
			cell?.delegate = self
		}

		// UITableView can call this method several times for the same cell, and .dequeueReusableCell will then return the same cell again.
		// Make sure we don't request the thumbnail multiple times in that case.
		if (cell?.item?.itemVersionIdentifier != newItem.itemVersionIdentifier) || (cell?.item?.name != newItem.name) || (cell?.item?.syncActivity != newItem.syncActivity) || (cell?.item?.cloudStatus != newItem.cloudStatus) {
			cell?.item = newItem
		}

		return cell!
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		// If not in multiple-selection mode, just navigate to the file or folder (collection)
		if !self.tableView.isEditing {
			let rowItem : OCItem = itemAtIndexPath(indexPath)

			if let core = self.core {
				switch rowItem.type {
				case .collection:
					if let path = rowItem.path {
						self.navigationController?.pushViewController(ClientQueryViewController(core: core, query: OCQuery(forPath: path)), animated: true)
					}

				case .file:
					if lastTappedItemLocalID != rowItem.localID {
						lastTappedItemLocalID = rowItem.localID

						core.downloadItem(rowItem, options: [ .returnImmediatelyIfOfflineOrUnavailable : true ]) { [weak self] (error, core, item, _) in

							guard let self = self else { return }
							OnMainThread { [weak core] in
								if (error == nil) || (error as NSError?)?.isOCError(withCode: .itemNotAvailableOffline) == true {
									if let item = item, let core = core, let path = rowItem.path {
										if item.localID == self.lastTappedItemLocalID {
											let itemViewController = DisplayHostViewController(core: core, selectedItem: item, query: OCQuery(forPath: path))
											itemViewController.hidesBottomBarWhenPushed = true
											self.navigationController?.pushViewController(itemViewController, animated: true)
										}
									}
								}

								if self.lastTappedItemLocalID == item?.localID {
									self.lastTappedItemLocalID = nil
								}
							}
						}
					}
				}
			}

			tableView.deselectRow(at: indexPath, animated: true)
		}
	}

}

// MARK: - ClientItemCell Delegate
extension SharesFilelistTableViewController: ClientItemCellDelegate {
	func moreButtonTapped(cell: ClientItemCell) {
		guard let indexPath = self.tableView.indexPath(for: cell), let core = self.core else {
			return
		}

		let item = self.itemAtIndexPath(indexPath)

		let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .moreItem)
		let actionContext = ActionContext(viewController: self, core: core, items: [item], location: actionsLocation)

		if let moreViewController = Action.cardViewController(for: item, with: actionContext, progressHandler: makeActionProgressHandler()) {
			self.present(asCard: moreViewController, animated: true)
		}
	}
}
