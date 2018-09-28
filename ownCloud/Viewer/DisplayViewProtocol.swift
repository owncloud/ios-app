//
//  DisplayViewProtocol.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 29/08/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

protocol DisplayViewProtocol where Self: DisplayViewController {

	static var features: [String : Any]? {get}
	static var supportedMimeTypes: [String] {get}
}

struct FeatureKeys {
	static let canEdit: String = "featureKeyCanEdit"
	static let canSave: String = "featureKeyCanSave"
}
