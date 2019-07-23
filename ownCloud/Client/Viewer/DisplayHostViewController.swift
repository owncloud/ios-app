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

	// MARK: - Constants
	let hasChangesAvailableKeyPath: String = "hasChangesAvailable"
	let imageFilterRegexp: String = "\\A((image/*))" // Filters all the mime types that are images (incluiding gif and svg)

	// MARK: - Instance Variables
	weak private var core: OCCore?

	private var lastSelectedLocalID: String?

	private var selectedItem: OCItem {
		willSet {
			// Remember last selected local ID for the case the selected item disappears and reapears again (e.g. due to some failed action)
			lastSelectedLocalID = self.selectedItem.localID
		}
	}

	private var items: [OCItem]? {
		willSet {
			if let oldItems = self.items, let newItems = newValue {
				if newItems.count > 0 {
					if oldItems.count != newItems.count {

						// Handle the case in which selected item disappears (move, delete)
						if oldItems.count > newItems.count {
							if newItems.first(where: { $0.localID == selectedItem.localID  }) == nil {
								if let deletedIndex = oldItems.index(of: selectedItem) {
									if deletedIndex < newItems.count {
										self.selectedItem = newItems[deletedIndex]
									} else {
										self.selectedItem = newItems.last!
									}
								}
							}
						}

						// Handle the case in which selected item does re-appear (e.g. upon failed move operation)
						if oldItems.count < newItems.count && lastSelectedLocalID != nil {
							if let reappearingItem = newItems.first(where: { $0.localID == lastSelectedLocalID }) {
								self.selectedItem = reappearingItem
							}
						}

						// Update data source in case number of items has changed
						OnMainThread { [weak self] in
							self?.updateDataSource(animated: true)
						}
					}

				} else {
					// If there is nothing to display, go back to the previous view in the navigation stack
					OnMainThread {  [weak self] in
						self?.navigationController?.popViewController(animated: true)
					}
				}

			}
		}
		didSet {
			OnMainThread { [weak self] in
				self?.configureScrolling()
			}
		}
	}

	private var query: OCQuery
	private var queryStarted : Bool = false
	private weak var viewControllerToTansition: DisplayViewController?
	private var queryObservation : NSKeyValueObservation?

	var progressSummarizer : ProgressSummarizer?

	// MARK: - Init & deinit
	init(core: OCCore, selectedItem: OCItem, query: OCQuery) {
		self.core = core
		self.selectedItem = selectedItem
		self.query = query

		super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)

		if query.state == .stopped {
			core.start(query)
			queryStarted = true
		}

		queryObservation = query.observe(\OCQuery.hasChangesAvailable, options: [.initial, .new]) { [weak self] (query, _) in
			query.requestChangeSet(withFlags: .onlyResults) { ( _, changeSet) in
				guard let changeSet = changeSet  else { return }
				if let queryResult = changeSet.queryResult, let items = self?.applyImageFilesFilter(items: queryResult) {
					self?.items = items
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
		updateDataSource()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		configureScrolling()
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

	private func updateDataSource(animated:Bool = false) {
		// First reset data source, to make sure that when it is again set, the page view controller does actually reload
		self.dataSource = nil
		self.dataSource = self
		self.delegate = self

		// Display first item
		guard let mimeType = self.selectedItem.mimeType else { return }

		let viewController = self.selectDisplayViewControllerBasedOn(mimeType: mimeType)
		let configuration = self.configurationFor(self.selectedItem, viewController: viewController)

		viewController.configure(configuration)

		self.setViewControllers([viewController], direction: .forward, animated: animated, completion: nil)

		viewController.present(item: self.selectedItem)
		viewController.updateNavigationBarItems()
	}

	private func viewControllerAtIndex(index: Int) -> UIViewController? {
		guard let items = items else { return nil }

		guard index >= 0, index < items.count else { return nil }

		let item = items[index]

		let newViewController = selectDisplayViewControllerBasedOn(mimeType: item.mimeType!)
		let configuration = configurationFor(item, viewController: newViewController)

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
		if selectedItem.mimeType?.matches(regExp: imageFilterRegexp) ?? false {
			let filteredItems = items.filter({$0.type != .collection && $0.mimeType?.matches(regExp: self.imageFilterRegexp) ?? false})
			return filteredItems
		} else {
			let filteredItems = items.filter({$0.type != .collection && $0.fileID == self.selectedItem.fileID})
			return filteredItems
		}
	}
}

extension DisplayHostViewController: UIPageViewControllerDataSource {
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		if let displayViewController = viewControllers?.first as? DisplayViewController,
			let item = displayViewController.item,
			let index = items?.firstIndex(where: {$0.fileID == item.fileID}) {
			return viewControllerAtIndex(index: index + 1)
		}

		return nil

	}

	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {

		if let displayViewController = viewControllers?.first as? DisplayViewController,
			let item = displayViewController.item,
			let index = items?.firstIndex(where: {$0.fileID == item.fileID}) {
			return viewControllerAtIndex(index: index - 1)
		}

		return nil
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

	private func configureScrolling() {
		guard let items = self.items else { return }
		self.dataSource = items.count > 1 ? self : nil
	}
}

extension DisplayHostViewController: Themeable {
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.view.backgroundColor = .black
	}
}
