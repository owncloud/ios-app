//
//  UncompressAction.swift
//  ownCloud
//
//  Created by Matthias Hühne on 05/06/2020.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2020, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import ownCloudSDK
import ownCloudApp

class UncompressAction: Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.uncompress") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String { return "Uncompress".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreFolder, .toolbar, .keyboardShortcut] }
	override class var keyCommand : String? { return "Z" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command] }
	class var supportedMimeTypes : [String] { return ["application/zip"] }

	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if let core = forContext.core, forContext.items.count == 1, forContext.items.contains(where: {$0.type == .file && ($0.permissions.contains(.writable) || $0.parentItem(from: core)? .permissions.contains(.createFile) == true)}) {
			if let item = forContext.items.first, let mimeType = item.mimeType {
				if supportedMimeTypes.filter({
					if mimeType.contains($0) {
						return true
					}

					return false
				}).count == 1 {
					return .middle
				}
			}
		}

		// Examine items in context
		return .none
	}

	override func run() {
		guard context.items.count > 0, let hostViewController = context.viewController, let core = self.core else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let hudViewController = DownloadItemsHUDViewController(core: core, downloadItems: context.items as [OCItem]) { [weak hostViewController] (error, downloadedItems) in

			if let downloadedItems = downloadedItems, let downloadedItem = downloadedItems.first, error == nil, let fileItem = self.context.items.first, let parentItem = fileItem.parentItem(from: core), let fileURL = downloadedItem.file.url, let parentPath = parentItem.path, let fileName = fileItem.path {

				print("--> uncompress \(fileURL)")

				let zipItems = ZIPArchive.uncompressContents(ofZipFile: fileURL, parentItem: parentItem, withPassword: nil, with: core)
/*
				for item in zipItems {
					print("--> \(item.filepath) \(item.isDirectory) \(item.absolutePath)")
				}*/

				let collectionItems = zipItems.filter { (item) -> Bool in
					return item.isDirectory
				}

				let fileItems = zipItems.filter { (item) -> Bool in
					return !item.isDirectory
				}
				let fileName = ((fileName as NSString).lastPathComponent as NSString).deletingPathExtension

				let dispatchGroup = DispatchGroup()

				core.createFolder(fileName, inside: parentItem, options: [
					.returnImmediatelyIfOfflineOrUnavailable : true,
					.addTemporaryClaimForPurpose 		 : OCCoreClaimPurpose.view.rawValue
				]) { (error, subcore, containerItem, _) in

					guard let containerItem = containerItem else { return }
					var lastItem = containerItem
					for collectionItem in collectionItems {
						OnMainThread {
							dispatchGroup.enter()
							let newFolderPath = (collectionItem.filepath as NSString).lastPathComponent

							var insideItem = containerItem
							if let lastpath = lastItem.path, lastpath.hasSuffix(collectionItem.filepath) {
								insideItem = lastItem
							}
							print("--> create folder \(newFolderPath) in \(insideItem.path) \(collectionItem.filepath)")

							subcore.createFolder(newFolderPath, inside: insideItem, options: [
								.returnImmediatelyIfOfflineOrUnavailable : true,
								.addTemporaryClaimForPurpose 		 : OCCoreClaimPurpose.view.rawValue
							]) { (error, core, item, _) in
								print("create folder finished \(item?.path)")
								if let item = item {
									lastItem = item
								}
								dispatchGroup.leave()
							}
							dispatchGroup.wait()
						}
					}
				}
			}

		}

		hudViewController.presentHUDOn(viewController: hostViewController)
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem || location == .moreFolder {
			if #available(iOS 13.0, *) {
				return UIImage(systemName: "cube.box")?.tinted(with: Theme.shared.activeCollection.tintColor)
			} else {
				// Fallback on earlier versions
			}
		}

		return nil
	}

	internal func upload(itemURL: URL, to rootItem: OCItem, name: String) -> Bool {

		if core != nil, let progress = itemURL.upload(with: core, at: rootItem) {
			self.publish(progress: progress)
			return true
		} else {
			Log.debug("Error setting up upload of \(Log.mask(name)) to \(Log.mask(rootItem.path))")
			return false
		}
	}
}
