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

class DisplayHostViewController: UIPageViewController {

	enum PagePosition {
		case before, after
	}

	// MARK: - Constants
	let mediaFilterRegexp: String = "\\A(((image|audio|video)/*))" // Filters all the mime types that are images (incluiding gif and svg)

	// MARK: - Instance Variables
	weak var core: OCCore?

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

	private var query: OCQuery
	private var queryStarted : Bool = false
	private var queryObservation : NSKeyValueObservation?

	var progressSummarizer : ProgressSummarizer?

	// MARK: - Init & deinit
	init(core: OCCore, selectedItem: OCItem, query: OCQuery) {
		self.core = core
		self.initialItem = selectedItem
		self.query = query

		super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)

		if query.state == .stopped {
			self.core?.start(query)
			queryStarted = true
		}

		queryObservation = query.observe(\OCQuery.hasChangesAvailable, options: [.initial, .new]) { [weak self] (query, _) in
			//guard self?.items == nil else { return }

			query.requestChangeSet(withFlags: .onlyResults) { ( _, changeSet) in
				guard let changeSet = changeSet  else { return }
				if let queryResult = changeSet.queryResult, let newItems = self?.applyMediaFilesFilter(items: queryResult) {
					let shallUpdateDatasource = self?.items?.count != newItems.count ? true : false

					self?.items = newItems

					if shallUpdateDatasource {
						self?.updateDatasource()
					}
				}
			}
		}

		Theme.shared.register(client: self)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		NotificationCenter.default.removeObserver(self, name: MediaDisplayViewController.MediaPlaybackFinishedNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: MediaDisplayViewController.MediaPlaybackNextTrackNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: MediaDisplayViewController.MediaPlaybackPreviousTrackNotification, object: nil)

		queryObservation?.invalidate()
		queryObservation = nil

		if queryStarted {
			core?.stop(query)
			queryStarted = false
		}

		Theme.shared.unregister(client: self)
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
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

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
	private var _navigationTitleObservation : NSKeyValueObservation?
	private var _navigationBarButtonItemsObservation : NSKeyValueObservation?

	weak var activeDisplayViewController : DisplayViewController? {
		willSet {
			_navigationTitleObservation?.invalidate()
			_navigationTitleObservation = nil

			_navigationBarButtonItemsObservation?.invalidate()
			_navigationBarButtonItemsObservation = nil
		}

		didSet {
			Log.debug("New activeDisplayViewController: \(activeDisplayViewController?.item?.name ?? "-")")

			_navigationTitleObservation = activeDisplayViewController?.observe(\DisplayViewController.displayTitle, options: .initial, changeHandler: { [weak self] (displayViewController, _) in
				self?.navigationItem.title = displayViewController.displayTitle
			})

			_navigationBarButtonItemsObservation = activeDisplayViewController?.observe(\DisplayViewController.displayBarButtonItems, options: .initial, changeHandler: { [weak self] (displayViewController, _) in
				self?.navigationItem.rightBarButtonItems = displayViewController.displayBarButtonItems
			})
		}
	}

	// MARK: - Helper methods
	private func updateDatasource() {
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
		let context = OCExtensionContext(location: location, requirements: nil, preferences: nil)

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
		newViewController.core = core
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
	private func applyMediaFilesFilter(items: [OCItem]) -> [OCItem] {
		if initialItem.mimeType?.matches(regExp: mediaFilterRegexp) ?? false {
			let filteredItems = items.filter({$0.type != .collection && $0.mimeType?.matches(regExp: self.mediaFilterRegexp) ?? false})
			return filteredItems
		} else {
			let filteredItems = items.filter({$0.type != .collection && $0.fileID == self.initialItem.fileID})
			return filteredItems
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
		}
	}
}

extension DisplayHostViewController: Themeable {
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.view.backgroundColor = collection.tableBackgroundColor
	}
}

extension DisplayHostViewController {

	@objc private func handleMediaPlaybackFinished(notification:Notification) {
		if let mediaController = activeDisplayViewController as? MediaDisplayViewController {
			if let displayViewController = adjacentViewController(relativeTo: mediaController, .after, includeOnlyMediaItems: true) as? MediaDisplayViewController {
				self.setViewControllers([displayViewController], direction: .forward, animated: false, completion: nil)
				activeDisplayViewController = displayViewController
			}
		}
	}

	@objc private func handlePlayNextMedia(notification:Notification) {
		if let mediaController = activeDisplayViewController as? MediaDisplayViewController {
			if let displayViewController = adjacentViewController(relativeTo: mediaController, .after, includeOnlyMediaItems: true) as? MediaDisplayViewController {
				self.setViewControllers([displayViewController], direction: .forward, animated: false, completion: nil)
				activeDisplayViewController = displayViewController
			}
		}
	}

	@objc private func handlePlayPreviousMedia(notification:Notification) {
		if let mediaController = activeDisplayViewController as? MediaDisplayViewController {
			if let displayViewController = adjacentViewController(relativeTo: mediaController, .before, includeOnlyMediaItems: true) as? MediaDisplayViewController {
				self.setViewControllers([displayViewController], direction: .forward, animated: false, completion: nil)
				activeDisplayViewController = displayViewController
			}
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
