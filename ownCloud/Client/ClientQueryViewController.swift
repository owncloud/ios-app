//
//  ClientQueryViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 05.04.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
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
import ownCloudSDK
import MobileCoreServices
import Photos

typealias ClientActionVieDidAppearHandler = () -> Void
typealias ClientActionCompletionHandler = (_ actionPerformed: Bool) -> Void

class ClientQueryViewController: UITableViewController, Themeable, UIDropInteractionDelegate, UIPopoverPresentationControllerDelegate {
	weak var core : OCCore?
	var query : OCQuery

	var items : [OCItem] = []

	var actions : [Action]?

	var queryProgressSummary : ProgressSummary? {
		willSet {
			if newValue != nil {
				progressSummarizer?.pushFallbackSummary(summary: newValue!)
			}
		}

		didSet {
			if oldValue != nil {
				progressSummarizer?.popFallbackSummary(summary: oldValue!)
			}
		}
	}
	var progressSummarizer : ProgressSummarizer?
	var queryRefreshControl: UIRefreshControl?

	let flexibleSpaceBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
	var deleteMultipleBarButtonItem: UIBarButtonItem?
	var moveMultipleBarButtonItem: UIBarButtonItem?
	var duplicateMultipleBarButtonItem: UIBarButtonItem?
	var copyMultipleBarButtonItem: UIBarButtonItem?
	var openMultipleBarButtonItem: UIBarButtonItem?

	var selectBarButton: UIBarButtonItem?
	var uploadBarButton: UIBarButtonItem?

	var selectDeselectAllButtonItem: UIBarButtonItem?
	var exitMultipleSelectionBarButtonItem: UIBarButtonItem?

	// MARK: - Init & Deinit
	public init(core inCore: OCCore, query inQuery: OCQuery) {

		core = inCore
		query = inQuery

		super.init(style: .plain)

		progressSummarizer = ProgressSummarizer.shared(forCore: inCore)

		query.delegate = self

		query.addObserver(self, forKeyPath: "state", options: .initial, context: nil)
		core?.start(query)

		var title = (query.queryPath as NSString?)!.lastPathComponent

		if title == "/", let shortName = core?.bookmark.shortName {
			title = shortName
			self.navigationItem.title = title
		} else {
			let titleButton = UIButton()
			titleButton.setTitle(title, for: .normal)
			titleButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
			titleButton.addTarget(self, action: #selector(showPathBreadCrumb(_:)), for: .touchUpInside)
			titleButton.sizeToFit()
			titleButton.accessibilityLabel = "Show parent paths".localized
			titleButton.accessibilityIdentifier = "show-paths-button"
			self.navigationItem.titleView = titleButton
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		query.removeObserver(self, forKeyPath: "state", context: nil)

		core?.stop(query)
		Theme.shared.unregister(client: self)

		if messageThemeApplierToken != nil {
			Theme.shared.remove(applierForToken: messageThemeApplierToken)
			messageThemeApplierToken = nil
		}

		self.queryProgressSummary = nil
	}

	// MARK: - Actions
	@objc func refreshQuery() {
		if core?.connectionStatus == OCCoreConnectionStatus.online {
			UIImpactFeedbackGenerator().impactOccurred()
			core?.reload(query)
		} else {
			if self.queryRefreshControl?.isRefreshing == true {
				self.queryRefreshControl?.endRefreshing()
			}
		}
	}

	// swiftlint:disable block_based_kvo
	// Would love to use the block-based KVO, but it doesn't seem to work when used on the .state property of the query :-(
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if (object as? OCQuery) === query {
			self.updateQueryProgressSummary()
		}
	}
	// swiftlint:enable block_based_kvo

	// MARK: - View controller events
	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.register(ClientItemCell.self, forCellReuseIdentifier: "itemCell")
		searchController = UISearchController(searchResultsController: nil)
		searchController?.searchResultsUpdater = self
		searchController?.obscuresBackgroundDuringPresentation = false
		searchController?.hidesNavigationBarDuringPresentation = true
		searchController?.searchBar.placeholder = "Search this folder".localized

		navigationItem.searchController =  searchController
		navigationItem.hidesSearchBarWhenScrolling = false

		self.definesPresentationContext = true

		sortBar = SortBar(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 40), sortMethod: sortMethod)
		sortBar?.delegate = self
		sortBar?.updateSortMethod()

		tableView.tableHeaderView = sortBar

