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
import UniformTypeIdentifiers

class OCItemPasteboardValue : NSObject, NSSecureCoding {
	static var supportsSecureCoding: Bool = true

	var item : OCItem?
	var bookmarkUUID : String?

	static func decode(data: Data) -> OCItemPasteboardValue? {
		if let value = try? NSKeyedUnarchiver.unarchivedObject(ofClass: OCItemPasteboardValue.self, from: data) {
			return value
		}

		return nil
	}

	func encode(with coder: NSCoder) {
		coder.encode(item, forKey: "item")
		coder.encode(bookmarkUUID as NSString?, forKey: "bookmarkUUID")
	}

	init(item: OCItem?, bookmarkUUID: String?) {
		super.init()
		self.item = item
		self.bookmarkUUID = bookmarkUUID
	}

	required init?(coder: NSCoder) {
		super.init()

		item = coder.decodeObject(of: OCItem.self, forKey: "item")
		bookmarkUUID = coder.decodeObject(of: NSString.self, forKey: "bookmarkUUID") as String?
	}

	var encodedData : Data? {
		return try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: true)
	}
}

class CopyAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.copy") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Copy".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreDetailItem, .moreFolder, .multiSelection, .dropAction, .keyboardShortcut, .contextMenuItem, .accessibilityCustomAction] }
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
		return UIImage(named: "copy-file")?.withRenderingMode(.alwaysTemplate)
	}

	func showDirectoryPicker() {
		guard context.items.count > 0, let clientContext = context.clientContext, let bookmark = context.core?.bookmark else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let items = context.items
		let startLocation: OCLocation = .account(bookmark)

		var titleText: String

		if items.count > 1 {
			titleText = "Copy {{itemCount}} items".localized(["itemCount" : "\(items.count)"])
		} else {
			titleText = "Copy \"{{itemName}}\"".localized(["itemName" : items.first?.name ?? "?"])
		}

		let locationPicker = ClientLocationPicker(location: startLocation, selectButtonTitle: "Copy here".localized, headerTitle: titleText, headerSubTitle: "Select target.".localized, avoidConflictsWith: items, choiceHandler: { (selectedDirectoryItem, location, _, cancelled) in
			guard !cancelled, let selectedDirectoryItem else {
				self.completed(with: NSError(ocError: OCError.cancelled))
				return
			}

			items.forEach({ (item) in
				guard let itemName = item.name else {
					return
				}

				if let progress = self.core?.copy(item, to: selectedDirectoryItem, withName: itemName, options: nil, resultHandler: { (error, _, _, _) in
					if error != nil {
						Log.error("Error \(String(describing: error)) copying \(String(describing: itemName)) to \(String(describing: location))")
					}
				}) {
					self.publish(progress: progress)
				}
			})

			self.completed()
		})

		locationPicker.present(in: clientContext)
	}

	func copyToPasteboard() {
		guard context.items.count > 0, let viewController = context.clientContext?.presentationViewController, let core = self.core else {
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
				items.forEach({ (item) in
					let itemProvider = NSItemProvider()
					itemProvider.suggestedName = item.name
					if item.type == .collection {
						containsFolders = true
					}

					// Prepare Items for internal use
					itemProvider.registerDataRepresentation(forTypeIdentifier: ImportPasteboardAction.InternalPasteboardCopyKey, visibility: .ownProcess) { (completionBlock) -> Progress? in
						completionBlock(OCItemPasteboardValue(item: item, bookmarkUUID: uuid).encodedData, nil)
						return nil
					}

					// Prepare Items for globale usage
					if item.type == .file { // only files can be added to the globale pasteboard
						guard let itemMimeType = item.mimeType else { return }

						guard let rawUti = UTType(mimeType: itemMimeType)?.identifier else { return }

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
					if let presentationViewController = self.context.clientContext?.presentationViewController {
						_ = NotificationHUDViewController(on: presentationViewController, title: "Copy".localized, subtitle: String(format: subtitle, itemProviderItems.count))
					}
				}
			}
		}

		hudViewController.presentHUDOn(viewController: viewController)

		self.completed()
	}
}
