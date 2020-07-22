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
import CoreServices

extension NSErrorDomain {
	static let ShareViewErrorDomain = "ShareViewErrorDomain"
}

class ShareViewController: MoreStaticTableViewController {

	var appearedInitial = false

	override func viewDidLoad() {
		super.viewDidLoad()

		AppLockManager.shared.passwordViewHostViewController = self
		AppLockManager.shared.cancelAction = { [weak self] in
			self?.extensionContext?.cancelRequest(withError: NSError(domain: NSErrorDomain.ShareViewErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Canceled by user"]))
		}

		OCExtensionManager.shared.addExtension(CreateFolderAction.actionExtension)
		OCItem.registerIcons()
		setupNavigationBar()
		setupAccountSelection()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if !appearedInitial {
			appearedInitial = true
			AppLockManager.shared.showLockscreenIfNeeded()
		}
	}

	@objc private func cancelAction () {
		let error = NSError(domain: NSErrorDomain.ShareViewErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Canceled by user"])
		extensionContext?.cancelRequest(withError: error)
	}

	private func setupNavigationBar() {
		self.navigationItem.title = OCAppIdentity.shared.appDisplayName ?? "ownCloud"

		let itemCancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAction))
		self.navigationItem.setRightBarButton(itemCancel, animated: false)
	}

	func setupAccountSelection() {
		let title = NSAttributedString(string: "Save File".localized, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .heavy)])

		var actionsRows: [StaticTableViewRow] = []
		OCBookmarkManager.shared.loadBookmarks()
		let bookmarks : [OCBookmark] = OCBookmarkManager.shared.bookmarks as [OCBookmark]
		if bookmarks.count > 0 {
			if bookmarks.count > 1 {
				let rowDescription = StaticTableViewRow(label: "Choose an account and folder to import into.".localized, alignment: .center)
				actionsRows.append(rowDescription)

				for (bookmark) in bookmarks {
					let row = StaticTableViewRow(buttonWithAction: { (_ row, _ sender) in
						self.openDirectoryPicker(for: bookmark, pushViewController: true)
					}, title: bookmark.shortName, style: .plain, image: UIImage(named: "bookmark-icon")?.scaledImageFitting(in: CGSize(width: 25.0, height: 25.0)), imageWidth: 25, alignment: .left)
					actionsRows.append(row)
				}

				self.addSection(MoreStaticTableViewSection(headerAttributedTitle: title, identifier: "actions-section", rows: actionsRows))
			} else if let bookmark = bookmarks.first {
				self.openDirectoryPicker(for: bookmark, pushViewController: false)
			}
		} else {
			let rowDescription = StaticTableViewRow(label: "No account configured.\nSetup an new account in the app to save to.".localized, alignment: .center)
			actionsRows.append(rowDescription)

			self.addSection(MoreStaticTableViewSection(headerAttributedTitle: title, identifier: "actions-section", rows: actionsRows))
		}
	}

	func openDirectoryPicker(for bookmark: OCBookmark, pushViewController: Bool) {
		OCCoreManager.shared.requestCore(for: bookmark, setup: nil, completionHandler: { (core, error) in
			if let core = core, error == nil {
				OnMainThread {
					let directoryPickerViewController = ClientDirectoryPickerViewController(core: core, path: "/", selectButtonTitle: "Save here".localized, avoidConflictsWith: [], choiceHandler: { [weak core] (selectedDirectory) in
						if let targetDirectory = selectedDirectory {
							self.importFiles(to: targetDirectory, bookmark: bookmark, core: core)
						}
					})

					directoryPickerViewController.cancelAction = { [weak self] in
						OCCoreManager.shared.returnCore(for: bookmark, completionHandler: {
							OnMainThread {
								self?.extensionContext?.cancelRequest(withError: NSError(domain: NSErrorDomain.ShareViewErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Canceled by user"]))
							}
						})
					}

					if pushViewController {
						self.navigationController?.pushViewController(directoryPickerViewController, animated: true)
					} else {
						self.addChild(directoryPickerViewController)
						self.view.addSubview(directoryPickerViewController.view)
						self.toolbarItems = directoryPickerViewController.toolbarItems

						self.navigationItem.searchController = directoryPickerViewController.searchController
						self.navigationItem.hidesSearchBarWhenScrolling = false
					}
				}
			}
		})
	}

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
}

extension ShareViewController {
	public func utiToFileExtension(_ utiType: String) -> String? {
		guard let ext = UTTypeCopyPreferredTagWithClass(utiType as CFString, kUTTagClassFilenameExtension) else { return nil }

		return ext.takeRetainedValue() as String
	}
}
