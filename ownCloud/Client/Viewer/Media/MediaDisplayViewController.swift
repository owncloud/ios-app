//
//  MediaDisplayViewController.swift
//  ownCloud
//
//  Created by Michael Neuwert on 30.06.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
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
import AVKit
import ownCloudSDK

class MediaDisplayViewController : DisplayViewController {

	override func renderSpecificView() {
		if source != nil {
			let player = AVPlayer(url: source!)
			let playerViewController = AVPlayerViewController()
			playerViewController.player = player

			addChild(playerViewController)
			self.view.addSubview(playerViewController.view)
			playerViewController.didMove(toParent: self)
			playerViewController.player?.play()
		}
	}
}

// MARK: - Display Extension.
extension MediaDisplayViewController: DisplayExtension {
	static var customMatcher: OCExtensionCustomContextMatcher? = { (context, defaultPriority) in
		do {
			if let mimeType = context.location?.identifier?.rawValue {
				let supportedFormatsRegex = try NSRegularExpression(pattern: "\\A((video/)|(audio/))",
																	options: .caseInsensitive)
				let matches = supportedFormatsRegex.numberOfMatches(in: mimeType, options: .reportCompletion, range: NSRange(location: 0, length: mimeType.count))

				if matches > 0 {
					return OCExtensionPriority.locationMatch
				}
			}

			return OCExtensionPriority.noMatch
		} catch {
			return OCExtensionPriority.noMatch
		}
	}
	static var displayExtensionIdentifier: String = "org.owncloud.image"
	static var supportedMimeTypes: [String]?
	static var features: [String : Any]? = [FeatureKeys.canEdit : false]
}
