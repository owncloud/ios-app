//
//  URLDisplayViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.04.24.
//  Copyright © 2024 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2024, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK
import ownCloudAppShared

class URLDisplayViewController: DisplayViewController {
	override func viewDidLoad() {
		super.viewDidLoad()
	}

	override func renderItem(completion: @escaping (Bool) -> Void) {
		if let itemDirectURL {
			if let data = try? Data(contentsOf: itemDirectURL) {
				if let url = INIFile(with: data).url {
					NSLog("\(url)")
				}
			}
		}
	}
}

extension URLDisplayViewController: DisplayExtension {
	static var customMatcher: OCExtensionCustomContextMatcher?
	static var displayExtensionIdentifier: String = "org.owncloud.url-shortcut"
	static var supportedMimeTypes: [String]? = ["text/uri-list"]
	static var features: [String : Any]? = [FeatureKeys.canEdit : false]
}
