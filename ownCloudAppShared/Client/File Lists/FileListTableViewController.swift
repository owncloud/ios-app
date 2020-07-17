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

public protocol OpenItemHandling {
	@discardableResult func open(item: OCItem, animated: Bool, pushViewController: Bool) -> UIViewController?
}

public protocol MoreItemHandling {
	@discardableResult func moreOptions(for item: OCItem, core: OCCore, query: OCQuery?, sender: AnyObject?) -> Bool
}

open class FileListTableViewController: UITableViewController, ClientItemCellDelegate, Themeable {
	open weak var core : OCCore?

	public let estimatedTableRowHeight : CGFloat = 62

	open var progressSummarizer : ProgressSummarizer?
	private var _actionProgressHandler : ActionProgressHandler?

	public init(core inCore: OCCore, style: UITableView.Style = .plain) {
		core = inCore
		super.init(style: style)

		progressSummarizer = ProgressSummarizer.shared(forCore: inCore)
	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	open func makeActionProgressHandler() -> ActionProgressHandler {
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
	open func item(for cell: ClientItemCell) -> OCItem? {
		return cell.item
	}

	open func itemAt(indexPath : IndexPath) -> OCItem? {
		return (self.tableView.cellForRow(at: indexPath) as? ClientItemCell)?.item
	}

	// MARK: - ClientItemCellDelegate
	open func moreButtonTapped(cell: ClientItemCell) {
		guard let item = self.item(for: cell), let core = core, let query = query(forItem: item) else {
			return
		}

		if let moreItemHandling = self as? MoreItemHandling {
			moreItemHandling.moreOptions(for: item, core: core, query: query, sender: cell)
		}
	}

	open func messageButtonTapped(cell: ClientItemCell) {
	}

	open func hasMessage(for item: OCItem) -> Bool {
		return false
	}

	// MARK: - Visibility handling
	private var viewControllerVisible : Bool = false

	open override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		viewControllerVisible = false
	}

	open override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		viewControllerVisible = true
		self.reloadTableData(ifNeeded: true)
	}

	// MARK: - View setup
	open override func viewDidLoad() {
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

	open func registerCellClasses() {
		self.tableView.register(ClientItemCell.self, forCellReuseIdentifier: "itemCell")
	}

	// MARK: - Pull-to-refresh handling
	open var allowPullToRefresh : Bool = false

	open var pullToRefreshControl: UIRefreshControl?
	open var pullToRefreshAction: ((_ completion: @escaping () -> Void) -> Void)?

	open var pullToRefreshVerticalOffset : CGFloat {
		return 0
	}

	@objc open func pullToRefreshTriggered() {
		if core?.connectionStatus == OCCoreConnectionStatus.online {
			UIImpactFeedbackGenerator().impactOccurred()
			performPullToRefreshAction()
		} else {
			pullToRefreshEnded()
		}
	}

	open func performPullToRefreshAction() {
		if pullToRefreshAction != nil {
			pullToRefreshBegan()

			pullToRefreshAction?({ [weak self] in
				self?.pullToRefreshEnded()
			})
		}
	}

	open func pullToRefreshBegan() {
		if let refreshControl = pullToRefreshControl {
			OnMainThread {
				if refreshControl.isRefreshing {
					refreshControl.beginRefreshing()
				}
			}
		}
	}

	open func pullToRefreshEnded() {
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

	open func reloadTableData(ifNeeded: Bool = false) {
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

	open func restoreSelectionAfterTableReload() {
	}

	// MARK: - Single item query creation
	open func query(forItem: OCItem) -> OCQuery? {
		if let path = forItem.path {
			return OCQuery(forPath: path)
		}

		return nil
	}

	// MARK: - Table view data source
	open override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	// MARK: - Table view delegate
	open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)

		if !self.tableView.isEditing {
			guard let rowItem : OCItem = itemAt(indexPath: indexPath) else {
				return
			}

			if let openItemHandler = self as? OpenItemHandling {
				openItemHandler.open(item: rowItem, animated: true, pushViewController: true)
			}
		}
	}

	open override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		guard let core = self.core, let item : OCItem = itemAt(indexPath: indexPath), let cell = tableView.cellForRow(at: indexPath) else {
			return nil
		}

		let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .tableRow)
		let actionContext = ActionContext(viewController: self, core: core, items: [item], location: actionsLocation, sender: cell)
		let actions = Action.sortedApplicableActions(for: actionContext)
		actions.forEach({
			$0.progressHandler = makeActionProgressHandler()
		})

		let contextualActions = actions.compactMap({$0.provideContextualAction()})
		let configuration = UISwipeActionsConfiguration(actions: contextualActions)
		return configuration
	}

	@available(iOS 13.0, *)
	open override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {

		guard let core = self.core, let item : OCItem = itemAt(indexPath: indexPath), let cell = tableView.cellForRow(at: indexPath) else {
			return nil
		}

		return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { _ in
			return self.makeContextMenu(for: indexPath, core: core, item: item, with: cell)
		})
	}

	@available(iOS 13.0, *)
	open func makeContextMenu(for indexPath: IndexPath, core: OCCore, item: OCItem, with cell: UITableViewCell) -> UIMenu {

		let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .contextMenuItem)
		let actionContext = ActionContext(viewController: self, core: core, items: [item], location: actionsLocation, sender: cell)
		let actions = Action.sortedApplicableActions(for: actionContext)
		actions.forEach({
			$0.progressHandler = makeActionProgressHandler()
		})

		let menuItems = actions.compactMap({$0.provideUIMenuAction()})
		let mainMenu = UIMenu(title: "", identifier: UIMenu.Identifier("context"), options: .displayInline, children: menuItems)

		if core.connectionStatus == .online, core.connection.capabilities?.sharingAPIEnabled == 1 {
			// Share Items
			let sharingActionsLocation = OCExtensionLocation(ofType: .action, identifier: .contextMenuSharingItem)
			let sharingActionContext = ActionContext(viewController: self, core: core, items: [item], location: sharingActionsLocation, sender: cell)
			let sharingActions = Action.sortedApplicableActions(for: sharingActionContext)
			sharingActions.forEach({
				$0.progressHandler = makeActionProgressHandler()
			})

			let sharingItems = sharingActions.compactMap({$0.provideUIMenuAction()})
			let shareMenu = UIMenu(title: "", identifier: UIMenu.Identifier("sharing"), options: .displayInline, children: sharingItems)

			return UIMenu(title: "", children: [shareMenu, mainMenu])
		}

		return UIMenu(title: "", children: [mainMenu])
	}

	// MARK: - Themable
	open func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.tableView.applyThemeCollection(collection)
		pullToRefreshControl?.tintColor = collection.navigationBarColors.labelColor

		if event == .update {
			self.reloadTableData()
		}
	}
}
