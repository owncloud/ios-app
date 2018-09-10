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
	}

	init(for items: [OCItem], with core: OCCore) {
		itemsToDisplay = items
		self.core = core

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

    override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .green

		let item = itemsToDisplay[0]
		guard var viewController = self.selectDisplayViewControllerBasedOn(mimeType: item.mimeType) as? (UIViewController & DisplayViewProtocol) else {
			print("LOG ---> error no controller for this mime type: \(item.mimeType)")
			OnMainThread {
				self.view.backgroundColor = .yellow
			}
			return
		}


		_ = self.core.downloadItem(item, options: nil, resultHandler: { (error, _, _, file) in

			guard error == nil else {
				print("LOG ---> error downloading")
				OnMainThread {
					self.view.backgroundColor = .purple
				}
				return
			}

			viewController.source = file!.url

			OnMainThread {
				self.view.addSubview(viewController.view)
				self.addChildViewController(viewController)
			}
		})
	}

	private func selectDisplayViewControllerBasedOn(mimeType: String) -> DisplayViewProtocol? {

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

		guard var controllerType = extensionObject as? (UIViewController & DisplayViewProtocol) else {
			return nil
		}

		let item = itemsToDisplay[0]
		let type = item.mimeType

		controllerType.extensionIdentifier = type!

		return controllerType
	}
}
