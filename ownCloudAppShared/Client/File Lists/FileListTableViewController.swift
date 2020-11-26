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
	@discardableResult func moreOptions(for item: OCItem, at location: OCExtensionLocationIdentifier, core: OCCore, query: OCQuery?, sender: AnyObject?) -> Bool
}

public protocol InlineMessageSupport {
	func hasInlineMessage(for item: OCItem) -> Bool
	func showInlineMessageFor(item: OCItem)
}

open class FileListTableViewController: UICollectionViewController, ClientItemCellDelegate, Themeable {
	public func currentLayout() -> SortLayout {
		return currentCollectionViewLayout
	}

	open weak var core : OCCore?
	public var currentCollectionViewLayout: SortLayout = .list

	public let estimatedTableRowHeight : CGFloat = 62

	open var progressSummarizer : ProgressSummarizer?
	private var _actionProgressHandler : ActionProgressHandler?

	public init(core inCore: OCCore, style: UITableView.Style = .plain) {
		core = inCore

		super.init(collectionViewLayout: UICollectionViewLayout())
		self.collectionView.setCollectionViewLayout(createLayout(), animated: false)
		self.collectionView.alwaysBounceVertical = true
		self.collectionView.contentInsetAdjustmentBehavior = .always

		progressSummarizer = ProgressSummarizer.shared(forCore: inCore)
	}