		queryRefreshControl = UIRefreshControl()
		queryRefreshControl?.addTarget(self, action: #selector(self.refreshQuery), for: .valueChanged)
		self.tableView.insertSubview(queryRefreshControl!, at: 0)
		tableView.contentOffset = CGPoint(x: 0, y: searchController!.searchBar.frame.height)

		Theme.shared.register(client: self, applyImmediately: true)

		self.tableView.dragDelegate = self
		self.tableView.dropDelegate = self
		self.tableView.dragInteractionEnabled = true
		self.tableView.allowsMultipleSelectionDuringEditing = true

		uploadBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(uploadsBarButtonPressed))
		selectBarButton = UIBarButtonItem(title: "Select".localized, style: .done, target: self, action: #selector(multipleSelectionButtonPressed))
		self.navigationItem.rightBarButtonItems = [selectBarButton!, uploadBarButton!]

		selectDeselectAllButtonItem = UIBarButtonItem(title: "Select All".localized, style: .done, target: self, action: #selector(selectAllItems))
		exitMultipleSelectionBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(exitMultipleSelection))

		// Create bar button items for the toolbar
		deleteMultipleBarButtonItem = UIBarButtonItem(image: UIImage(named:"trash"), target: self as AnyObject, action: #selector(actOnMultipleItems), dropTarget: self, actionIdentifier: DeleteAction.identifier!)
		deleteMultipleBarButtonItem?.isEnabled = false

		moveMultipleBarButtonItem = UIBarButtonItem(image: UIImage(named:"folder"), target: self as AnyObject, action: #selector(actOnMultipleItems), dropTarget: self, actionIdentifier: MoveAction.identifier!)
		moveMultipleBarButtonItem?.isEnabled = false

		duplicateMultipleBarButtonItem = UIBarButtonItem(image: UIImage(named: "duplicate-file"), target: self as AnyObject, action: #selector(actOnMultipleItems), dropTarget: self, actionIdentifier: DuplicateAction.identifier!)
		duplicateMultipleBarButtonItem?.isEnabled = false

		copyMultipleBarButtonItem = UIBarButtonItem(image: UIImage(named: "copy-file"), target: self as AnyObject, action: #selector(actOnMultipleItems), dropTarget: self, actionIdentifier: CopyAction.identifier!)
		copyMultipleBarButtonItem?.isEnabled = false

		openMultipleBarButtonItem = UIBarButtonItem(image: UIImage(named: "open-in"), target: self as AnyObject, action: #selector(actOnMultipleItems), dropTarget: self, actionIdentifier: OpenInAction.identifier!)
		openMultipleBarButtonItem?.isEnabled = false

		self.addThemableBackgroundView()
	}

	private var viewControllerVisible : Bool = false

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		self.queryProgressSummary = nil
		searchController?.searchBar.text = ""
		searchController?.dismiss(animated: true, completion: nil)

		viewControllerVisible = false
		leaveMultipleSelection()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		updateQueryProgressSummary()

		sortBar?.sortMethod = self.sortMethod
		query.sortComparator = self.sortMethod.comparator()

		viewControllerVisible = true

		self.reloadTableData(ifNeeded: true)
	}

	func updateQueryProgressSummary() {
		var summary : ProgressSummary = ProgressSummary(indeterminate: true, progress: 1.0, message: nil, progressCount: 1)

		switch query.state {
			case .stopped:
				summary.message = "Stopped".localized

			case .started:
				summary.message = "Started…".localized

			case .contentsFromCache:
				summary.message = "Contents from cache.".localized

			case .waitingForServerReply:
				summary.message = "Waiting for server response…".localized

			case .targetRemoved:
				summary.message = "This folder no longer exists.".localized

			case .idle:
				summary.message = "Everything up-to-date.".localized
				summary.progressCount = 0

			default:
				summary.message = "Please wait…".localized
		}

		switch query.state {
			case .idle:
				OnMainThread {
					if !self.queryRefreshControl!.isRefreshing {
						self.queryRefreshControl?.beginRefreshing()
					}
				}

			case .contentsFromCache, .stopped:
				OnMainThread {
					self.tableView.refreshControl = nil
				}

			default:
			break
		}

		self.queryProgressSummary = summary
	}

	// MARK: - Theme support

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.tableView.applyThemeCollection(collection)
		self.searchController?.searchBar.applyThemeCollection(collection)
		if event == .update {
			self.reloadTableData()
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

	var lastTappedItemLocalID : String?

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

							core.downloadItem(rowItem, options: [ .returnImmediatelyIfOfflineOrUnavailable : true ]) { [weak self, query] (error, core, item, _) in

								guard let self = self else { return }
								OnMainThread {
									if (error == nil) || (error as NSError?)?.isOCError(withCode: .itemNotAvailableOffline) == true {
										if let item = item, let core = core {
											if item.localID == self.lastTappedItemLocalID {
												let itemViewController = GalleryHostViewController(core: core, selectedItem: item, query: query)
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
		} else {
			updateMultiSelectionUI()
		}
	}

	override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		if tableView.isEditing {
			updateMultiSelectionUI()
		}
	}

	override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
		if tableView.isEditing {
			return true
		} else {
			return true
		}
	}

	func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
		for item in session.items {
			if item.localObject == nil, item.itemProvider.hasItemConformingToTypeIdentifier("public.folder") {
				return false
			}
		}
		return true
	}

 	override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		guard let core = self.core else {
			return nil
		}

		let item: OCItem = itemAtIndexPath(indexPath)

		let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .tableRow)
		let actionContext = ActionContext(viewController: self, core: core, items: [item], location: actionsLocation)
		let actions = Action.sortedApplicableActions(for: actionContext)
		actions.forEach({$0.progressHandler = { [weak self] progress in
			self?.progressSummarizer?.startTracking(progress: progress)
			}
		})

		let contextualActions = actions.compactMap({$0.provideContextualAction()})
		let configuration = UISwipeActionsConfiguration(actions: contextualActions)
		return configuration
	}

	func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {

		if session.localDragSession != nil {
				if let indexPath = destinationIndexPath, items.count - 1 < indexPath.row {
					return UITableViewDropProposal(operation: .forbidden)
				}

				if let indexPath = destinationIndexPath, items[indexPath.row].type == .file {
					return UITableViewDropProposal(operation: .move)
				} else {
					return UITableViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
				}
		} else {
			return UITableViewDropProposal(operation: .copy)
		}
	}

	func updateToolbarItemsForDropping(_ items: [OCItem]) {
		guard let tabBarController = self.tabBarController as? ClientRootViewController else { return }
		guard let toolbarItems = tabBarController.toolbar?.items else { return }

		if let core = self.core {
			// Remove duplicates
			let uniqueItems = Array(Set(items))
			// Get possible associated actions
			let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .toolbar)
			let actionContext = ActionContext(viewController: self, core: core, items: uniqueItems, location: actionsLocation)
			self.actions = Action.sortedApplicableActions(for: actionContext)

			// Enable / disable tool-bar items depending on action availability
			for item in toolbarItems {
				if self.actions?.contains(where: {type(of:$0).identifier == item.actionIdentifier}) ?? false {
					item.isEnabled = true
				} else {
					item.isEnabled = false
				}
			}
		}

	}

	func tableView(_: UITableView, dragSessionDidEnd: UIDragSession) {
		if !self.tableView.isEditing {
			removeToolbar()
			self.actions = nil
		}
	}

	// MARK: - UIBarButtonItem Drop Delegate

	func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
		return true
	}

	func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
		return UIDropProposal(operation: .copy)
	}

