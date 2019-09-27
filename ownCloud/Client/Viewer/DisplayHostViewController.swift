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

class DisplayHostViewController: UIPageViewController {

	enum PagePosition {
		case before, after
	}

	// MARK: - Constants
	let imageFilterRegexp: String = "\\A((image/*))" // Filters all the mime types that are images (incluiding gif and svg)

	// MARK: - Instance Variables
	weak private var core: OCCore?

	private var initialItem: OCItem
	private var displayedIndex: Int?

	public var items: [OCItem]?

	private var query: OCQuery
	private var queryStarted : Bool = false
	private weak var viewControllerToTansition: DisplayViewController?
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
				if let queryResult = changeSet.queryResult, let newItems = self?.applyImageFilesFilter(items: queryResult) {
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
		if queryStarted {
			core?.stop(query)
			queryStarted = false
		}

		queryObservation?.invalidate()
		Theme.shared.unregister(client: self)
	}

	// MARK: - ViewController lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()

		self.dataSource = self
		self.delegate = self

		if let initialViewController = viewController(for: self.initialItem) {
			self.setViewControllers([initialViewController], direction: .forward, animated: false, completion: nil)

			if let displayController = initialViewController as? DisplayViewController, let items = self.items, let initialID = self.initialItem.localID,
				let currentIndex = items.firstIndex(where: {$0.localID == initialID}) {
				self.displayedIndex = currentIndex
				displayController.itemIndex = currentIndex
			}
		}
	}

	override var childForHomeIndicatorAutoHidden : UIViewController? {
		if let childViewController = self.children.first {
			return childViewController
		}
		return nil
	}

	// MARK: - Extension selection
	private func selectDisplayViewControllerBasedOn(mimeType: String) -> (DisplayViewController) {

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

		displayViewController.progressSummarizer = progressSummarizer

		return displayViewController
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

							currentDisplayViewController.removeFromParent()

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

	private func viewControllerAtIndex(index: Int) -> UIViewController? {
		guard let items = items else { return nil }

		guard index >= 0, index < items.count else { return nil }

		let item = items[index]

		let viewController = self.viewController(for: item)
		(viewController as? DisplayViewController)?.itemIndex = index

		return viewController
	}

	private func viewController(for item:OCItem) -> UIViewController? {

		guard let mimeType = item.mimeType else { return nil }

		let newViewController = selectDisplayViewControllerBasedOn(mimeType: mimeType)
		let configuration = configurationFor(item, viewController: newViewController)

		self.addChild(newViewController)
		newViewController.didMove(toParent: self)

		newViewController.configure(configuration)
		newViewController.present(item: item)

		return newViewController
	}

	private func configurationFor(_ item: OCItem, viewController: UIViewController) -> DisplayViewConfiguration {
		let shouldDownload = viewController is (DisplayViewController & DisplayExtension) ? true : false
		var configuration: DisplayViewConfiguration
		if !shouldDownload {
			configuration = DisplayViewConfiguration(item: item, core: core, state: .notSupportedMimeType)
		} else {
			configuration = DisplayViewConfiguration(item: item, core: core, state: .hasNetworkConnection)
		}
		return configuration
	}

	// MARK: - Filters
	private func applyImageFilesFilter(items: [OCItem]) -> [OCItem] {
		if initialItem.mimeType?.matches(regExp: imageFilterRegexp) ?? false {
			let filteredItems = items.filter({$0.type != .collection && $0.mimeType?.matches(regExp: self.imageFilterRegexp) ?? false})
			return filteredItems
		} else {
			let filteredItems = items.filter({$0.type != .collection && $0.fileID == self.initialItem.fileID})
			return filteredItems
		}
	}
}

extension DisplayHostViewController: UIPageViewControllerDataSource {

	private func vendNewViewController(from viewController:UIViewController, _ position:PagePosition) -> UIViewController? {
		guard let displayViewController = viewControllers?.first as? DisplayViewController else { return nil }
		guard let item = displayViewController.item, let items = self.items else { return nil }

		// Is the item assigned to the currently visible view controller still available?
		let index = items.firstIndex(where: {$0.localID == item.localID})

		if index != nil {
			// If so, then vend view controller with the item next to the current item
			if let nextIndex = computeNewIndex(for: index!, itemCount:items.count, position: position) {
				return viewControllerAtIndex(index: nextIndex)
			}

		} else {
			// Currently visible item was deleted or moved, use it's old index to find a new one
			if let index = displayViewController.itemIndex {
				if let nextIndex = computeNewIndex(for: index, itemCount:items.count, position: position, indexFound: false) {
					return viewControllerAtIndex(index: nextIndex)
				}
			}
		}

		return nil
	}

	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		return vendNewViewController(from: viewController, .after)
	}

	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
		return vendNewViewController(from: viewController, .before)
	}
}

extension DisplayHostViewController: UIPageViewControllerDelegate {
	func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {

		let previousViewController = previousViewControllers[0]
		previousViewController.didMove(toParent: nil)

		if completed, let viewControllerToTransition = self.viewControllerToTansition {
			if self.children.contains(viewControllerToTransition) == false {
				self.addChild(viewControllerToTransition)
			}
			viewControllerToTransition.didMove(toParent: self)
			viewControllerToTransition.updateNavigationBarItems()
		}
	}

	func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
		guard pendingViewControllers.isEmpty == false else { return }

		if let viewControllerToTransition = pendingViewControllers[0] as? DisplayViewController {
			self.viewControllerToTansition = viewControllerToTransition
		}
	}
}

extension DisplayHostViewController: Themeable {
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.view.backgroundColor = .black
	}
}
