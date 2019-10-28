//
//  FileListTableViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 21.05.19.
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

class FileListTableViewController: UITableViewController, ClientItemCellDelegate, Themeable {
	weak var core : OCCore?

	let estimatedTableRowHeight : CGFloat = 80

	var progressSummarizer : ProgressSummarizer?
	private var _actionProgressHandler : ActionProgressHandler?

	public init(core inCore: OCCore, style: UITableView.Style = .plain) {
		core = inCore
		super.init(style: style)

		progressSummarizer = ProgressSummarizer.shared(forCore: inCore)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

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

	// MARK: - Item retrieval
	func item(for cell: ClientItemCell) -> OCItem? {
		return cell.item
	}

	func itemAt(indexPath : IndexPath) -> OCItem? {
		return (self.tableView.cellForRow(at: indexPath) as? ClientItemCell)?.item
	}

	// MARK: - ClientItemCellDelegate
	func moreButtonTapped(cell: ClientItemCell) {
		guard let item = self.item(for: cell), let core = core, let query = query(forItem: item) else {
			return
		}

		let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .moreItem)
		let actionContext = ActionContext(viewController: self, core: core, query: query, items: [item], location: actionsLocation)

		if let moreViewController = Action.cardViewController(for: item, with: actionContext, progressHandler: makeActionProgressHandler()) {
			self.present(asCard: moreViewController, animated: true)
		}
	}

	// MARK: - Visibility handling
	private var viewControllerVisible : Bool = false

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		viewControllerVisible = false
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		viewControllerVisible = true
		self.reloadTableData(ifNeeded: true)
	}

	// MARK: - View setup
	override func viewDidLoad() {
		super.viewDidLoad()

		self.navigationController?.navigationBar.prefersLargeTitles = false
		Theme.shared.register(client: self, applyImmediately: true)
		self.tableView.estimatedRowHeight = estimatedTableRowHeight

		self.registerCellClasses()

		if allowPullToRefresh {
			pullToRefreshControl = UIRefreshControl()
			pullToRefreshControl?.tintColor = Theme.shared.activeCollection.navigationBarColors.labelColor
			pullToRefreshControl?.addTarget(self, action: #selector(self.pullToRefreshTriggered), for: .valueChanged)
			self.tableView.insertSubview(pullToRefreshControl!, at: 0)
			tableView.contentOffset = CGPoint(x: 0, y: self.pullToRefreshVerticalOffset)
			tableView.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
		}

		self.addThemableBackgroundView()
	}

	func registerCellClasses() {
		self.tableView.register(ClientItemCell.self, forCellReuseIdentifier: "itemCell")
	}

	// MARK: - Pull-to-refresh handling
	var allowPullToRefresh : Bool = false

	var pullToRefreshControl: UIRefreshControl?
	var pullToRefreshAction: ((_ completion: @escaping () -> Void) -> Void)?

	var pullToRefreshVerticalOffset : CGFloat {
		return 0
	}

	@objc func pullToRefreshTriggered() {
		if core?.connectionStatus == OCCoreConnectionStatus.online {
			UIImpactFeedbackGenerator().impactOccurred()
			performPullToRefreshAction()
		} else {
			pullToRefreshEnded()
		}
	}

	func performPullToRefreshAction() {
		if pullToRefreshAction != nil {
			pullToRefreshBegan()

			pullToRefreshAction?({ [weak self] in
				self?.pullToRefreshEnded()
			})
		}
	}

	func pullToRefreshBegan() {
		if let refreshControl = pullToRefreshControl {
			OnMainThread {
				if refreshControl.isRefreshing {
					refreshControl.beginRefreshing()
				}
			}
		}
	}

	func pullToRefreshEnded() {
		if let refreshControl = pullToRefreshControl {
			OnMainThread {
				if refreshControl.isRefreshing == true {
					refreshControl.endRefreshing()
				}
			}
		}
	}

	// MARK: - Reload Data
	private var tableReloadNeeded = false

	func reloadTableData(ifNeeded: Bool = false) {
		/*
			This is a workaround to cope with the fact that:
			- UITableView.reloadData() does nothing if the view controller is not currently visible (via viewWillDisappear/viewWillAppear), so cells may hold references to outdated OCItems
			- OCQuery may signal updates at any time, including when the view controller is not currently visible

			This workaround effectively makes sure reloadData() is called in viewWillAppear if a reload has been signalled to the tableView while it wasn't visible.
		*/
		if !viewControllerVisible {
			tableReloadNeeded = true
		}

		if !ifNeeded || (ifNeeded && tableReloadNeeded) {
			self.tableView.reloadData()

			if viewControllerVisible {
				tableReloadNeeded = false
			}

			self.restoreSelectionAfterTableReload()
		}
	}

	func restoreSelectionAfterTableReload() {
	}

	// MARK: - Single item query creation
	func query(forItem: OCItem) -> OCQuery? {
		if let path = forItem.path {
			return OCQuery(forPath: path)
		}

		return nil
	}

	// MARK: - Table view data source
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	// MARK: - Table view delegate
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)

		if !self.tableView.isEditing {
			guard let rowItem : OCItem = itemAt(indexPath: indexPath) else {
				return
			}

			open(item: rowItem, animated: true)
		}
	}

	func open(item: OCItem, animated: Bool, pushViewController: Bool = true) -> ClientQueryViewController? {
		if let core = self.core {
			if #available(iOS 13.0, *) {
				if  let tabBarController = self.tabBarController as? ClientRootViewController {
					let activity = OpenItemUserActivity(detailItem: item, detailBookmark: tabBarController.bookmark)
					view.window?.windowScene?.userActivity = activity.openItemUserActivity
				}
			}

			switch item.type {
				case .collection:
					if let path = item.path {
						let clientQueryViewController = ClientQueryViewController(core: core, query: OCQuery(forPath: path))
						if pushViewController {
							self.navigationController?.pushViewController(clientQueryViewController, animated: animated)
						}

						return clientQueryViewController
					}

				case .file:
					guard let query = self.query(forItem: item) else {
						return nil
					}

					let itemViewController = DisplayHostViewController(core: core, selectedItem: item, query: query)
					itemViewController.hidesBottomBarWhenPushed = true
					itemViewController.progressSummarizer = self.progressSummarizer
					self.navigationController?.pushViewController(itemViewController, animated: animated)
			}
		}

		return nil
	}

	// MARK: - Themable
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.tableView.applyThemeCollection(collection)
		pullToRefreshControl?.tintColor = collection.navigationBarColors.labelColor

		if event == .update {
			self.reloadTableData()
		}
	}
}