	func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
		guard let button = interaction.view as? UIButton, let identifier = button.actionIdentifier  else { return }

		if let action = self.actions?.first(where: {type(of:$0).identifier == identifier}) {
			// Configure progress handler
			action.progressHandler = { [weak self] progress in
				self?.progressSummarizer?.startTracking(progress: progress)
			}

			action.completionHandler = { [weak self] _ in
			}

			// Execute the action
			action.willRun()
			action.run()
		}
	}

	func dragInteraction(_ interaction: UIDragInteraction,
						 session: UIDragSession,
						 didEndWith operation: UIDropOperation) {
		removeToolbar()
	}

	// MARK: - Message
	var messageView : UIView?
	var messageContainerView : UIView?
	var messageImageView : VectorImageView?
	var messageTitleLabel : UILabel?
	var messageMessageLabel : UILabel?
	var messageThemeApplierToken : ThemeApplierToken?
	var messageShowsSortBar : Bool = false

	func message(show: Bool, imageName : String? = nil, title : String? = nil, message : String? = nil, showSortBar : Bool = false) {
		if !show || (show && (messageShowsSortBar != showSortBar)) {
			if messageView?.superview != nil {
				messageView?.removeFromSuperview()
			}
			if !show {
				return
			}
		}

		if messageView == nil {
			var rootView : UIView
			var containerView : UIView
			var imageView : VectorImageView
			var titleLabel : UILabel
			var messageLabel : UILabel

			rootView = UIView()
			rootView.translatesAutoresizingMaskIntoConstraints = false

			containerView = UIView()
			containerView.translatesAutoresizingMaskIntoConstraints = false

			imageView = VectorImageView()
			imageView.translatesAutoresizingMaskIntoConstraints = false

			titleLabel = UILabel()
			titleLabel.translatesAutoresizingMaskIntoConstraints = false

			messageLabel = UILabel()
			messageLabel.translatesAutoresizingMaskIntoConstraints = false
			messageLabel.numberOfLines = 0
			messageLabel.textAlignment = .center

			containerView.addSubview(imageView)
			containerView.addSubview(titleLabel)
			containerView.addSubview(messageLabel)

			containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[imageView]-(20)-[titleLabel]-[messageLabel]|",
										   options: NSLayoutConstraint.FormatOptions(rawValue: 0),
										   metrics: nil,
										   views: ["imageView" : imageView, "titleLabel" : titleLabel, "messageLabel" : messageLabel])
						   )

			imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
			imageView.widthAnchor.constraint(equalToConstant: 96).isActive = true
			imageView.heightAnchor.constraint(equalToConstant: 96).isActive = true

			titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
			titleLabel.leftAnchor.constraint(greaterThanOrEqualTo: containerView.leftAnchor).isActive = true
			titleLabel.rightAnchor.constraint(lessThanOrEqualTo: containerView.rightAnchor).isActive = true

			messageLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
			messageLabel.leftAnchor.constraint(greaterThanOrEqualTo: containerView.leftAnchor).isActive = true
			messageLabel.rightAnchor.constraint(lessThanOrEqualTo: containerView.rightAnchor).isActive = true

			rootView.addSubview(containerView)

			containerView.centerXAnchor.constraint(equalTo: rootView.centerXAnchor).isActive = true
			containerView.centerYAnchor.constraint(equalTo: rootView.centerYAnchor).isActive = true

			containerView.leftAnchor.constraint(greaterThanOrEqualTo: rootView.leftAnchor, constant: 20).isActive = true
			containerView.rightAnchor.constraint(lessThanOrEqualTo: rootView.rightAnchor, constant: -20).isActive = true
			containerView.topAnchor.constraint(greaterThanOrEqualTo: rootView.topAnchor, constant: 20).isActive = true
			containerView.bottomAnchor.constraint(lessThanOrEqualTo: rootView.bottomAnchor, constant: -20).isActive = true

			messageView = rootView
			messageContainerView = containerView
			messageImageView = imageView
			messageTitleLabel = titleLabel
			messageMessageLabel = messageLabel

			messageThemeApplierToken = Theme.shared.add(applier: { [weak self] (_, collection, _) in
				self?.messageView?.backgroundColor = collection.tableBackgroundColor

				self?.messageTitleLabel?.applyThemeCollection(collection, itemStyle: .bigTitle)
				self?.messageMessageLabel?.applyThemeCollection(collection, itemStyle: .bigMessage)
			})
		}

		if messageView?.superview == nil {
			if let rootView = self.messageView, let containerView = self.messageContainerView {
				containerView.alpha = 0
				containerView.transform = CGAffineTransform(translationX: 0, y: 15)

				rootView.alpha = 0

				self.view.addSubview(rootView)

				rootView.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor).isActive = true
				rootView.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor).isActive = true
				if showSortBar {
					rootView.topAnchor.constraint(equalTo: (sortBar?.bottomAnchor)!).isActive = true
				} else {
					rootView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
				}
				rootView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true

				messageShowsSortBar = showSortBar

				UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
					rootView.alpha = 1
				}, completion: { (_) in
					UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
						containerView.alpha = 1
						containerView.transform = CGAffineTransform.identity
					})
				})
			}
		}

		if imageName != nil {
			messageImageView?.vectorImage = Theme.shared.tvgImage(for: imageName!)
		}
		if title != nil {
			messageTitleLabel?.text = title!
		}
		if message != nil {
			messageMessageLabel?.text = message!
		}
	}

	// MARK: - Sorting
	private var sortBar: SortBar?
	private var sortMethod: SortMethod {

		set {
			UserDefaults.standard.setValue(newValue.rawValue, forKey: "sort-method")
		}

		get {
			let sort = SortMethod(rawValue: UserDefaults.standard.integer(forKey: "sort-method")) ?? SortMethod.alphabeticallyDescendant
			return sort
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
		}
	}

	// MARK: - Search
	var searchController: UISearchController?

	func upload(itemURL: URL, name: String, completionHandler: ClientActionCompletionHandler? = nil) {
		if let rootItem = query.rootItem,
		   let progress = core?.importFileNamed(name, at: rootItem, from: itemURL, isSecurityScoped: false, options: nil, placeholderCompletionHandler: nil, resultHandler: { (error, _ core, _ item, _) in
			if error != nil {
				Log.debug("Error uploading \(Log.mask(name)) file to \(Log.mask(rootItem.path))")
				completionHandler?(false)
			} else {
				Log.debug("Success uploading \(Log.mask(name)) file to \(Log.mask(rootItem.path))")
				completionHandler?(true)
			}
		}) {
			self.progressSummarizer?.startTracking(progress: progress)
		}
	}

	func upload(asset:PHAsset) {
		let ressources = PHAssetResource.assetResources(for: asset)
		if let ressource = ressources.first {
			let filename = ressource.originalFilename

			let progress = Progress(totalUnitCount: 100)
			progress.localizedDescription = String(format: "Importing '%@' from photo library".localized, filename)

			let options = PHAssetResourceRequestOptions()
			options.isNetworkAccessAllowed = true
			options.progressHandler = { (completed:Double) in
				progress.completedUnitCount = Int64(completed * 100)
			}

			let localURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)

			self.progressSummarizer?.startTracking(progress: progress)
			PHAssetResourceManager.default().writeData(for: ressource, toFile: localURL, options: options) { (error) in
				self.progressSummarizer?.stopTracking(progress: progress)
				if error == nil {
					self.upload(itemURL: localURL, name: filename, completionHandler: { (_) in
						// Delete the temporary asset file
						try? FileManager.default.removeItem(at: localURL)
					})
				} else {
					progress.cancel()
				}
			}
		}
	}

	// MARK: - Toolbar actions handling multiple selected items
	fileprivate func updateSelectDeselectAllButton() {
		var selectedCount = 0
		if let selectedIndexPaths = self.tableView.indexPathsForSelectedRows {
			selectedCount = selectedIndexPaths.count
		}

		if selectedCount == self.items.count {
			selectDeselectAllButtonItem?.title = "Deselect All".localized
			selectDeselectAllButtonItem?.target = self
			selectDeselectAllButtonItem?.action = #selector(deselectAllItems)
		} else {
			selectDeselectAllButtonItem?.title = "Select All".localized
			selectDeselectAllButtonItem?.target = self
			selectDeselectAllButtonItem?.action = #selector(selectAllItems)
		}
	}

	fileprivate func updateMultiSelectionUI() {
		guard let tabBarController = self.tabBarController as? ClientRootViewController else { return }

		guard let toolbarItems = tabBarController.toolbar?.items else { return }

		updateSelectDeselectAllButton()

		// Do we have selected items?
		if let selectedIndexPaths = self.tableView.indexPathsForSelectedRows {
			if selectedIndexPaths.count > 0 {

				if let core = self.core {
					// Get array of OCItems from selected table view index paths
					var selectedItems = [OCItem]()
					for indexPath in selectedIndexPaths {
						selectedItems.append(itemAtIndexPath(indexPath))
					}

					// Get possible associated actions
					let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .toolbar)
					let actionContext = ActionContext(viewController: self, core: core, items: selectedItems, location: actionsLocation)

					self.actions = Action.sortedApplicableActions(for: actionContext)

					// Enable / disable tool-bar items depending on action availability
					for item in toolbarItems {
						if self.actions?.contains(where: {type(of:$0).identifier == item.actionIdentifier}) ?? false {
							item.isEnabled = true
						} else {
							item.isEnabled = false
						}
					}
				}
			}
		} else {
			self.actions = nil
			for item in toolbarItems {
				item.isEnabled = false
			}
		}
	}

	func leaveMultipleSelection() {
		self.tableView.setEditing(false, animated: true)
		selectBarButton?.title = "Select".localized
		self.navigationItem.rightBarButtonItems = [selectBarButton!, uploadBarButton!]
		self.navigationItem.leftBarButtonItem = nil
		removeToolbar()
	}

	func populateToolbar() {
		self.populateToolbar(with: [
			openMultipleBarButtonItem!,
			flexibleSpaceBarButton,
			moveMultipleBarButtonItem!,
			flexibleSpaceBarButton,
			copyMultipleBarButtonItem!,
			flexibleSpaceBarButton,
			duplicateMultipleBarButtonItem!,
			flexibleSpaceBarButton,
			deleteMultipleBarButtonItem!])
	}

	@objc func actOnMultipleItems(_ sender: UIButton) {
		// Find associated action
		if let action = self.actions?.first(where: {type(of:$0).identifier == sender.actionIdentifier}) {
			// Configure progress handler
			action.progressHandler = { [weak self] progress in
				self?.progressSummarizer?.startTracking(progress: progress)
			}

			action.completionHandler = { [weak self] _ in
				DispatchQueue.main.async {
					self?.leaveMultipleSelection()
				}
			}

			// Execute the action
			action.willRun()
			action.run()
		}
	}

	// MARK: - Navigation Bar Actions
	@objc func multipleSelectionButtonPressed(_ sender: UIBarButtonItem) {

		if !self.tableView.isEditing {
			updateMultiSelectionUI()
			self.tableView.setEditing(true, animated: true)

			populateToolbar()

			self.navigationItem.leftBarButtonItem = selectDeselectAllButtonItem!
			self.navigationItem.rightBarButtonItems = [exitMultipleSelectionBarButtonItem!]

			updateMultiSelectionUI()
		}
	}

	@objc func exitMultipleSelection(_ sender: UIBarButtonItem) {
		leaveMultipleSelection()
	}

	@objc func selectAllItems(_ sender: UIBarButtonItem) {
		(0..<self.items.count).map { (item) -> IndexPath in
			return IndexPath(item: item, section: 0)
			}.forEach { (indexPath) in
				self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
		}
		updateMultiSelectionUI()
	}

	@objc func deselectAllItems(_ sender: UIBarButtonItem) {

		self.tableView.indexPathsForSelectedRows?.forEach({ (indexPath) in
			self.tableView.deselectRow(at: indexPath, animated: true)
		})
		updateMultiSelectionUI()
	}

	@objc func uploadsBarButtonPressed(_ sender: UIBarButtonItem) {

		let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		let photoLibrary = UIAlertAction(title: "Upload from your photo library".localized, style: .default, handler: { (_) in

			func presentImageGalleryPicker() {

				let photoAlbumViewController = PhotoAlbumTableViewController()
				photoAlbumViewController.selectionCallback = { (assets) in
					for asset in assets {
						self.upload(asset: asset)
					}
				}
				let navigationController = ThemeNavigationController(rootViewController: photoAlbumViewController)

				OnMainThread {
					self.present(navigationController, animated: true)
				}
			}

			let permisson = PHPhotoLibrary.authorizationStatus()
			switch permisson {

			case .authorized:
				presentImageGalleryPicker()
			case .notDetermined:
				PHPhotoLibrary.requestAuthorization({ newStatus in
					if newStatus == .authorized {
						presentImageGalleryPicker()
					}
				})

			default:
				PHPhotoLibrary.requestAuthorization({ newStatus in

					if newStatus == .denied {
						let alert = UIAlertController(title: "Missing permissions".localized, message: "This permission is needed to upload photos and videos from your photo library.".localized, preferredStyle: .alert)

						let settingAction = UIAlertAction(title: "Settings".localized, style: .default, handler: { _ in
							UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
						})
						let notNowAction = UIAlertAction(title: "Not now".localized, style: .cancel)

						alert.addAction(settingAction)
						alert.addAction(notNowAction)

						OnMainThread {
							self.present(alert, animated: true)
						}
					}
				})
			}
		})

		let uploadFileAction = UIAlertAction(title: "Upload file".localized, style: .default) { _ in
			let documentPickerViewController = UIDocumentPickerViewController(documentTypes: [kUTTypeData as String], in: .import)
			documentPickerViewController.delegate = self
			documentPickerViewController.allowsMultipleSelection = true
			self.present(documentPickerViewController, animated: true)
		}

		let cancelAction = UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil)
		controller.addAction(photoLibrary)
		controller.addAction(uploadFileAction)
		controller.addAction(cancelAction)

		if let popoverController = controller.popoverPresentationController {
			popoverController.barButtonItem = sender
		}
		self.present(controller, animated: true)
	}

	// MARK: - Path Bread Crumb Action
	@objc func showPathBreadCrumb(_ sender: UIButton) {
		let tableViewController = BreadCrumbTableViewController()
		tableViewController.modalPresentationStyle = UIModalPresentationStyle.popover
		tableViewController.parentNavigationController = self.navigationController
		tableViewController.queryPath = (query.queryPath as NSString?)!

		let popoverPresentationController = tableViewController.popoverPresentationController
		popoverPresentationController?.sourceView = sender
		popoverPresentationController?.delegate = self
		popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: sender.frame.size.width, height: sender.frame.size.height)

		present(tableViewController, animated: true, completion: nil)
	}

	// MARK: - UIPopoverPresentationControllerDelegate
	func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
		return .none
	}
}

