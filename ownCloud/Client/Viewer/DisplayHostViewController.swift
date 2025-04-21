//
//  DisplayHostViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 14/02/2019.
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
import ownCloudAppShared

class DisplayExtensionContext: OCExtensionContext {
	public var clientContext: ClientContext?
}

class DisplayHostViewController: UIPageViewController {
	enum PagePosition {
		case before, after
	}

	// MARK: - Constants
	let mediaFilterRegexp: String = "\\A(((image|audio|video)/*))" // Filters all the mime types that are images (including gif and svg)

	// MARK: - Instance Variables
	public var clientContext : ClientContext?

	private var initialItem: OCItem

	public var items: [OCItem]? {
		didSet {
			playableItems = items?.filter({ $0.isPlayable })
			OnMainThread {
				self.autoEnablePageScrolling()
			}
		}
	}

	private var playableItems: [OCItem]?

	private var parentFolderQuery: OCQuery?

	private var queryDatasource: OCDataSource?
	private var queryDatasourceSubscription: OCDataSourceSubscription?

	var progressSummarizer : ProgressSummarizer?

	// MARK: - Init & deinit
	init(clientContext inClientContext: ClientContext? = nil, core: OCCore? = nil, selectedItem: OCItem, queryDataSource inQueryDataSource: OCDataSource? = nil) {
		var clientContext = inClientContext

		initialItem = selectedItem
		queryDatasource = inQueryDataSource ?? clientContext?.queryDatasource

		if queryDatasource == nil, let parentLocation = selectedItem.location?.parent, let core = clientContext?.core {
			// If no data source was given, create one for the parent location
			let query = OCQuery(for: parentLocation)
			core.start(query)

			parentFolderQuery = query
			queryDatasource = parentFolderQuery?.queryResultsDataSource

			clientContext = ClientContext(with: inClientContext)
			clientContext?.queryDatasource = queryDatasource
		}

		super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)

		self.clientContext = ClientContext(with: clientContext, originatingViewController: self)

