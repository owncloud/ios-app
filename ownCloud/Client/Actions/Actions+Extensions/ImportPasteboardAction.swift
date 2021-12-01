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

extension String {
	func trimIllegalCharacters() -> String {
		return self
			.trimmingCharacters(in: .illegalCharacters)
			.trimmingCharacters(in: .whitespaces)
			.trimmingCharacters(in: .newlines)
			.filter({ $0.isASCII })
	}
}

class ImportPasteboardAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.importpasteboard") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Paste".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreFolder, .keyboardShortcut] }
	override class var keyCommand : String? { return "V" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command] }

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
		var importToRootItem : OCItem?

		if let root = context.query?.rootItem {
			importToRootItem = root
		} else if let root = context.preferences?["rootItem"] as? OCItem { // KeyCommands send the rootItem via Preferences, because if a table view cell is selected, we need the folder root item
			importToRootItem = root
		}

		guard context.items.count > 0, let core = self.core, let rootItem = importToRootItem else {
			completed(with: NSError(ocError: .insufficientParameters))
			return
		}
		let generalPasteboard = UIPasteboard.general

		if generalPasteboard.contains(pasteboardTypes: [ImportPasteboardAction.InternalPasteboardCopyKey, ImportPasteboardAction.InternalPasteboardCutKey]) {

			for item in generalPasteboard.itemProviders {
				// Copy Items Internally
				item.loadDataRepresentation(forTypeIdentifier: ImportPasteboardAction.InternalPasteboardCopyKey, completionHandler: { data, error in
					if let data = data, let object = OCItemPasteboardValue(data: data) {
							let item = object.item
							let bookmarkUUID = object.bookmarkUUID
						guard let name = item.name else { return }

						if core.bookmark.uuid.uuidString == bookmarkUUID {
							core.copy(item, to: rootItem, withName: name, options: nil, resultHandler: { (error, _, _, _) in
								if error != nil {
									self.completed(with: error)
								}
							})
						} else {
							// Move between Accounts
							guard let sourceBookmark = OCBookmarkManager.shared.bookmark(forUUIDString: bookmarkUUID), let destinationItem = self.context.items.first else {return }

								OCCoreManager.shared.requestCore(for: sourceBookmark, setup: nil) { (srcCore, error) in
									if error == nil {
										srcCore?.downloadItem(item, options: nil, resultHandler: { (error, _, srcItem, _) in
											if error == nil, let srcItem = srcItem, let localURL = srcCore?.localCopy(of: srcItem) {
												core.importItemNamed(srcItem.name, at: destinationItem, from: localURL, isSecurityScoped: false, options: nil, placeholderCompletionHandler: nil) { (_, _, _, _) in
												}
											}
										})
									}
								}
						}
					}
				})

				// Cut Item Internally
				item.loadDataRepresentation(forTypeIdentifier: ImportPasteboardAction.InternalPasteboardCutKey, completionHandler: { data, error in
					if let data = data, let object = OCItemPasteboardValue(data: data) {

							let item = object.item
							let bookmarkUUID = object.bookmarkUUID
						guard let name = item.name else { return }

						if core.bookmark.uuid.uuidString == bookmarkUUID {
							core.move(item, to: rootItem, withName: name, options: nil) { (error, _, _, _) in
						  if error != nil {
							  self.completed(with: error)
						  } else {
							generalPasteboard.items = []
						  }
					  }
						} else {
							// Move between Accounts
							guard let sourceBookmark = OCBookmarkManager.shared.bookmark(forUUIDString: bookmarkUUID), let destinationItem = self.context.items.first else {return }

								OCCoreManager.shared.requestCore(for: sourceBookmark, setup: nil) { (srcCore, error) in
									if error == nil {
										srcCore?.downloadItem(item, options: nil, resultHandler: { (error, _, srcItem, _) in
											if error == nil, let srcItem = srcItem, let localURL = srcCore?.localCopy(of: srcItem) {
												core.importItemNamed(srcItem.name, at: destinationItem, from: localURL, isSecurityScoped: false, options: nil, placeholderCompletionHandler: nil) { (_, _, _, _) in

													srcCore?.delete(srcItem, requireMatch: true, resultHandler: { (error, _, _, _) in
													   if error != nil {
														   Log.log("Error \(String(describing: error)) deleting \(String(describing: item.path))")
													} else {

														generalPasteboard.items = []
													}
												   })
												}
											}
										})
									}
								}
						}
					}
				})
			}
		} else {
			// System-wide Pasteboard Items

			for item in generalPasteboard.itemProviders {
				let typeIdentifiers = item.registeredTypeIdentifiers
				let preferredUTIs = [
					kUTTypeImage,
					kUTTypeMovie,
					kUTTypePDF,
					kUTTypeText,
					kUTTypeRTF,
					kUTTypeHTML,
					kUTTypePlainText
				]
				var useUTI : String?
				var useIndex : Int = Int.max

				for typeIdentifier in typeIdentifiers {
					if !typeIdentifier.hasPrefix("dyn.") {
						for preferredUTI in preferredUTIs {
							let conforms = UTTypeConformsTo(typeIdentifier as CFString, preferredUTI)

							// Log.log("\(preferredUTI) vs \(typeIdentifier) -> \(conforms)")

							if conforms {
								if let utiIndex = preferredUTIs.index(of: preferredUTI), utiIndex < useIndex {
									useUTI = typeIdentifier
									useIndex = utiIndex
								}
							}
						}
					}
				}

				if useUTI == nil, typeIdentifiers.count == 1 {
					useUTI = typeIdentifiers.first
				}

				if useUTI == nil {
					useUTI = kUTTypeData as String
				}

				var fileName: String?

				item.loadFileRepresentation(forTypeIdentifier: useUTI!) { (url, _ error) in
					guard let url = url else { return }

					let fileNameMaxLength = 16

					if useUTI == kUTTypeUTF8PlainText as String {
						fileName = try? String(String(contentsOf: url, encoding: .utf8).prefix(fileNameMaxLength) + ".txt")
					}

					if useUTI == kUTTypeRTF as String {
						let options = [NSAttributedString.DocumentReadingOptionKey.documentType : NSAttributedString.DocumentType.rtf]
						fileName = try? String(NSAttributedString(url: url, options: options, documentAttributes: nil).string.prefix(fileNameMaxLength) + ".rtf")
					}

					fileName = fileName?
						.trimmingCharacters(in: .illegalCharacters)
						.trimmingCharacters(in: .whitespaces)
						.trimmingCharacters(in: .newlines)
						.filter({ $0.isASCII })

					if fileName == nil {
						fileName = url.lastPathComponent
					}

					guard let name = fileName else { return }

					self.upload(itemURL: url, rootItem: rootItem, name: name)
				}
			}
		}
	}

	open func upload(itemURL: URL, rootItem: OCItem, name: String, completionHandler: ClientActionCompletionHandler? = nil) {
		core?.importItemNamed(name, at: rootItem, from: itemURL, isSecurityScoped: false, options: [
			OCCoreOption.importByCopying : false,
			OCCoreOption.automaticConflictResolutionNameStyle : OCCoreDuplicateNameStyle.bracketed.rawValue
		], placeholderCompletionHandler: nil, resultHandler: { (error, _ core, _ item, _) in
			if error != nil {
				Log.debug("Error uploading \(Log.mask(name)) file to \(Log.mask(rootItem.path))")
				completionHandler?(false)
			} else {
				Log.debug("Success uploading \(Log.mask(name)) file to \(Log.mask(rootItem.path))")
				completionHandler?(true)
			}
		})
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
