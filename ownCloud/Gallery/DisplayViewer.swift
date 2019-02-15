//
//  DisplayViewer.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 14/02/2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import Foundation
import ownCloudSDK

protocol DisplayViewerDataSource: class {
	func numberOfItems() -> Int
	func itemFor(viewController: UIViewController) -> OCItem?
	func nonSupportedItemView() -> UIView?
}

protocol DisplayViewerDelegate: class {

	func setNavigationBarItemsFor(viewController: UIViewController)

}

protocol DisplayViewer where Self: UIViewController {
	static var features: [String : Any]? {get}
	static var supportedMimeTypes: [String]? {get}
	static var displayExtensionIdentifier: String {get}

	static var displayExtension: OCExtension {get}

	static var customMatcher: OCExtensionCustomContextMatcher? {get}

	var delegate: DisplayViewerDelegate? {get set}
	var dataSource: DisplayViewerDataSource? {get set}

	var core: OCCore {get set}
	var items: [OCItem] {get set}

	init(core: OCCore, items: [OCItem])
}

extension DisplayViewer where Self: UIViewController {
	static var displayExtension: OCExtension {
		let rawIdentifier: OCExtensionIdentifier =  OCExtensionIdentifier(rawValue: displayExtensionIdentifier)
		var locationIdentifiers: [OCExtensionLocationIdentifier] = []

		if let supportedMimeTypes = supportedMimeTypes {
			for mimeType in supportedMimeTypes {
				let locationIdentifier: OCExtensionLocationIdentifier = OCExtensionLocationIdentifier(rawValue: mimeType)
				locationIdentifiers.append(locationIdentifier)
			}
		}

		let displayExtension = OCExtension(identifier: rawIdentifier, type: .viewer, locations: locationIdentifiers, features: features, objectProvider: { (_ rawExtension, _ context, _ error) -> Any? in
			return Self.self
		}, customMatcher:customMatcher)

		return displayExtension
	}
}