// MARK: - Query Delegate
extension ClientQueryViewController : OCQueryDelegate {
	func query(_ query: OCQuery, failedWithError error: Error) {
		// Not applicable atm
	}

	func queryHasChangesAvailable(_ query: OCQuery) {
		query.requestChangeSet(withFlags: OCQueryChangeSetRequestFlag(rawValue: 0)) { (query, changeSet) in
			OnMainThread {

				switch query.state {
				case .idle, .targetRemoved, .contentsFromCache, .stopped:
					if self.queryRefreshControl!.isRefreshing {
						self.queryRefreshControl?.endRefreshing()
					}
				default: break
				}

				let previousItemCount = self.items.count

				self.items = changeSet?.queryResult ?? []

				switch query.state {
				case .contentsFromCache, .idle, .waitingForServerReply:
					if previousItemCount == 0, self.items.count == 0, query.state == .waitingForServerReply {
						break
					}

					if self.items.count == 0 {
						if self.searchController?.searchBar.text != "" {
							self.message(show: true, imageName: "icon-search", title: "No matches".localized, message: "There is no results for this search".localized)
						} else {
							self.message(show: true, imageName: "folder", title: "Empty folder".localized, message: "This folder contains no files or folders.".localized, showSortBar : true)
						}
					} else {
						self.message(show: false)
					}

					self.reloadTableData()

				case .targetRemoved:
					self.message(show: true, imageName: "folder", title: "Folder removed".localized, message: "This folder no longer exists on the server.".localized)
					self.reloadTableData()

				default:
					self.message(show: false)
				}
			}
		}
	}
}

