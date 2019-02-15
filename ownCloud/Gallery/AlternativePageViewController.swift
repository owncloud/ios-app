//
//  AlternativePageViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 14/02/2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

class AlternativePageViewController: UIPageViewController {

	weak private var core: OCCore?
	private var items: [OCItem]
	private var initialIndex: Int
	private var query: OCQuery
	private var viewControllerToTansition: DisplayViewController? {
		didSet {
			print("LOG ---> viewControllerToTansition = \(viewControllerToTansition?.item?.name)")
		}
	}

	init(core: OCCore, items: [OCItem], index: Int = 0, query: OCQuery) {
		self.core = core
		self.items = items
		self.initialIndex = index
		self.query = query

		super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)

		query.addObserver(self, forKeyPath: "hasChangesAvailable", options: [.initial, .new], context: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		query.removeObserver(self, forKeyPath: "hasChangesAvailable")
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		dataSource = self
		delegate = self
		let itemToDisplay = items[initialIndex]
		let mimeType = itemToDisplay.mimeType!
		let viewController = self.selectDisplayViewControllerBasedOn(mimeType: mimeType)
		let shouldDownload = viewController is (DisplayViewController & DisplayExtension) ? true : false
		var configuration: DisplayViewConfiguration
		if !shouldDownload {
			configuration = DisplayViewConfiguration(item: itemToDisplay, core: core, state: .notSupportedMimeType)
		} else {
			configuration = DisplayViewConfiguration(item: itemToDisplay, core: core, state: .hasNetworkConnection)
		}

		viewController.configure(configuration)
		viewController.present(item: itemToDisplay)

		self.setViewControllers([viewController], direction: .forward, animated: false, completion: nil)
    }

	// swiftlint:disable block_based_kvo
	// Would love to use the block-based KVO, but it doesn't seem to work when used on the .state property of the query :-(
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if (object as? OCQuery) === query {
			query.requestChangeSet(withFlags: .onlyResults) { ( _, changeSet) in
				guard changeSet != nil else { return }
				self.items = changeSet!.queryResult
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
		guard index >= 0, index < items.count else {
			return nil
		}

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

extension AlternativePageViewController: UIPageViewControllerDataSource {
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {

		if let displayViewController = viewController as? DisplayViewController, let item = displayViewController.item, let index =
			items.firstIndex(where: {$0.fileID == item.fileID}) {
			return viewControllerAtIndex(index: index + 1)
		}

		return nil

	}

	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {

		if let displayViewController = viewController as? DisplayViewController, let item = displayViewController.item, let index =
			items.firstIndex(where: {$0.fileID == item.fileID}) {
			return viewControllerAtIndex(index: index - 1)
		}

		return nil
	}
}

extension AlternativePageViewController: UIPageViewControllerDelegate {
	func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {

		let previousViewController = previousViewControllers[0]
		previousViewController.didMove(toParent: nil)

		if completed, let vc = self.viewControllerToTansition {
//			if self.children.contains(vc) {
//			} else {
//				self.addChild(vc)
//			}
//			vc.didMove(toParent: self)
		}
	}

	func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
		if let vc = pendingViewControllers[0] as? DisplayViewController {
			self.viewControllerToTansition = vc
		}
	}
}
