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
import ownCloudAppShared

class CutAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.cutpasteboard") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Cut".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreDetailItem, .moreFolder, .toolbar, .keyboardShortcut, .contextMenuItem] }
	override class var keyCommand : String? { return "X" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.containsRoot {
			return .none
		}

		return .middle
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0, let viewController = context.viewController, let tabBarController = viewController.tabBarController as? ClientRootViewController else {
			completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let items = context.items
		let vault : OCVault = OCVault(bookmark: tabBarController.bookmark)
		UIPasteboard.remove(withName: UIPasteboard.Name(rawValue: ImportPasteboardAction.InternalPasteboardKey))
		guard let internalPasteboard = UIPasteboard(name: UIPasteboard.Name(rawValue: ImportPasteboardAction.InternalPasteboardKey), create: true) else {
			return
		}
		let internalItems = items.map { item in
			return [ImportPasteboardAction.InternalPasteboardCutKey : item.serializedData()]
		}
		internalPasteboard.addItems(internalItems)

		vault.keyValueStore?.storeObject(UIPasteboard.general.changeCount as NSNumber, forKey: ImportPasteboardAction.InternalPasteboardChangedCounterKey)
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem || location == .moreDetailItem || location == .moreFolder || location == .contextMenuItem {
			if #available(iOS 13.0, *) {
				return UIImage(systemName: "scissors")
			} else {
				return UIImage(named: "clipboard")
			}
		}

		return nil
	}
}
