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
	override class var name : String? { return OCLocalizedString("Cut", nil) }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreDetailItem, .moreFolder, .multiSelection, .dropAction, .keyboardShortcut, .contextMenuItem, .accessibilityCustomAction] }
	override class var keyCommand : String? { return "X" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.containsRoot || !forContext.allItemsMoveable {
			return .none
		}

		return .middle
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0, let viewController = context.viewController, let core = context.core else {
			completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let items = context.items
		let uuid = core.bookmark.uuid.uuidString
		var itemProviderItems: [NSItemProvider] = []
		let globalPasteboard = UIPasteboard.general
		globalPasteboard.items = []
		var containsFolders = false

		items.forEach({ (item) in

			let itemProvider = NSItemProvider()

			itemProvider.suggestedName = item.name
			if item.type == .collection {
				containsFolders = true
			}

			itemProvider.registerDataRepresentation(forTypeIdentifier: ImportPasteboardAction.InternalPasteboardCutKey, visibility: .ownProcess) { (completionBlock) -> Progress? in
				let data = OCItemPasteboardValue(item: item, bookmarkUUID: uuid).encodedData
				completionBlock(data, nil)
				return nil
			}
			itemProviderItems.append(itemProvider)

		})
		globalPasteboard.itemProviders = itemProviderItems

		var subtitle = OCLocalizedString("%ld Item was copied to the clipboard", nil)
		if itemProviderItems.count > 1 {
			subtitle = OCLocalizedString("%ld Items were copied to the clipboard", nil)
		}

		if containsFolders {
			let subtitleFolder = String(format:OCLocalizedString("Please note: Folders can only be pasted into the %@ app and the same account.", nil), VendorServices.shared.appName)
			subtitle = String(format: "%@\n\n%@", subtitle, subtitleFolder)
		}

		OnMainThread {
			if let navigationController = viewController.navigationController {
				_ = NotificationHUDViewController(on: navigationController, title: OCLocalizedString("Cut", nil), subtitle: String(format: subtitle, itemProviderItems.count))
			}
		}

		completed()
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return UIImage(systemName: "scissors")?.withRenderingMode(.alwaysTemplate)
	}
}
