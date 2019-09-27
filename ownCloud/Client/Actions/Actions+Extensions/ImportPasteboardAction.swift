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

class ImportPasteboardAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.importpasteboard") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Import from Pasteboard".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreFolder, .keyboardShortcut] }
	override class var keyCommand : String? { return "V" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command, .shift] }

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

		let pasteboard = UIPasteboard.general

		// Determine, if the internal pasteboard is the current item and use it
		if pasteboard.changeCount == tabBarController.pasteboardChangedCounter {
			// Internal Pasteboard
			if let pasteboard = UIPasteboard(name: UIPasteboard.Name(rawValue: "com.owncloud.pasteboard"), create: false) {
				if let data = pasteboard.data(forPasteboardType: "com.owncloud.uti.OCItem.copy"), let object = NSKeyedUnarchiver.unarchiveObject(with: data) {
					if let item = object as? OCItem, let name = item.name {
						core.copy(item, to: rootItem, withName: name, options: nil, resultHandler: { (error, _, _, _) in
							if error != nil {
							} else {
							}
						})
					}
				} else if let data = pasteboard.data(forPasteboardType: "com.owncloud.uti.OCItem.cut"), let object = NSKeyedUnarchiver.unarchiveObject(with: data) {
					if let item = object as? OCItem, let name = item.name {
						core.copy(item, to: rootItem, withName: name, options: nil, resultHandler: { (error, _, _, _) in
							if error != nil {
							} else {
								core.delete(item, requireMatch: true) { (_, _, _, _) in
								}
							}
						})
					}
				}
			}
		} else {
			// System-wide Pasteboard
			for type in pasteboard.types {
				guard let data = pasteboard.data(forPasteboardType: type) else { return }
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
													Log.debug("Error uploading \(Log.mask(fileName)) to \(Log.mask(rootItem.path)), error: \(error?.localizedDescription ?? "" )")
												}
						},
											 resultHandler: { (error, _ core, _ item, _) in
												if error != nil {
													Log.debug("Error uploading \(Log.mask(fileName)) to \(Log.mask(rootItem.path)), error: \(error?.localizedDescription ?? "" )")
												} else {
													Log.debug("Success uploading \(Log.mask(fileName)) to \(Log.mask(rootItem.path))")
												}
						}
						)
					} catch let error as NSError {
						print(error)
					}
				}
			}
		}
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem || location == .moreFolder {
			return UIImage(named: "copy-file")
		}

		return nil
	}
}
