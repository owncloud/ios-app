//
//  DisplayViewProtocol.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 29/08/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

protocol DisplayViewEditingDelegate: class {
	func save(item: OCItem, fileURL newVersion: URL)
}

protocol DisplayViewProtocol where Self: UIViewController {

	static var features: [String : Any]? {get}
	static var supportedMimeTypes: [String] {get}

	var extensionIdentifier: String! {get set} //?
	var source: URL! {get set}
	var editingDelegate: DisplayViewEditingDelegate? {get set}
}

struct FeatureKeys {
	static let canEdit: String = "featureKeyCanEdit"
	static let canSave: String = "featureKeyCanSave"
	static let showPDF: String = "featureKeyShowPDF"
	static let showImages: String = "featureKeyShowImages"
}