	enum SectionLayoutKind: Int, CaseIterable {
	 case list, grid5, grid3
	 func columnCount(for width: CGFloat) -> Int {
		 let wideMode = width > 400
		 switch self {
		 case .grid3:
			 return wideMode ? 6 : 3

		 case .grid5:
			 return wideMode ? 10 : 5

		 case .list:
			 return wideMode ? 2 : 1
		 }
	 }
 }
 /*
 func configureDataSource() {
	 dataSource = UICollectionViewDiffableDataSource<SectionLayoutKind, Int>(collectionView: collectionView) {
		 (collectionView: UICollectionView, indexPath: IndexPath, identifier: Int) -> UICollectionViewCell? in
		 let section = SectionLayoutKind(rawValue: indexPath.section)!
		 if section == .list {
			 if let cell = collectionView.dequeueReusableCell(
				 withReuseIdentifier: ListCell.reuseIdentifier,
				 for: indexPath) as? ListCell {
				 cell.label.text = "\(identifier)"
				 return cell
			 } else {
				 fatalError("Cannot create new cell")
			 }
		 } else {
			 if let cell = collectionView.dequeueReusableCell(
				 withReuseIdentifier: TextCell.reuseIdentifier,
				 for: indexPath) as? TextCell {
				 cell.label.text = "\(identifier)"
				 cell.contentView.backgroundColor = .cornflowerBlue
				 cell.contentView.layer.borderColor = UIColor.black.cgColor
				 cell.contentView.layer.borderWidth = 1
				 cell.contentView.layer.cornerRadius = section == .grid5 ? 8 : 0
				 cell.label.textAlignment = .center
				 cell.label.font = UIFont.preferredFont(forTextStyle: .title1)
				 return cell
			 } else {
				 fatalError("Cannot create new cell")
			 }
		 }
	 }

	 // initial data
	 let itemsPerSection = 10
	 var snapshot = NSDiffableDataSourceSnapshot<SectionLayoutKind, Int>()
	 SectionLayoutKind.allCases.forEach {
		 snapshot.appendSections([$0])
		 let itemOffset = $0.rawValue * itemsPerSection
		 let itemUpperbound = itemOffset + itemsPerSection
		 snapshot.appendItems(Array(itemOffset..<itemUpperbound))
	 }
	 dataSource.apply(snapshot, animatingDifferences: false)
 }
*/
 public func createLayout() -> UICollectionViewLayout {
	 if #available(iOS 13.0, *) {
		 /*
		 let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
											   heightDimension: .fractionalHeight(1.0))
	 let item = NSCollectionLayoutItem(layoutSize: itemSize)

	 let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
										   heightDimension: .absolute(62))
	 let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
													  subitems: [item])

	 let section = NSCollectionLayoutSection(group: group)

	 let layout = UICollectionViewCompositionalLayout(section: section)

	 return layout
*/
		 let layout = UICollectionViewCompositionalLayout {
			 (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
			 guard let layoutKind = SectionLayoutKind(rawValue: sectionIndex) else { return nil }

			 let columns = layoutKind.columnCount(for: layoutEnvironment.container.effectiveContentSize.width)

			 let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
												  heightDimension: .fractionalHeight(1.0))
			 let item = NSCollectionLayoutItem(layoutSize: itemSize)
			 item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)

			 let groupHeight = layoutKind == .list ?
				 NSCollectionLayoutDimension.absolute(63) : NSCollectionLayoutDimension.fractionalWidth(0.2)
			 let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
													heightDimension: groupHeight)
			 let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: columns)

			 let section = NSCollectionLayoutSection(group: group)

			 let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
														  heightDimension: .estimated(44))
			 let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
				 layoutSize: headerFooterSize,
				 elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
			 let sectionFooter = NSCollectionLayoutBoundarySupplementaryItem(
				 layoutSize: headerFooterSize,
				 elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)
			 section.boundarySupplementaryItems = [sectionHeader, sectionFooter]

			 //section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
			 return section
		 }
		 return layout
	 }

	 let layout = UICollectionViewFlowLayout()
	 layout.itemSize = CGSize(width: 362, height: 62)
	 layout.minimumInteritemSpacing = 0
	 layout.minimumLineSpacing = 0
	 layout.headerReferenceSize = CGSize(width: 0, height: 40)
	 layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
	 layout.footerReferenceSize = CGSize(width: 0, height: 60)

	 return layout
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
		return (self.collectionView.cellForItem(at: indexPath) as? ClientItemCell)?.item
	}

	// MARK: - ClientItemCellDelegate
	open func moreButtonTapped(cell: ClientItemCell) {
		guard let item = self.item(for: cell), let core = core, let query = query(forItem: item) else {
			return
		}

		if let moreItemHandling = self as? MoreItemHandling {
			moreItemHandling.moreOptions(for: item, at: .moreItem, core: core, query: query, sender: cell)
		}
	}

	// MARK: - Inline message support
	open func hasMessage(for item: OCItem) -> Bool {
		if let inlineMessageSupport = self as? InlineMessageSupport {
			return inlineMessageSupport.hasInlineMessage(for: item)
		}

		return false
	}

	open func messageButtonTapped(cell: ClientItemCell) {
		if let item = cell.item {
			if let inlineMessageSupport = self as? InlineMessageSupport {
				inlineMessageSupport.showInlineMessageFor(item: item)
			}
		}
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

		self.registerCellClasses()

		if allowPullToRefresh {
			pullToRefreshControl = UIRefreshControl()
			pullToRefreshControl?.tintColor = Theme.shared.activeCollection.navigationBarColors.labelColor
			pullToRefreshControl?.addTarget(self, action: #selector(self.pullToRefreshTriggered), for: .valueChanged)
			self.collectionView.insertSubview(pullToRefreshControl!, at: 0)
			collectionView.contentOffset = CGPoint(x: 0, y: self.pullToRefreshVerticalOffset)
			//collectionView.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
		}

		//self.addThemableBackgroundView()
	}

	open func registerCellClasses() {
		collectionView.register(ClientItemCell.self, forCellWithReuseIdentifier: "itemCell")
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
			self.collectionView.reloadData()

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

	// MARK: - Collection view data source
	open override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}

	// MARK: - Collection view delegate
	open override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		//collectionView.deselectRow(at: indexPath, animated: true)

		//if !self.collectionView.isEditing {
			guard let rowItem : OCItem = itemAt(indexPath: indexPath) else {
				return
			}

			if let openItemHandler = self as? OpenItemHandling {
				openItemHandler.open(item: rowItem, animated: true, pushViewController: true)
			}
		//}
	}
/*
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
			self.removeToolbar()
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
	}*/

	// MARK: - Themable
	open func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.collectionView.applyThemeCollection(collection)
		pullToRefreshControl?.tintColor = collection.navigationBarColors.labelColor

		if event == .update {
			self.reloadTableData()
		}
	}
}
