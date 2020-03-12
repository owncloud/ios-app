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

		// Implement App Lock
		//AppLockManager.shared.showLockscreenIfNeeded()

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
		let bookmarks : [OCBookmark] = OCBookmarkManager.shared.bookmarks as [OCBookmark]

		let rowDescription = StaticTableViewRow(label: "Choose an account and folder to import the file into.".localized, alignment: .center)
		actionsRows.append(rowDescription)

		for (bookmark) in bookmarks {
			let row = StaticTableViewRow(buttonWithAction: { (_ row, _ sender) in
				self.openDirectoryPicker(for: bookmark)
			}, title: bookmark.shortName, style: .plain, image: Theme.shared.image(for: "owncloud-logo", size: CGSize(width: 25, height: 25)), imageWidth: 25, alignment: .left)
			actionsRows.append(row)
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
			print("--> inputItems \(inputItems)")
            for item : NSExtensionItem in inputItems {
				if let attachments = item.attachments {

                    if attachments.isEmpty {
                        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                        return
                    }

                    for current in attachments {
						print("--> \(current.registeredTypeIdentifiers)")
                        if current.hasItemConformingToTypeIdentifier(kUTTypeItem as String) {
                            current.loadItem(forTypeIdentifier: kUTTypeItem as String, options: nil, completionHandler: {(item, error) -> Void in
								print("..>> item \(item)")
                                if error == nil {
                                    if let url = item as? URL {
                                        print("item as url: \(url)")
										self.importFile(url: url, to: targetDirectory, bookmark: bookmark, core: core)
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
		self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

	func importFile(url importItemURL: URL, to targetDirectory : OCItem, bookmark: OCBookmark, core : OCCore?) {
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
						}

						OnBackgroundQueue(after: 2) {
							// Return OCCore after 2 seconds, giving the core a chance to schedule the upload with a NSURLSession
							OCCoreManager.shared.returnCore(for: bookmark, completionHandler: nil)
						}
					 },
					 resultHandler: { (error, _ core, _ item, _) in
						if error != nil {
							Log.debug("Error uploading \(Log.mask(name)) to \(Log.mask(targetDirectory.path)), error: \(error?.localizedDescription ?? "" )")
						} else {
							Log.debug("Success uploading \(Log.mask(name)) to \(Log.mask(targetDirectory.path))")
						}
					}
		) == nil {
			Log.debug("Error setting up upload of \(Log.mask(name)) to \(Log.mask(targetDirectory.path))")
		}
	}
}
