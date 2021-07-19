//
//  ImportPasteboardAction.swift
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

class ImportPasteboardAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.importpasteboard") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Paste".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreFolder, .keyboardShortcut] }
	override class var keyCommand : String? { return "V" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command] }

	static let InternalPasteboardKey = "com.owncloud.pasteboard"
	static let InternalPasteboardCopyKey = "com.owncloud.uti.ocitem.copy"
	static let InternalPasteboardCutKey = "com.owncloud.uti.ocitem.cut"
	static let InternalPasteboardChangedCounterKey = OCKeyValueStoreKey(rawValue: "com.owncloud.internal-pasteboard-changed-counter")

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		let pasteboard = UIPasteboard.general
		if pasteboard.numberOfItems > 0 {
			return .afterMiddle
		}

		return .none
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0, let viewController = context.viewController, let core = self.core, let rootItem = context.query?.rootItem, let tabBarController = viewController.tabBarController as? ClientRootViewController else {
			completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let vault : OCVault = OCVault(bookmark: tabBarController.bookmark)
		let generalPasteboard = UIPasteboard.general

		// Determine, if the internal pasteboard has items available
		if let pasteboard = UIPasteboard(name: UIPasteboard.Name(rawValue: ImportPasteboardAction.InternalPasteboardKey), create: false), let pasteboardChangedCounter = vault.keyValueStore?.readObject(forKey: ImportPasteboardAction.InternalPasteboardChangedCounterKey) as? Int, generalPasteboard.changeCount == pasteboardChangedCounter {
			for item in pasteboard.items {
				if let data = item[ImportPasteboardAction.InternalPasteboardCopyKey] as? Data, let object = NSKeyedUnarchiver.unarchiveObject(with: data) {
					guard let item = object as? OCItem, let name = item.name else { return }

					core.copy(item, to: rootItem, withName: name, options: nil, resultHandler: { (error, _, _, _) in
						if error != nil {
							self.completed(with: error)
						}
					})
				} else if let data = item[ImportPasteboardAction.InternalPasteboardCutKey] as? Data, let object = NSKeyedUnarchiver.unarchiveObject(with: data) {
					guard let item = object as? OCItem, let name = item.name else { return }

					core.move(item, to: rootItem, withName: name, options: nil) { (error, _, _, _) in
						if error != nil {
							self.completed(with: error)
						}
					}
				}

			}
		} else {
			// System-wide Pasteboard
			for type in generalPasteboard.types {
				guard let dataArray = generalPasteboard.data(forPasteboardType: type, inItemSet: nil) else { return }
				for data in dataArray {

					if let extUTI = UTTypeCopyPreferredTagWithClass(type as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue() {
						let fileName = type
						let localURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName).appendingPathExtension(extUTI as String)
						do {
							try data.write(to: localURL)

							core.importItemNamed(localURL.lastPathComponent,
												 at: rootItem,
												 from: localURL,
												 isSecurityScoped: false,
												 options: [
													OCCoreOption.importByCopying : false,
													OCCoreOption.automaticConflictResolutionNameStyle : OCCoreDuplicateNameStyle.bracketed.rawValue
								],
												 placeholderCompletionHandler: { (error, item) in
													if error != nil {
														self.completed(with: error)
														Log.debug("Error uploading \(Log.mask(fileName)) to \(Log.mask(rootItem.path)), error: \(error?.localizedDescription ?? "" )")
													}
							},
												 resultHandler: { (error, _ core, _ item, _) in
													if error != nil {
														self.completed(with: error)
														Log.debug("Error uploading \(Log.mask(fileName)) to \(Log.mask(rootItem.path)), error: \(error?.localizedDescription ?? "" )")
													} else {
														Log.debug("Success uploading \(Log.mask(fileName)) to \(Log.mask(rootItem.path))")
													}
							}
							)
						} catch let error as NSError {
							self.completed(with: error)
						}
					}
				}
			}
		}
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem || location == .moreFolder {
			if #available(iOS 13.0, *) {
				return UIImage(systemName: "doc.on.clipboard")
			} else {
				return UIImage(named: "clipboard")
			}
		}

		return nil
	}
}