		if let queryDatasource {
			queryDatasourceSubscription = queryDatasource.subscribe(updateHandler: { [weak self]  subscription in
				guard let self = self, let queryDataSource = self.queryDatasource else {
					return
				}

				let snapshot = subscription.snapshotResettingChangeTracking(true)
				var allItems : [OCItem] = []

				for itemRef in snapshot.items {
					if let itemRecord = try? queryDataSource.record(forItemRef: itemRef) {
						if let item = itemRecord.item as? OCItem {
							allItems.append(item)
						}
					}
				}

				self.items = self.applyMediaFilesFilter(items: allItems)

				self.updatePageViewControllerDatasource()
			}, on: .main, trackDifferences: true, performInitialUpdate: true)
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func windDown() {
		NotificationCenter.default.removeObserver(self, name: MediaDisplayViewController.MediaPlaybackFinishedNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: MediaDisplayViewController.MediaPlaybackNextTrackNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: MediaDisplayViewController.MediaPlaybackPreviousTrackNotification, object: nil)

		queryDatasourceSubscription?.terminate()

		if let parentFolderQuery {
			clientContext?.core?.stop(parentFolderQuery)
		}

		Theme.shared.unregister(client: self)
	}

	deinit {
		windDown()
	}

	// MARK: - ViewController lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()

		self.dataSource = self
		self.delegate = self

		var initialIndex : Int?

		if let items = self.items,
		   let initialItemLocalID = self.initialItem.localID,
		   let itemIndex = items.firstIndex(where: {$0.localID == initialItemLocalID}) {
			initialIndex = itemIndex
		}

		if let initialViewController = viewController(for: self.initialItem, at: initialIndex) {
			self.setViewControllers([initialViewController], direction: .forward, animated: false, completion: nil)

			activeDisplayViewController = initialViewController as? DisplayViewController
		}

		NotificationCenter.default.addObserver(self, selector: #selector(handleMediaPlaybackFinished(notification:)), name: MediaDisplayViewController.MediaPlaybackFinishedNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handlePlayNextMedia(notification:)), name: MediaDisplayViewController.MediaPlaybackNextTrackNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handlePlayPreviousMedia(notification:)), name: MediaDisplayViewController.MediaPlaybackPreviousTrackNotification, object: nil)

		addKeyCommand(UIKeyCommand.ported(input: UIKeyCommand.inputLeftArrow, modifierFlags: .shift, action: #selector(keyCommandPreviousItem), discoverabilityTitle: OCLocalizedString("Previous item", nil)))
		addKeyCommand(UIKeyCommand.ported(input: UIKeyCommand.inputRightArrow, modifierFlags: .shift, action: #selector(keyCommandNextItem), discoverabilityTitle: OCLocalizedString("Next item", nil)))

		let hoverRecognizer = UIHoverGestureRecognizer(target: self, action: #selector(handleHover(_:)))
		view.addGestureRecognizer(hoverRecognizer)

		view.addSubview(previousButton)
		view.addSubview(nextButton)

		NSLayoutConstraint.activate([
			previousButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10),
			previousButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
			nextButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10),
			nextButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		])
	}

	private var registered = false
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		if !registered {
			registered = true
			Theme.shared.register(client: self)
		}

		self.autoEnablePageScrolling()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		DisplaySleepPreventer.shared.stopPreventingDisplaySleep(for: PresentationModeAction.reason)
	}

	override var childForHomeIndicatorAutoHidden : UIViewController? {
		if let childViewController = self.children.first {
			return childViewController
		}
		return nil
	}

	// MARK: - Active Viewer
	private var _navigationItemObservation : NSKeyValueObservation?
	private var _navigationBarButtonItemsObservation : NSKeyValueObservation?

	weak var activeDisplayViewController : DisplayViewController? {
		willSet {
			_navigationItemObservation?.invalidate()
			_navigationItemObservation = nil

			_navigationBarButtonItemsObservation?.invalidate()
			_navigationBarButtonItemsObservation = nil
		}

		didSet {
			Log.debug("New activeDisplayViewController: \(activeDisplayViewController?.item?.name ?? "-")")

			_navigationItemObservation = activeDisplayViewController?.observe(\DisplayViewController.item, options: .initial, changeHandler: { [weak self] (displayViewController, _) in
				if let itemLocation = displayViewController.item?.location, let clientContext = displayViewController.clientContext {
					OnMainThread(inline: true) {
						self?.navigationItem.titleView = ClientLocationPopupButton(clientContext: clientContext, location: itemLocation)
					}
				}
			})

			_navigationBarButtonItemsObservation = activeDisplayViewController?.observe(\DisplayViewController.displayBarButtonItems, options: .initial, changeHandler: { [weak self] (displayViewController, _) in
				self?.navigationItem.rightBarButtonItems = displayViewController.displayBarButtonItems
			})
		}
	}

	// MARK: - Helper methods
	private func updatePageViewControllerDatasource() {
		OnMainThread { [weak self] in
			self?.dataSource = nil
			if let itemCount = self?.items?.count {
				if itemCount > 0 {

					if let currentDisplayViewController = self?.viewControllers?.first as? DisplayViewController,
						let item = currentDisplayViewController.item,
						let index = currentDisplayViewController.itemIndex {

						let foundIndex = self?.items?.firstIndex(where: {$0.localID == item.localID})

						if foundIndex == nil {
							if index < itemCount {
								if let newIndex = self?.computeNewIndex(for: index, itemCount: itemCount, position: .after, indexFound: false),
									let newViewController = self?.viewControllerAtIndex(index: newIndex) {
									self?.setViewControllers([newViewController], direction: .forward, animated: false, completion: nil)
								}
							} else {
								if let newIndex = self?.computeNewIndex(for: index, itemCount: itemCount, position: .before, indexFound: false),
									let newViewController = self?.viewControllerAtIndex(index: newIndex) {
									self?.setViewControllers([newViewController], direction: .reverse, animated: false, completion: nil)
								}
							}
						}
					}

					self?.dataSource = self
				}
			}
		}
	}

	func computeNewIndex(for currentIndex:Int, itemCount:Int, position:PagePosition, indexFound:Bool = true) -> Int? {
		switch position {
		case .after:
			if indexFound {
				if currentIndex < (itemCount - 1) {
					return currentIndex + 1
				}
			} else {
				// If current index was moved, next element in the list will assume it's position
				if currentIndex < itemCount {
					return currentIndex
				}
			}

		case .before:
			if currentIndex > 0 {
				return currentIndex - 1
			}
		}

		return nil
	}

	private func viewControllerAtIndex(index: Int, includeOnlyMediaItems: Bool = false) -> UIViewController? {

		guard let processedItems = includeOnlyMediaItems ? playableItems : items else { return nil }

		guard index >= 0, index < processedItems.count else { return nil }

		let item = processedItems[index]

		let viewController = self.viewController(for: item, at: index)

		return viewController
	}

	private func createDisplayViewController(for mimeType: String) -> (DisplayViewController) {
		let locationIdentifier = OCExtensionLocationIdentifier(rawValue: mimeType)
		let location: OCExtensionLocation = OCExtensionLocation(ofType: .viewer, identifier: locationIdentifier)
		let context = DisplayExtensionContext(location: location, requirements: nil, preferences: nil)
		context.clientContext = clientContext

		var extensions: [OCExtensionMatch]?

		do {
			try extensions = OCExtensionManager.shared.provideExtensions(for: context)
		} catch {
			return DisplayViewController()
		}

		guard let matchedExtensions = extensions else {
			return DisplayViewController()
		}

		guard matchedExtensions.count > 0 else {
			return DisplayViewController()
		}

		let preferredExtension: OCExtension = matchedExtensions[0].extension

		guard let displayViewController = preferredExtension.provideObject(for: context) as? (DisplayViewController & DisplayExtension) else {
			return DisplayViewController()
		}

		return displayViewController
	}

	private func viewController(for item: OCItem, at index: Int? = nil) -> UIViewController? {

		guard let mimeType = item.mimeType else { return nil }

		let newViewController = createDisplayViewController(for: mimeType)

		newViewController.progressSummarizer = progressSummarizer
		newViewController.core = clientContext?.core
		newViewController.itemIndex = index

		newViewController.item = item

		Log.debug("Created DisplayViewController: \(newViewController.item?.name ?? "-")")

		return newViewController
	}

	private func adjacentViewController(relativeTo viewController:UIViewController, _ position:PagePosition, includeOnlyMediaItems: Bool = false) -> UIViewController? {
		guard let displayViewController = viewControllers?.first as? DisplayViewController else { return nil }
		guard let item = displayViewController.item else { return nil }

		guard let processedItems = includeOnlyMediaItems ? playableItems : items else { return nil }

		// Is the item assigned to the currently visible view controller still available?
		let index = processedItems.firstIndex(where: {$0.localID == item.localID})

		if index != nil {
			// If so, then vend view controller with the item next to the current item
			if let nextIndex = computeNewIndex(for: index!, itemCount:processedItems.count, position: position) {
				return viewControllerAtIndex(index: nextIndex, includeOnlyMediaItems: includeOnlyMediaItems)
			}

		} else {
			// Currently visible item was deleted or moved, use it's old index to find a new one
			if let index = displayViewController.itemIndex {
				if let nextIndex = computeNewIndex(for: index, itemCount:processedItems.count, position: position, indexFound: false) {
					return viewControllerAtIndex(index: nextIndex, includeOnlyMediaItems: includeOnlyMediaItems)
				}
			}
		}

		return nil
	}

	// MARK: - Filters
	private func filtersMatch(item: OCItem?) -> Bool {
		if let mimeType = item?.mimeType,
		   !mimeType.hasPrefix("image/svg"),
		   mimeType.matches(regExp: mediaFilterRegexp) {
			return true
		}

		return false
	}

	private func applyMediaFilesFilter(items: [OCItem]) -> [OCItem] {
		if filtersMatch(item: initialItem) {
			let filteredItems = items.filter({$0.type != .collection && filtersMatch(item: $0)})
			return filteredItems
		} else {
			let filteredItems = items.filter({$0.type != .collection && $0.fileID == self.initialItem.fileID})
			return filteredItems
		}
	}

	// MARK: - Manual navigation
	func showPreviousItem(onlyMediaItems: Bool = false, animated: Bool = false) {
		guard let activeDisplayViewController, let previousViewController = adjacentViewController(relativeTo: activeDisplayViewController, .before, includeOnlyMediaItems: onlyMediaItems) as? DisplayViewController else { return }

		setViewControllers([previousViewController], direction: .reverse, animated: animated, completion: nil)
		self.activeDisplayViewController = previousViewController
	}

	func showNextItem(onlyMediaItems: Bool = false, animated: Bool = false) {
		guard let activeDisplayViewController, let nextViewController = adjacentViewController(relativeTo: activeDisplayViewController, .after, includeOnlyMediaItems: onlyMediaItems) as? DisplayViewController else { return }

		setViewControllers([nextViewController], direction: .forward, animated: animated, completion: nil)
		self.activeDisplayViewController = nextViewController
	}

	var hasPreviousItem: Bool {
		if let activeDisplayViewController {
			return (adjacentViewController(relativeTo: activeDisplayViewController, .before, includeOnlyMediaItems: false) as? DisplayViewController) != nil
		}
		return false
	}
	var hasNextItem: Bool {
		if let activeDisplayViewController {
			return (adjacentViewController(relativeTo: activeDisplayViewController, .after, includeOnlyMediaItems: false) as? DisplayViewController) != nil
		}
		return false
	}

	// MARK: - Keyboard support
	@objc func keyCommandPreviousItem() {
		showPreviousItem(animated: false)
	}

	@objc func keyCommandNextItem() {
		showNextItem(animated: false)
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}

	// MARK: - Pointer Hover (accessibility)
	private func buildButton(symbolName: String, selectors: [ThemeCSSSelector], action: @escaping () -> Void) -> UIButton {
		var buttonConfig = UIButton.Configuration.bordered()
		buttonConfig.image = OCSymbol.icon(forSymbolName: symbolName)
		buttonConfig.contentInsets = .zero

		let button = ThemeButton(withSelectors: selectors, configuration: buttonConfig)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.isHidden = true
		button.addAction(UIAction(handler: { _ in
			action()
		}), for: .primaryActionTriggered)
		return button
	}

	lazy var previousButton: UIButton = {
		return buildButton(symbolName: "chevron.left", selectors: [.buttonPrevious], action: { [weak self] in
			self?.showPreviousItem(animated: true)
		})
	}()
	lazy var nextButton: UIButton = {
		return buildButton(symbolName: "chevron.right", selectors: [.buttonNext], action: { [weak self] in
			self?.showNextItem(animated: true)
		})
	}()

	@objc func handleHover(_ recognizer: UIHoverGestureRecognizer) {
		switch recognizer.state {

			case .began, .changed:
				showButtons = true

			case .ended, .cancelled, .failed:
				showButtons = false

			default: break
		}
	}
	var showButtons: Bool = false {
		didSet {
			updateButtonsVisibility()
		}
	}
	func updateButtonsVisibility() {
		if UIDevice.current.userInterfaceIdiom == .pad { // Save unnecessary overhead on devices without pointer interface
			previousButton.isHidden = !showButtons || !hasPreviousItem
			nextButton.isHidden = !showButtons || !hasNextItem
		}
	}
}

extension DisplayHostViewController: UIPageViewControllerDataSource {
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		return adjacentViewController(relativeTo: viewController, .after)
	}

	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
		return adjacentViewController(relativeTo: viewController, .before)
	}
}

extension DisplayHostViewController: UIPageViewControllerDelegate {
	func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
		if completed, let newActiveDisplayViewController = self.viewControllers?.first as? DisplayViewController {
			activeDisplayViewController = newActiveDisplayViewController
			updateButtonsVisibility()
		}
	}
}