// MARK: - SortBar Delegate
extension ClientQueryViewController : SortBarDelegate {
	func sortBar(_ sortBar: SortBar, leftButtonPressed: UIButton) {
		guard let core = self.core, let rootItem = query.rootItem else { return }

		let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .sortBar)
		let actionContext = ActionContext(viewController: self, core: core, items: [rootItem], location: actionsLocation)

		let actions = Action.sortedApplicableActions(for: actionContext)

		let createFolderAction = actions.first
		createFolderAction?.progressHandler = { [weak self] progess in
			self?.progressSummarizer?.startTracking(progress: progess)
		}

		actions.first?.run()
	}

	func sortBar(_ sortBar: SortBar, rightButtonPressed: UIButton) {
		print("LOG ---> right button pressed")
	}

	func sortBar(_ sortBar: SortBar, didUpdateSortMethod: SortMethod) {
		sortMethod = didUpdateSortMethod
		query.sortComparator = sortMethod.comparator()
	}

	func sortBar(_ sortBar: SortBar, presentViewController: UIViewController, animated: Bool, completionHandler: (() -> Void)?) {
		self.present(presentViewController, animated: animated, completion: completionHandler)
	}
}

// MARK: - UISearchResultsUpdating Delegate
extension ClientQueryViewController: UISearchResultsUpdating {
	func updateSearchResults(for searchController: UISearchController) {
		let searchText = searchController.searchBar.text!

		let filterHandler: OCQueryFilterHandler = { (_, _, item) -> Bool in
			if let itemName = item?.name {
				return itemName.localizedCaseInsensitiveContains(searchText)
			}
			return false
		}

		if searchText == "" {
			if let filter = query.filter(withIdentifier: "text-search") {
				query.removeFilter(filter)
			}
		} else {
			if let filter = query.filter(withIdentifier: "text-search") {
				query.updateFilter(filter, applyChanges: { filterToChange in
					(filterToChange as? OCQueryFilter)?.filterHandler = filterHandler
				})
			} else {
				query.addFilter(OCQueryFilter.init(handler: filterHandler), withIdentifier: "text-search")
			}
		}
	}
}

