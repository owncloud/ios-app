//
//  ShareViewController.swift
//  ownCloud Share Extension
//
//  Created by Matthias Hühne on 10.03.20.
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
import MobileCoreServices

class ShareViewController: MoreStaticTableViewController {
	override func viewDidLoad() {
		super.viewDidLoad()

		AppLockManager.shared.passwordViewHostViewController = self
		AppLockManager.shared.showLockscreenIfNeeded()

		OCExtensionManager.shared.addExtension(CreateFolderAction.actionExtension)
		Theme.shared.add(tvgResourceFor: "owncloud-logo")
		OCItem.registerIcons()
		setupNavigationBar()
		setupAccountSelection()
	}

	@objc private func cancelAction () {
		let error = NSError(domain: "ShareViewErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Canceled by user"])
		extensionContext?.cancelRequest(withError: error)
	}

	private func setupNavigationBar() {
		self.navigationItem.title = OCAppIdentity.shared.appName ?? "ownCloud"

		let itemCancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAction))
		self.navigationItem.setRightBarButton(itemCancel, animated: false)
	}

	func setupAccountSelection() {
		let title = NSAttributedString(string: "Save File".localized, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .heavy)])

		var actionsRows: [StaticTableViewRow] = []
		OCBookmarkManager.shared.loadBookmarks()
		let bookmarks : [OCBookmark] = OCBookmarkManager.shared.bookmarks as [OCBookmark]
		if bookmarks.count > 0 {
			let rowDescription = StaticTableViewRow(label: "Choose an account and folder to import the file into.".localized, alignment: .center)
			actionsRows.append(rowDescription)

			for (bookmark) in bookmarks {
				let row = StaticTableViewRow(buttonWithAction: { (_ row, _ sender) in
					self.openDirectoryPicker(for: bookmark)
				}, title: bookmark.shortName, style: .plain, image: Theme.shared.image(for: "owncloud-logo", size: CGSize(width: 25, height: 25)), imageWidth: 25, alignment: .left)
				actionsRows.append(row)
			}
		} else {
			let rowDescription = StaticTableViewRow(label: "No account configured.\nSetup an new account in the app, before you can save a file.".localized, alignment: .center)
			actionsRows.append(rowDescription)
		}

		self.addSection(MoreStaticTableViewSection(headerAttributedTitle: title, identifier: "actions-section", rows: actionsRows))
	}

	func openDirectoryPicker(for bookmark: OCBookmark ) {
		OCCoreManager.shared.requestCore(for: bookmark, setup: { (_, _) in
		}, completionHandler: { (core, error) in
			if let core = core, error == nil {
				let directoryPickerViewController = ClientDirectoryPickerViewController(core: core, path: "/", selectButtonTitle: "Save here".localized, avoidConflictsWith: [], choiceHandler: { (selectedDirectory) in
					if let targetDirectory = selectedDirectory {
						self.importFiles(to: targetDirectory, bookmark: bookmark, core: core)
					}
				})
				OnMainThread {
					self.navigationController?.pushViewController(directoryPickerViewController, animated: true)
				}
			}
		})
	}

    func importFiles(to targetDirectory : OCItem, bookmark: OCBookmark, core : OCCore?) {
        if let inputItems : [NSExtensionItem] = self.extensionContext?.inputItems as? [NSExtensionItem] {

			let progressHUDViewController = ProgressHUDViewController(on: self, label: "Saving".localized)

            for item : NSExtensionItem in inputItems {
				if let attachments = item.attachments {
                    if attachments.isEmpty {
                        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                        return
                    }

                    for (index, current) in attachments.enumerated() {
						if let type = current.registeredTypeIdentifiers.first, current.hasItemConformingToTypeIdentifier(kUTTypeItem as String) {
                            current.loadItem(forTypeIdentifier: kUTTypeItem as String, options: nil, completionHandler: {(item, error) -> Void in
                                if error == nil {
                                    if let url = item as? URL {
										self.importFile(url: url, to: targetDirectory, bookmark: bookmark, core: core) { (_) in
											if (index + 1) == attachments.count {
												OnMainThread {
													progressHUDViewController.dismiss(animated: true, completion: {
														self.dismiss(animated: true)
														self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
													})
												}
											}
										}
									} else if let data = item as? Data {
										let ext = self.utiToFileExtension(type)
                                        let tempFilePath = NSTemporaryDirectory() + (current.suggestedName ?? "Import") + "." + (ext ?? type)

										FileManager.default.createFile(atPath: tempFilePath, contents:data, attributes:nil)

										self.importFile(url: URL(fileURLWithPath: tempFilePath), to: targetDirectory, bookmark: bookmark, core: core) { (_) in
											try? FileManager.default.removeItem(atPath: tempFilePath)

											if (index + 1) == attachments.count {
												OnMainThread {
													progressHUDViewController.dismiss(animated: true, completion: {
														self.dismiss(animated: true)
														self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
													})
												}
											}
										}
									}
                                } else {
                                    print("ERROR: \(error)")
                                }
                            })
                        }
                    }
                }
            }
        }
    }

	func importFile(url importItemURL: URL, to targetDirectory : OCItem, bookmark: OCBookmark, core : OCCore?, completion: @escaping (_ error: Error?) -> Void) {
		let name = importItemURL.lastPathComponent
		if core?.importItemNamed(name,
					 at: targetDirectory,
					 from: importItemURL,
					 isSecurityScoped: false,
					 options: [OCCoreOption.importByCopying : true,
						   OCCoreOption.automaticConflictResolutionNameStyle : OCCoreDuplicateNameStyle.bracketed.rawValue],
					 placeholderCompletionHandler: { (error, item) in
						if error != nil {
							Log.debug("Error uploading \(Log.mask(name)) to \(Log.mask(targetDirectory.path)), error: \(error?.localizedDescription ?? "" )")
							completion(error)
						}

						OnBackgroundQueue(after: 2) {
							// Return OCCore after 2 seconds, giving the core a chance to schedule the upload with a NSURLSession
							OCCoreManager.shared.returnCore(for: bookmark, completionHandler: nil)
						}
					 },
					 resultHandler: { (error, _ core, _ item, _) in
						if error != nil {
							Log.debug("Error uploading \(Log.mask(name)) to \(Log.mask(targetDirectory.path)), error: \(error?.localizedDescription ?? "" )")
							completion(error)
						} else {
							Log.debug("Success uploading \(Log.mask(name)) to \(Log.mask(targetDirectory.path))")
							completion(nil)
						}
					}
		) == nil {
			Log.debug("Error setting up upload of \(Log.mask(name)) to \(Log.mask(targetDirectory.path))")
			let error = NSError(domain: "ImportFileErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Canceled by user"])
			completion(error)
		}
	}
}

extension ShareViewController {
	public func utiToFileExtension(_ utiType: String) -> String? {
		guard let ext = UTTypeCopyPreferredTagWithClass(utiType as CFString, kUTTagClassFilenameExtension) else { return nil }

		return ext.takeRetainedValue() as String
	}
}
