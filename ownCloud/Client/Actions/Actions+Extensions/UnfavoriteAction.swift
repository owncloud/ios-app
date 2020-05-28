//
//  UnfavoriteAction.swift
//  ownCloud
//
//  Created by Matthias Hühne on 27/09/2019.
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

import Foundation
import ownCloudSDK
import MobileCoreServices

class UnfavoriteAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.unfavorite") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Favorited".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.keyboardShortcut, .contextMenuItem] }
	override class var keyCommand : String? { return "F" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command, .shift] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.items.filter({return $0.isRoot}).count > 0 {
			return .none
		} else if forContext.items.count > 0, let item = forContext.items.first, item.isFavorite == false {
			return .none
		}

		return .middle
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0, let item = context.items.first, let core = core else {
			completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		item.isFavorite = false

		core.update(item, properties: [OCItemPropertyName.isFavorite], options: nil, resultHandler: { (error, _, _, _) in
			if error == nil {
			}
		})
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem || location == .contextMenuItem {
			return UIImage(named: "star")
		}

		return nil
	}
}