// MARK: - ClientItemCell Delegate
extension ClientQueryViewController: ClientItemCellDelegate {
	func moreButtonTapped(cell: ClientItemCell) {
		guard let indexPath = self.tableView.indexPath(for: cell), let core = self.core else {
			return
		}

		let item = self.itemAtIndexPath(indexPath)

		let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .moreItem)
		let actionContext = ActionContext(viewController: self, core: core, items: [item], location: actionsLocation)

		let moreViewController = Action.cardViewController(for: item, with: actionContext, progressHandler: { [weak self] progress in
			self?.progressSummarizer?.startTracking(progress: progress)
		})

		self.present(asCard: moreViewController, animated: true)
	}
}

extension ClientQueryViewController: UITableViewDropDelegate {
	func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
		guard let core = self.core else { return }

		for item in coordinator.items {
			if item.dragItem.localObject != nil {
				var destinationItem: OCItem

				guard let item = item.dragItem.localObject as? OCItem, let itemName = item.name else {
					return
				}

				if coordinator.proposal.intent == .insertIntoDestinationIndexPath {

					guard let destinationIndexPath = coordinator.destinationIndexPath else {
						return
					}

					guard items.count >= destinationIndexPath.row else {
						return
					}

					let rootItem = items[destinationIndexPath.row]

					guard rootItem.type == .collection else {
						return
					}

					destinationItem = rootItem

				} else {

					guard let rootItem = self.query.rootItem, item.parentFileID != rootItem.fileID else {
						return
					}

					destinationItem =  rootItem

				}

				if let progress = core.move(item, to: destinationItem, withName: itemName, options: nil, resultHandler: { (error, _, _, _) in
					if error != nil {
						Log.log("Error \(String(describing: error)) moving \(String(describing: item.path))")
					}
				}) {
					self.progressSummarizer?.startTracking(progress: progress)
				}
			} else {
				guard let UTI = item.dragItem.itemProvider.registeredTypeIdentifiers.last else { return }
				item.dragItem.itemProvider.loadFileRepresentation(forTypeIdentifier: UTI) { (url, _ error) in
					guard let url = url else { return }
					self.upload(itemURL: url, name: url.lastPathComponent)
				}
			}
		}
	}
}

