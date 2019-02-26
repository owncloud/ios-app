//
//  AlternativePageViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 14/02/2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

class GalleryHostViewController: UIPageViewController {

	// MARK: - Instance Variables
	weak private var core: OCCore?
	private var selectedItem: OCItem
	private var items: [OCItem]?
	private var query: OCQuery
	private weak var viewControllerToTansition: DisplayViewController?

	private var itemsFilter: OCQueryFilter = {
		var itemFilterHandler: OCQueryFilterHandler = { (_, _, item) -> Bool in
			if let item = item {
				if item.type == .collection {return false}
			}
			return true
		}

		return OCQueryFilter(handler: itemFilterHandler)
	}()

	private lazy var leftEdgeSwipeGestureRecognizer: UIScreenEdgePanGestureRecognizer = {
		let gestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(edgeSwipeGesture))
		gestureRecognizer.edges = [UIRectEdge.left]
		return gestureRecognizer
	}()

	private lazy var rightEdgeSwipeGestureRecognizer: UIScreenEdgePanGestureRecognizer = {
		let gestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(edgeSwipeGesture(_:)))
		gestureRecognizer.edges = [UIRectEdge.right]
		return gestureRecognizer
	}()

	@objc func edgeSwipeGesture(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
		var add = 1

		if gestureRecognizer.edges == [.left] {
			add = -1
		}

		if let displayViewController = self.viewControllers?[0] as? DisplayViewController,
			let item = displayViewController.item,
			let index = items?.firstIndex(where: {$0.fileID == item.fileID}),
			let viewControllerToDisplay = viewControllerAtIndex(index: index + add) {

			self.setViewControllers([viewControllerToDisplay], direction: .forward, animated: true, completion: nil)
		}
	}

	@objc func leftSwipe() {
		if let displayViewController = self.viewControllers?[0] as? DisplayViewController,
			let item = displayViewController.item,
			let index = items?.firstIndex(where: {$0.fileID == item.fileID}),
			let viewControllerToDisplay = viewControllerAtIndex(index: index - 1) {

			self.setViewControllers([viewControllerToDisplay], direction: .forward, animated: true, completion: nil)
		}
	}

	// MARK: - Init & deinit
	init(core: OCCore, selectedItem: OCItem, query: OCQuery) {
		self.core = core
		self.selectedItem = selectedItem
		self.query = query

		super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)

		query.addObserver(self, forKeyPath: "hasChangesAvailable", options: [.initial, .new], context: nil)
		query.addFilter(itemsFilter, withIdentifier: "items-filter")

	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		query.removeObserver(self, forKeyPath: "hasChangesAvailable")
	}

	// MARK: - ViewController lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
		dataSource = self
		delegate = self

		view.addGestureRecognizer(leftEdgeSwipeGestureRecognizer)
		view.addGestureRecognizer(rightEdgeSwipeGestureRecognizer)

		query.requestChangeSet(withFlags: .onlyResults) { [weak self] ( _, changeSet) in
			guard let `self` = self else {
				return
			}

			self.items = changeSet?.queryResult

			if let items = self.items, let index = items.firstIndex(where: {$0.fileID == self.selectedItem.fileID}) {
				let itemToDisplay = items[index]

				guard let mimeType = itemToDisplay.mimeType else { return }
				OnMainThread {
					let viewController = self.selectDisplayViewControllerBasedOn(mimeType: mimeType)
					let shouldDownload = viewController is DisplayExtension ? true : false
					let configurationState: DisplayViewState = shouldDownload ? .hasNetworkConnection : .notSupportedMimeType
					let configuration = DisplayViewConfiguration(item: itemToDisplay, core: self.core, state: configurationState)

					self.addChild(viewController)
					viewController.didMove(toParent: self)

					viewController.configure(configuration)
					viewController.present(item: itemToDisplay)
					viewController.setupStatusBar()

					self.setViewControllers([viewController], direction: .forward, animated: false, completion: nil)
				}
			}
		}
    }

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		query.removeFilter(itemsFilter)
	}

	override var childForHomeIndicatorAutoHidden : UIViewController? {
		if let childViewController = self.children.first {
			return childViewController
		}
		return nil
	}

	// swiftlint:disable block_based_kvo
	// Would love to use the block-based KVO, but it doesn't seem to work when used on the .state property of the query :-(
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if (object as? OCQuery) === query {
			query.requestChangeSet(withFlags: .onlyResults) { ( _, changeSet) in
				guard changeSet != nil else { return }
				self.items = changeSet!.queryResult.filter({$0.mimeType != nil})
			}
		}
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

		let preferedExtension: OCExtension = matchedExtensions[0].extension

		let extensionObject = preferedExtension.provideObject(for: context)

		guard let controllerType = extensionObject as? (DisplayViewController & DisplayExtension) else {
			return DisplayViewController()
		}

		return controllerType
	}

	private func viewControllerAtIndex(index: Int) -> UIViewController? {
		guard let items = items else { return nil }

		guard index >= 0, index < items.count else { return nil }

		let item = items[index]

		let newViewController = selectDisplayViewControllerBasedOn(mimeType: item.mimeType!)
		let shouldDownload = newViewController is (DisplayViewController & DisplayExtension) ? true : false
		var configuration: DisplayViewConfiguration
		if !shouldDownload {
			configuration = DisplayViewConfiguration(item: item, core: core, state: .notSupportedMimeType)
		} else {
			configuration = DisplayViewConfiguration(item: item, core: core, state: .hasNetworkConnection)
		}

		newViewController.configure(configuration)
		newViewController.present(item: item)
		return newViewController
	}
}

extension GalleryHostViewController: UIPageViewControllerDataSource {
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		if let displayViewController = viewController as? DisplayViewController,
			let item = displayViewController.item,
			let index = items?.firstIndex(where: {$0.fileID == item.fileID}) {
			return viewControllerAtIndex(index: index + 1)
		}

		return nil

	}

	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
		if let displayViewController = viewController as? DisplayViewController,
			let item = displayViewController.item,
			let index = items?.firstIndex(where: {$0.fileID == item.fileID}) {
			return viewControllerAtIndex(index: index - 1)
		}

		return nil
	}
}

extension GalleryHostViewController: UIPageViewControllerDelegate {
	func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {

		let previousViewController = previousViewControllers[0]
		previousViewController.didMove(toParent: nil)

		if completed, let viewControllerToTransition = self.viewControllerToTansition {
			if self.children.contains(viewControllerToTransition) == false {
				self.addChild(viewControllerToTransition)
			}
			viewControllerToTransition.didMove(toParent: self)
			viewControllerToTransition.setupStatusBar()
		}
	}

	func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
		if let viewControllerToTransition = pendingViewControllers[0] as? DisplayViewController {
			self.viewControllerToTansition = viewControllerToTransition
		}
	}
}
