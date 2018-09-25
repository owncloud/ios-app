//
//  DisplayHostViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 29/08/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK
import QuickLook

class DisplayHostViewController: UIViewController {

	var itemsToDisplay: [OCItem]
	var core: OCCore

	init(for item: OCItem, with core: OCCore) {
		itemsToDisplay = []
		itemsToDisplay.append(item)
		self.core = core

		super.init(nibName: nil, bundle: nil)

		Theme.shared.register(client: self)
	}

	init(for items: [OCItem], with core: OCCore) {
		itemsToDisplay = items
		self.core = core

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

    override func viewDidLoad() {
		super.viewDidLoad()

		let item = itemsToDisplay[0]

        func setupChild(viewController:UIViewController) {
            OnMainThread {
                self.addChildViewController(viewController)
                viewController.view.frame = self.view.frame
                self.view.addSubview(viewController.view)
                viewController.didMove(toParentViewController: self)
            }
        }

		guard let viewController = self.selectDisplayViewControllerBasedOn(mimeType: item.mimeType) else {
			print("LOG ---> error no controller for this mime type: \(item.mimeType!)")
            let controller = DisplayViewController()
            controller.item = item
            controller.core = self.core
            setupChild(viewController: controller)
			return
		}

		viewController.item = item
		viewController.core = core
        setupChild(viewController: viewController)

		_ = self.core.downloadItem(item, options: nil, resultHandler: { (error, _, _, file) in

			guard error == nil else {
				print("LOG ---> error downloading")
				OnMainThread {
					self.view.backgroundColor = .purple
				}
				return
			}

            OnMainThread {
                viewController.source = file!.url
            }

		})
	}

	private func selectDisplayViewControllerBasedOn(mimeType: String) -> (DisplayViewController & DisplayViewProtocol)? {

		let locationIdentifier = OCExtensionLocationIdentifier(rawValue: "viewer")
		let location: OCDisplayExtensionLocation = OCDisplayExtensionLocation(type: .viewer, identifier: locationIdentifier, supportedMimeTypes: [mimeType])
		let context = OCExtensionContext(location: location, requirements: nil, preferences: nil)

		var extensions: [OCExtensionMatch]?

		do {
			try extensions = OCExtensionManager.shared.provideExtensions(for: context)
		} catch {
			return nil
		}

		guard let matchedExtensions = extensions else {
			return nil
		}

		let preferedExtension: OCExtension = matchedExtensions[0].extension

		let extensionObject = preferedExtension.provideObject(for: context!)

		guard let controllerType = extensionObject as? (DisplayViewController & DisplayViewProtocol) else {
			return nil
		}

		return controllerType
	}
}

extension DisplayHostViewController: Themeable {

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.view.backgroundColor = collection.tableBackgroundColor
	}
}