extension DisplayHostViewController: Themeable {
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		view.backgroundColor = collection.css.getColor(.fill, for: self.view)
	}
}

extension DisplayHostViewController {
	@objc private func handleMediaPlaybackFinished(notification:Notification) {
		if activeDisplayViewController is MediaDisplayViewController {
			showNextItem(onlyMediaItems: true, animated: false)
		}
	}

	@objc private func handlePlayNextMedia(notification:Notification) {
		if activeDisplayViewController is MediaDisplayViewController {
			showNextItem(onlyMediaItems: true, animated: false)
		}
	}

	@objc private func handlePlayPreviousMedia(notification:Notification) {
		if activeDisplayViewController is MediaDisplayViewController {
			showPreviousItem(onlyMediaItems: true, animated: false)
		}
	}
}

extension DisplayHostViewController {
	private var scrollView: UIScrollView? {
		return view.subviews.compactMap { $0 as? UIScrollView }.first
	}

	private func autoEnablePageScrolling() {
		self.scrollView?.isScrollEnabled = (self.items?.count ?? 0 < 2) ? false : true
	}
}

public extension ThemeCSSSelector {
	static let buttonPrevious = ThemeCSSSelector(rawValue: "buttonPrevious")
	static let buttonNext = ThemeCSSSelector(rawValue: "buttonNext")
}
