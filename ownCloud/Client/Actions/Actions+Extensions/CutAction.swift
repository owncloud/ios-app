//
//  CutAction.swift
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

class CutAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.cutpasteboard") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Cut".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreFolder, .keyboardShortcut] }
	override class var keyCommand : String? { return "X" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.items.filter({return $0.isRoot}).count == 0 {
			return .afterMiddle

		}

		return .none
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0, let item = context.items.first, let viewController = context.viewController, let tabBarController = viewController.tabBarController as? ClientRootViewController else {
			completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		if let fileData = item.serializedData() {
			let pasteboard = UIPasteboard(name: UIPasteboard.Name(rawValue: "com.owncloud.pasteboard"), create: true)
			pasteboard?.setData(fileData as Data, forPasteboardType: "com.owncloud.uti.OCItem.cut")
			tabBarController.pasteboardChangedCounter = UIPasteboard.general.changeCount
		}
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem || location == .moreFolder {
			return UIImage(named: "copy-file")
		}

		return nil
	}
}