extension ClientQueryViewController: UITableViewDragDelegate {

	func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {

		if !self.tableView.isEditing {
			self.populateToolbar()
		}

		var selectedItems = [OCItem]()
		// Add Items from Multiselection too
		if let selectedIndexPaths = self.tableView.indexPathsForSelectedRows {
			if selectedIndexPaths.count > 0 {
				for indexPath in selectedIndexPaths {
					selectedItems.append(itemAtIndexPath(indexPath))
				}
			}
		}
		for dragItem in session.items {
			guard let item = dragItem.localObject as? OCItem else { continue }
			selectedItems.append(item)
		}

		let item: OCItem = itemAtIndexPath(indexPath)
		selectedItems.append(item)
		updateToolbarItemsForDropping(selectedItems)

		guard let dragItem = itemForDragging(item: item) else { return [] }
		return [dragItem]
	}

	func tableView(_ tableView: UITableView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
		var selectedItems = [OCItem]()
		for dragItem in session.items {
			guard let item = dragItem.localObject as? OCItem else { continue }
			selectedItems.append(item)
		}

		let item: OCItem = itemAtIndexPath(indexPath)
		selectedItems.append(item)
		updateToolbarItemsForDropping(selectedItems)

		guard let dragItem = itemForDragging(item: item) else { return [] }
		return [dragItem]
	}

