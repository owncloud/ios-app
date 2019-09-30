//
//  DiscardSceneAction.swift
//  ownCloud
//
//  Created by Matthias Hühne on 06.09.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
*/

import UIKit
import ownCloudSDK
import MobileCoreServices

@available(iOS 13.0, *)
class DiscardSceneAction: Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.discardscene") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String { return "Close Window".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreFolder] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {

		if UIDevice.current.isIpad() {
			if let viewController = forContext.viewController, viewController.view.window?.windowScene?.userActivity != nil {
				return .first
			}
		}

		return .none
	}

	// MARK: - Action implementation
	override func run() {
		guard let viewController = context.viewController else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		if UIDevice.current.isIpad() {
			if let scene = viewController.view.window?.windowScene {
				UIApplication.shared.requestSceneSessionDestruction(scene.session, options: nil) { (_) in
				}
			}
		}
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return UIImage(systemName: "xmark.square")?.tinted(with: Theme.shared.activeCollection.tintColor)
	}
}
