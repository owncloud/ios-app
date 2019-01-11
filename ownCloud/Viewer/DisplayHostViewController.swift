//
//  DisplayHostViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 29/08/2018.
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
import QuickLook

class DisplayHostViewController: UIViewController {

	// MARK: - Instance Properties
	private var itemsToDisplay: [OCItem] = []
	private weak var core: OCCore?
	private var rootItem: OCItem

	// MARK: - Init & deinit
	init(for item: OCItem, with core: OCCore, root: OCItem) {
		itemsToDisplay.append(item)
		self.core = core
		self.rootItem = root

		super.init(nibName: nil, bundle: nil)
		Theme.shared.register(client: self)
	}

	init(for items: [OCItem], with core: OCCore, root: OCItem) {
		itemsToDisplay = items
		self.core = core
		self.rootItem = root

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	// MARK: - Controller lifcycle
	override func viewDidLoad() {
		super.viewDidLoad()

		let itemToDisplay = itemsToDisplay[0]

		let viewController = self.selectDisplayViewControllerBasedOn(mimeType: itemToDisplay.mimeType!)
		let shouldDownload = viewController is (DisplayViewController & DisplayExtension) ? true : false

		var configuration: DisplayViewConfiguration
		if !shouldDownload {
			configuration = DisplayViewConfiguration(item: itemToDisplay, core: core, state: .notSupportedMimeType)
		} else {
			configuration = DisplayViewConfiguration(item: itemToDisplay, core: core, state: .hasNetworkConnection)
		}

		viewController.configure(configuration)

		self.addChild(viewController)
		self.view.addSubview(viewController.view)
		viewController.didMove(toParent: self)

		if shouldDownload {
			viewController.downloadItem(sender: nil)
		} else {
			viewController.downloadProgress = nil
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		navigationController?.tabBarController?.tabBar.isHidden = true
	}

	override func viewWillDisappear(_ animated: Bool) {
		navigationController?.tabBarController?.tabBar.isHidden = false
	}

	override var childForHomeIndicatorAutoHidden : UIViewController? {
		if let childViewController = self.children.first {
			return childViewController
		}
		return nil
	}

	// MARK: - Host Actions
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
}

// MARK: - Themeable support
extension DisplayHostViewController: Themeable {
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.view.backgroundColor = collection.tableBackgroundColor
	}
}
