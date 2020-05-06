//
//  ZipAction.swift
//  ownCloud
//
//  Created by Matthias Hühne on 05/04/2020.
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

class ZipAction: Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.zip") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String { return "Compress as ZIP file".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreFolder, .toolbar, .keyboardShortcut] }
	override class var keyCommand : String? { return "Z" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command] }

	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		return .afterMiddle
	}

	let defaultZipName = "Archive.zip".localized

	override func run() {
		guard context.items.count > 0, let hostViewController = context.viewController, let core = self.core else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		var fileItems = context.items.filter { (item) -> Bool in
			if item.type == .collection {
				return false
			}

			return true
		}

		var collectionItems = context.items.filter { (item) -> Bool in
			if item.type == .file {
				return false
			}

			return true
		}

		let dispatchGroup = DispatchGroup()
		for collection in collectionItems {

			dispatchGroup.enter()
			core.retrieveSubItems(for: collection) { (items) in
				let subFileItems = items?.filter { (item) -> Bool in
					if item.type == .collection {
						return false
					}

					return true
				}
				let subCollectionItems = items?.filter { (item) -> Bool in
					if item.type == .file {
						return false
					}

					return true
				}
				fileItems.append(contentsOf: subFileItems!)
				collectionItems.append(contentsOf: subCollectionItems!)
				dispatchGroup.leave()
			}
		}
		dispatchGroup.wait()

		let hudViewController = DownloadItemsHUDViewController(core: core, downloadItems: fileItems as [OCItem]) { [weak hostViewController] (error, downloadedItems) in

			var unifiedItems = downloadedItems

			unifiedItems?.append(contentsOf:
				collectionItems.map { (item) -> DownloadItem in
					return DownloadItem(file: OCFile(), item: item)
			})

			if let error = error {
				if (error as NSError).isOCError(withCode: .cancelled) {
					return
				}

				let appName = OCAppIdentity.shared.appName ?? "ownCloud"
				let alertController = ThemedAlertController(with: "Cannot connect to ".localized + appName, message: appName + " couldn't download file(s)".localized, okLabel: "OK".localized, action: nil)

				hostViewController?.present(alertController, animated: true)
			} else {
				guard let unifiedItems = unifiedItems, unifiedItems.count > 0, let viewController = hostViewController else { return }

				var zipName = self.defaultZipName

				if self.context.items.count == 1, let item = self.context.items.first {
					zipName = String(format: "%@.zip", item.name ?? self.defaultZipName)
				}

				let renameViewController = NamingViewController(with: nil, core: self.core, defaultName: zipName, stringValidator: { name in
					if name.contains("/") || name.contains("\\") {
						return (false, "File name cannot contain / or \\".localized)
					} else {
						return (true, nil)
					}
				}, completion: { newName, _ in

					OnBackgroundQueue {
						if let newName = newName, error == nil, let fileItem = self.context.items.first, let parentItem = fileItem.parentItem(from: core) {
							let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent(newName)
							let error = ZIPArchive.compressContents(of: unifiedItems, fromBasePath: parentItem.path ?? "", asZipFile: zipURL, withPassword: nil)

								if !self.upload(itemURL: zipURL, to: parentItem, name: zipURL.lastPathComponent) {
									self.completed(with: NSError(ocError: .internal))
									return
								} else {
									self.completed()
								}

							do {
								try FileManager.default.removeItem(at: zipURL)
							} catch {
							}
						}
					}
				})

				renameViewController.navigationItem.title = "Compress".localized

				let navigationController = ThemeNavigationController(rootViewController: renameViewController)
				navigationController.modalPresentationStyle = .overFullScreen

				viewController.present(navigationController, animated: true)
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