	func itemForDragging(item : OCItem) -> UIDragItem? {
		if let core = self.core {
			switch item.type {
			case .collection:
				guard let data = item.serializedData() else { return nil }
				let itemProvider = NSItemProvider(item: data as NSData, typeIdentifier: kUTTypeData as String)
				let dragItem = UIDragItem(itemProvider: itemProvider)
				dragItem.localObject = item
				return dragItem
			case .file:
				guard let rawUti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, item.mimeType as! CFString, nil)?.takeRetainedValue() else { return nil }

				if let fileData = NSData(contentsOf: core.localURL(for: item)) {
					let itemProvider = NSItemProvider(item: fileData, typeIdentifier: rawUti as! String)
					itemProvider.suggestedName = item.name
					let dragItem = UIDragItem(itemProvider: itemProvider)
					dragItem.localObject = item
					return dragItem
				} else {
					guard let data = item.serializedData() else { return nil }
					let itemProvider = NSItemProvider(item: data as NSData, typeIdentifier: kUTTypeData as String)
					let dragItem = UIDragItem(itemProvider: itemProvider)
					dragItem.localObject = item
					return dragItem
				}
			}
		}

		return nil
	}
}

// MARK: - UIDocumentPickerDelegate
extension ClientQueryViewController: UIDocumentPickerDelegate {

	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		for url in urls {
			self.upload(itemURL: url, name: url.lastPathComponent)
		}
	}
}

// MARK: - UINavigationControllerDelegate
extension ClientQueryViewController: UINavigationControllerDelegate {}
