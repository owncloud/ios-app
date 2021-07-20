//
//  CopyAction.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 14/01/2019.
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

import Foundation
import MobileCoreServices
import ownCloudSDK
import ownCloudAppShared

class CopyAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.copy") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Copy".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreDetailItem, .moreFolder, .toolbar, .keyboardShortcut, .contextMenuItem] }
	override class var keyCommand : String? { return "C" }
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
		guard context.items.count > 0, let viewController = context.viewController else {
			completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		var presentationStyle: UIAlertController.Style = .actionSheet
		if UIDevice.current.isIpad {
			presentationStyle = .alert
		}

		let alertController = ThemedAlertController(title: "Copy".localized,
													message: nil,
													preferredStyle: presentationStyle)

		alertController.addAction(UIAlertAction(title: "Choose destination directory…".localized, style: .default) { (_) in
			self.showDirectoryPicker()
		})
		alertController.addAction(UIAlertAction(title: "Copy to Clipboard".localized, style: .default) { (_) in
			self.copyToPasteboard()
		})
		alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))

		viewController.present(alertController, animated: true, completion: nil)
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem || location == .moreDetailItem || location == .moreFolder || location == .contextMenuItem {
			return UIImage(named: "copy-file")
		}

		return nil
	}

	func showDirectoryPicker() {
		guard context.items.count > 0, let viewController = context.viewController, let core = self.core else {
			completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let items = context.items

		let directoryPickerViewController = ClientDirectoryPickerViewController(core: core, path: "/", selectButtonTitle: "Copy here".localized, avoidConflictsWith: items, choiceHandler: { (selectedDirectory, _) in
			if let targetDirectory = selectedDirectory {
				items.forEach({ (item) in

					if let progress = self.core?.copy(item, to: targetDirectory, withName: item.name!, options: nil, resultHandler: { (error, _, _, _) in
						if error != nil {
							self.completed(with: error)
						} else {
							self.completed()
						}

					}) {
						self.publish(progress: progress)
					}
				})
			}

		})

		let pickerNavigationController = ThemeNavigationController(rootViewController: directoryPickerViewController)
		viewController.present(pickerNavigationController, animated: true)
	}

	func copyToPasteboard() {
		guard context.items.count > 0, let viewController = context.viewController, let core = self.core, let tabBarController = viewController.tabBarController as? ClientRootViewController else {
			completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let items = context.items

		// Internal Pasteboard
		let vault : OCVault = OCVault(bookmark: tabBarController.bookmark)
		UIPasteboard.remove(withName: UIPasteboard.Name(rawValue: ImportPasteboardAction.InternalPasteboardKey))
		guard let internalPasteboard = UIPasteboard(name: UIPasteboard.Name(rawValue: ImportPasteboardAction.InternalPasteboardKey), create: true) else {
			return
		}
		let internalItems = items.map { item in
			return [ImportPasteboardAction.InternalPasteboardCopyKey : item.serializedData()]
		}
		internalPasteboard.addItems(internalItems)

		// General system-wide Pasteboard
		let globalPasteboard = UIPasteboard.general
		globalPasteboard.items = []
		var itemProviderItems: [NSItemProvider] = []

		items.forEach({ (item) in
			if item.type == .file { // only files can be added to the globale pasteboard
				guard let itemMimeType = item.mimeType else { return }

				let mimeTypeCF = itemMimeType as CFString
				guard let rawUti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeTypeCF, nil)?.takeRetainedValue() as String? else { return }

				let itemProvider = NSItemProvider()

				itemProvider.suggestedName = item.name

				itemProvider.registerFileRepresentation(forTypeIdentifier: rawUti, fileOptions: [], visibility: .all, loadHandler: { [weak core] (completionHandler) -> Progress? in
					var progress : Progress?

					guard let core = core else {
						completionHandler(nil, false, NSError(domain: OCErrorDomain, code: Int(OCError.internal.rawValue), userInfo: nil))
						return nil
					}

					if let localFileURL = core.localCopy(of: item) {
						// Provide local copies directly
						completionHandler(localFileURL, true, nil)
					} else {
						// Otherwise download the file and provide it when done
						progress = core.downloadItem(item, options: [
							.returnImmediatelyIfOfflineOrUnavailable : true,
							.addTemporaryClaimForPurpose : OCCoreClaimPurpose.view.rawValue
						], resultHandler: { [weak self] (error, core, item, file) in
							guard error == nil, let fileURL = file?.url else {
								completionHandler(nil, false, error)
								return
							}

							completionHandler(fileURL, true, nil)

							if let claim = file?.claim, let item = item, let self = self {
								self.core?.remove(claim, on: item, afterDeallocationOf: [fileURL])
							}
						})
					}

					return progress
				})
				itemProviderItems.append(itemProvider)
			}
		})

		globalPasteboard.itemProviders = itemProviderItems
		vault.keyValueStore?.storeObject(UIPasteboard.general.changeCount as NSNumber, forKey: ImportPasteboardAction.InternalPasteboardChangedCounterKey)

		var subtitle = "%ld Item was copied to the clipboard".localized
		if internalItems.count > 1 {
			subtitle = "%ld Items was copied to the clipboard".localized
		}

		OnMainThread {
			if let navigationController = viewController.navigationController {
				_ = NotificationHUDViewController(on: navigationController, title: "Copy".localized, subtitle: String(format: subtitle, internalItems.count))
			}
		}
	}
}
