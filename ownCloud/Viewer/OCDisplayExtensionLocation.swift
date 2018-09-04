//
//  OCDisplayExtensionLocation.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 04/09/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import ownCloudSDK

class OCDisplayExtensionLocation: OCExtensionLocation {

	var supportedMimeTypes: [String]!

	init(type: OCExtensionType, identifier: OCExtensionLocationIdentifier, supportedMimeTypes: [String]) {

		self.supportedMimeTypes = supportedMimeTypes

		super.init()
		self.type = type
		self.identifier = identifier
	}
}
