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



struct OCItemPasteboardValue {
	var item : OCItem
	var bookmarkUUID : String
}

extension OCItemPasteboardValue {
	func encode() -> Data {
		let data = NSMutableData()
		let archiver = NSKeyedArchiver(forWritingWith: data)
		archiver.encode(item, forKey: "item")
		archiver.encode(bookmarkUUID, forKey: "bookmarkUUID")
		archiver.finishEncoding()
		return data as Data
	}

	init?(data: Data) {
		let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
		defer {
			unarchiver.finishDecoding()
		}
		guard let item = unarchiver.decodeObject(forKey: "item") as? OCItem else { return nil }
		guard let bookmarkUUID = unarchiver.decodeObject(forKey: "bookmarkUUID") as? String else { return nil }
		self.item = item
		self.bookmarkUUID = bookmarkUUID
	}
}

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
		guard context.items.count > 0, let viewController = context.viewController, let core = self.core else {
			completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let items = context.items
		let uuid = core.bookmark.uuid.uuidString
		let globalPasteboard = UIPasteboard.general
		globalPasteboard.items = []
		var itemProviderItems: [NSItemProvider] = []
		var containsFolders = false

		let fileItems = context.items.filter { item in
			if item.type == .file {
				return true
			}

			return false
		}

		let hudViewController = DownloadItemsHUDViewController(core: core, downloadItems: fileItems) { [weak viewController] (error, _) in
			if let error = error {
				if (error as NSError).isOCError(withCode: .cancelled) {
					return
				}

				let appName = VendorServices.shared.appName
				let alertController = ThemedAlertController(with: "Cannot connect to ".localized + appName, message: appName + " couldn't download file(s)".localized, okLabel: "OK".localized, action: nil)

				viewController?.present(alertController, animated: true)
			} else {
				guard let viewController = viewController else { return }

				items.forEach({ (item) in
					let itemProvider = NSItemProvider()
					itemProvider.suggestedName = item.name
					if item.type == .collection {
						containsFolders = true
					}

					// Prepare Items for internal use
					itemProvider.registerDataRepresentation(forTypeIdentifier: ImportPasteboardAction.InternalPasteboardCopyKey, visibility: .ownProcess) { (completionBlock) -> Progress? in
						let data = OCItemPasteboardValue(item: item, bookmarkUUID: uuid).encode()
						completionBlock(data, nil)
						return nil
					}

					// Prepare Items for globale usage
					if item.type == .file { // only files can be added to the globale pasteboard
						guard let itemMimeType = item.mimeType else { return }

						let mimeTypeCF = itemMimeType as CFString
						guard let rawUti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeTypeCF, nil)?.takeRetainedValue() as String? else { return }

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
					}
					itemProviderItems.append(itemProvider)
				})

				globalPasteboard.itemProviders = itemProviderItems

				var subtitle = "%ld Item was copied to the clipboard".localized
				if itemProviderItems.count > 1 {
					subtitle = "%ld Items were copied to the clipboard".localized
				}

				if containsFolders {
					let subtitleFolder = String(format:"Please note: Folders can only be pasted into the %@ app and the same account.".localized, VendorServices.shared.appName)
					subtitle = String(format: "%@\n\n%@", subtitle, subtitleFolder)
				}

				OnMainThread {
					if let navigationController = viewController.navigationController {
						_ = NotificationHUDViewController(on: navigationController, title: "Copy".localized, subtitle: String(format: subtitle, itemProviderItems.count))
					}
				}
			}
		}

		hudViewController.presentHUDOn(viewController: viewController)

		self.completed()
	}
}
