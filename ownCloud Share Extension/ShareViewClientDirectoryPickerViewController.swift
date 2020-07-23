//
//  ShareViewDirectoryPickerViewController.swift
//  ownCloud Share Extension
//
//  Created by Matthias Hühne on 22.07.20.
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

import UIKit
import ownCloudSDK
import ownCloudAppShared
import CoreServices

class ShareViewClientDirectoryPickerViewController: ClientDirectoryPickerViewController {

	var bookmark: OCBookmark
	var appearedInitial = false

	// MARK: - Init & deinit
	init(core inCore: OCCore, bookmark inBookmark: OCBookmark, path: String, selectButtonTitle: String, avoidConflictsWith items: [OCItem], appearedInitial initial: Bool, choiceHandler: @escaping ClientDirectoryPickerChoiceHandler) {

		bookmark = inBookmark
		appearedInitial = initial

		let folderItemPaths = items.filter({ (item) -> Bool in
			return item.type == .collection && item.path != nil && !item.isRoot
		}).map { (item) -> String in
			return item.path!
		}
		let itemParentPaths = items.filter({ (item) -> Bool in
			return item.path?.parentPath != nil
		}).map { (item) -> String in
			return item.path!.parentPath
		}

		var navigationPathFilter : ClientDirectoryPickerPathFilter?

		if folderItemPaths.count > 0 {
			navigationPathFilter = { (targetPath) in
				return !folderItemPaths.contains(targetPath)
			}
		}

		super.init(core: inCore, path: path, selectButtonTitle: selectButtonTitle, allowedPathFilter: { (targetPath) in
			// Disallow all paths as target that are parent of any of the items
			return !itemParentPaths.contains(targetPath)
		}, navigationPathFilter: navigationPathFilter, choiceHandler: choiceHandler)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if self.navigationController?.viewControllers.count == 1 {
			self.navigationItem.title = OCAppIdentity.shared.appDisplayName ?? "ownCloud"
		}

		if !appearedInitial {
			appearedInitial = true
			AppLockManager.shared.showLockscreenIfNeeded()
		}
	}
}

extension ClientDirectoryPickerViewController {

	func importFiles(to targetDirectory : OCItem, bookmark: OCBookmark, core : OCCore?) {
		if let inputItems : [NSExtensionItem] = self.extensionContext?.inputItems as? [NSExtensionItem] {

			let dispatchGroup = DispatchGroup()
			let progressHUDViewController = ProgressHUDViewController(on: self, label: "Saving".localized)

			for item : NSExtensionItem in inputItems {
				if let attachments = item.attachments {
					for attachment in attachments {
						if let type = attachment.registeredTypeIdentifiers.first, attachment.hasItemConformingToTypeIdentifier(kUTTypeItem as String) {
							dispatchGroup.enter()

							attachment.loadItem(forTypeIdentifier: kUTTypeItem as String, options: nil, completionHandler: { [weak core] (item, error) -> Void in
								if error == nil {
									if let url = item as? URL {
										self.importFile(url: url, to: targetDirectory, bookmark: bookmark, core: core) { (_) in
											dispatchGroup.leave()
										}
									} else if let data = item as? Data {
										let ext = self.utiToFileExtension(type)
										let tempFilePath = NSTemporaryDirectory() + (attachment.suggestedName ?? "Import") + "." + (ext ?? type)

										FileManager.default.createFile(atPath: tempFilePath, contents:data, attributes:nil)

										self.importFile(url: URL(fileURLWithPath: tempFilePath), to: targetDirectory, bookmark: bookmark, core: core) { (_) in
											try? FileManager.default.removeItem(atPath: tempFilePath)

											dispatchGroup.leave()
										}
									}
								} else {
									Log.error("Error loading item: \(String(describing: error))")
									dispatchGroup.leave()
								}
							})
						}
					}
				}
			}

			dispatchGroup.notify(queue: .main) {
				OCCoreManager.shared.returnCore(for: bookmark, completionHandler: {
					OnMainThread {
						progressHUDViewController.dismiss(animated: true, completion: {
							self.dismiss(animated: true)
							self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
						})
					}
				})
			}
		}
	}

	func importFile(url importItemURL: URL, to targetDirectory : OCItem, bookmark: OCBookmark, core : OCCore?, completion: @escaping (_ error: Error?) -> Void) {
		let name = importItemURL.lastPathComponent
		if core?.importItemNamed(name,
					 at: targetDirectory,
					 from: importItemURL,
					 isSecurityScoped: false,
					 options: [
						.importByCopying : true,
						.automaticConflictResolutionNameStyle : OCCoreDuplicateNameStyle.bracketed.rawValue
					 ],
					 placeholderCompletionHandler: { (error, _) in
						if error != nil {
							Log.debug("Error uploading \(Log.mask(name)) to \(Log.mask(targetDirectory.path)), error: \(error?.localizedDescription ?? "" )")
							completion(error)
						} else {
							completion(nil)
						}
					 },
					 resultHandler: nil
		) == nil {
			Log.debug("Error setting up upload of \(Log.mask(name)) to \(Log.mask(targetDirectory.path))")
			let error = NSError(domain: NSErrorDomain.ShareViewErrorDomain, code: 1, userInfo: [NSLocalizedDescriptionKey: "Error setting up upload of \(Log.mask(name)) to \(Log.mask(targetDirectory.path))"])
			completion(error)
		}
	}

	public func utiToFileExtension(_ utiType: String) -> String? {
		guard let ext = UTTypeCopyPreferredTagWithClass(utiType as CFString, kUTTagClassFilenameExtension) else { return nil }

		return ext.takeRetainedValue() as String
	}
}
