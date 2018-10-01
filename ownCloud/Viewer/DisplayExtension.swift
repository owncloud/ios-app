//
//  DisplayViewProtocol.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 29/08/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

protocol DisplayExtension where Self: DisplayViewController {

	static var features: [String : Any]? {get}
	static var supportedMimeTypes: [String] {get}
	static var displayExtensionIdentifier: String {get}

	static var displayExtension: OCExtension {get}

	static var customMatcher: OCExtensionCustomContextMatcher? {get}
}

extension DisplayExtension where Self: DisplayViewController {
	static var displayExtension: OCExtension {
		let rawIdentifier: OCExtensionIdentifier =  OCExtensionIdentifier(rawValue: displayExtensionIdentifier)
		var locationIdentifiers: [OCExtensionLocationIdentifier] = []
		for mimeType in supportedMimeTypes {
			let locationIdentifier: OCExtensionLocationIdentifier = OCExtensionLocationIdentifier(rawValue: mimeType)
			locationIdentifiers.append(locationIdentifier)
		}

		let displayExtension = OCExtension(identifier: rawIdentifier, type: .viewer, locations: locationIdentifiers, features: features, objectProvider: { (_ rawExtension, _ context, _ error) -> Any? in
			return Self()
		}, customMatcher:customMatcher)

		return displayExtension!
	}
}

struct FeatureKeys {
	static let canEdit: String = "featureKeyCanEdit"
}
