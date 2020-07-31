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

	var willAppearInitial = false
	var didAppearInitial = false

	override func viewDidLoad() {
		super.viewDidLoad()

		OCCoreManager.shared.memoryConfiguration = .minimum // Limit memory usage
		OCHTTPPipelineManager.setupPersistentPipelines() // Set up HTTP pipelines

		AppLockManager.shared.passwordViewHostViewController = self
		AppLockManager.shared.cancelAction = { [weak self] in
			self?.returnCores(completion: {
				self?.extensionContext?.cancelRequest(withError: NSError(domain: NSErrorDomain.ShareViewErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Canceled by user"]))
			})
		}

		OCExtensionManager.shared.addExtension(CreateFolderAction.actionExtension)
		OCItem.registerIcons()
		setupNavigationBar()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if !willAppearInitial {
			willAppearInitial = true
			AppLockManager.shared.showLockscreenIfNeeded()

			if let appexNavigationController = self.navigationController as? AppExtensionNavigationController {
				appexNavigationController.dismissalAction = { [weak self] (_) in
					self?.returnCores(completion: {
						Log.debug("Returned all cores (share sheet was closed / dismissed)")
					})
				}
			}
			setupAccountSelection()
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		if didAppearInitial {
			self.returnCores(completion: {
				Log.debug("Returned all cores (back to server list)")
			})
		}

		didAppearInitial = true
	}

	private var requestedCoreBookmarks : [OCBookmark] = []

	func requestCore(for bookmark: OCBookmark, completionHandler: @escaping (OCCore?, Error?) -> Void) {
		requestedCoreBookmarks.append(bookmark)

		OCCoreManager.shared.requestCore(for: bookmark, setup: nil, completionHandler: { (core, error) in
			if error != nil {
				// Remove only one entry, not all for that bookmark
				if let index = self.requestedCoreBookmarks.index(of: bookmark) {
					self.requestedCoreBookmarks.remove(at: index)
				}
			}
			completionHandler(core, error)
		})
	}

	func returnCore(for bookmark: OCBookmark, completionHandler: @escaping () -> Void) {
		OCCoreManager.shared.returnCore(for: bookmark, completionHandler: {
			// Remove only one entry, not all for that bookmark
			if let index = self.requestedCoreBookmarks.index(of: bookmark) {
				self.requestedCoreBookmarks.remove(at: index)
			}

			completionHandler()
		})
	}

	func returnCores(completion: (() -> Void)?) {
		let waitGroup = DispatchGroup()
		let returnBookmarks = requestedCoreBookmarks

		requestedCoreBookmarks = []

		for bookmark in returnBookmarks {
			waitGroup.enter()

			OCCoreManager.shared.returnCore(for: bookmark, completionHandler: {
				waitGroup.leave()
			})
		}

		waitGroup.notify(queue: .main, execute: {
			OnMainThread {
				completion?()
			}
		})
	}

	@objc private func cancelAction () {
		self.returnCores(completion: {
			let error = NSError(domain: NSErrorDomain.ShareViewErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Canceled by user"])
			self.extensionContext?.cancelRequest(withError: error)
		})
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
						self.openDirectoryPicker(for: bookmark, withBackButton: true)
					}, title: bookmark.shortName, style: .plain, image: UIImage(named: "bookmark-icon")?.scaledImageFitting(in: CGSize(width: 25.0, height: 25.0)), imageWidth: 25, alignment: .left)
					actionsRows.append(row)
				}
			} else if let bookmark = bookmarks.first {
				self.openDirectoryPicker(for: bookmark, withBackButton: false)
			}
		} else {
			let rowDescription = StaticTableViewRow(label: "No account configured.\nSetup an new account in the app to save to.".localized, alignment: .center)
			actionsRows.append(rowDescription)
		}

		self.addSection(MoreStaticTableViewSection(headerAttributedTitle: title, identifier: "actions-section", rows: actionsRows))
	}

	func openDirectoryPicker(for bookmark: OCBookmark, withBackButton: Bool) {
		self.requestCore(for: bookmark, completionHandler: { (core, error) in
			if let core = core, error == nil {
				OnMainThread {
					let directoryPickerViewController = ClientDirectoryPickerViewController(core: core, path: "/", selectButtonTitle: "Save here".localized, avoidConflictsWith: [], choiceHandler: { [weak core] (selectedDirectory) in
						if let targetDirectory = selectedDirectory {
							let progressHUDViewController = ProgressHUDViewController(on: self, label: "Saving".localized)
							self.importFiles(to: targetDirectory, bookmark: bookmark, core: core, completion: { [weak self] in
								OnMainThread {
									progressHUDViewController.dismiss(animated: true, completion: {
										self?.dismiss(animated: true, completion: {
											self?.returnCores(completion: {
												OnMainThread {
													self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
												}
											})
										})
									})
								}
							})
						}
					})

					directoryPickerViewController.cancelAction = { [weak self] in
						self?.dismiss(animated: true, completion: {
							self?.returnCores(completion: {
								OnMainThread {
									self?.extensionContext?.cancelRequest(withError: NSError(domain: NSErrorDomain.ShareViewErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Canceled by user"]))
								}
							})
						})
					}
					if !withBackButton {
						directoryPickerViewController.navigationItem.setHidesBackButton(true, animated: false)
						directoryPickerViewController.navigationItem.title = OCAppIdentity.shared.appDisplayName ?? "ownCloud"
					}
					self.navigationController?.pushViewController(directoryPickerViewController, animated: withBackButton)
				}
			}
		})
	}

	func importFiles(to targetDirectory : OCItem, bookmark: OCBookmark, core : OCCore?, completion: @escaping () -> Void) {
		if let inputItems : [NSExtensionItem] = self.extensionContext?.inputItems as? [NSExtensionItem] {
			let dispatchGroup = DispatchGroup()

			for item : NSExtensionItem in inputItems {
				if let attachments = item.attachments {
					for attachment in attachments {
						if let type = attachment.registeredTypeIdentifiers.first, attachment.hasItemConformingToTypeIdentifier(kUTTypeItem as String) {
							dispatchGroup.enter()

							if type == "public.plain-text" || type == "public.url" {
								attachment.loadItem(forTypeIdentifier: type, options: nil, completionHandler: { [weak core] (item, error) -> Void in
									if error == nil {
										var data : Data?
										var tempFilePath : String?

										if let text = item as? String { // Save plain text content
											let ext = self.utiToFileExtension(type)
											tempFilePath = NSTemporaryDirectory() + (attachment.suggestedName ?? "Text".localized) + "." + (ext ?? type)
											data = Data(text.utf8)
										} else if let url = item as? URL { // Download URL content
											do {
												tempFilePath = NSTemporaryDirectory() + url.lastPathComponent
												data = try Data(contentsOf: url)
											} catch {
												dispatchGroup.leave()
											}
										}

										if let data = data, let tempFilePath = tempFilePath {
											FileManager.default.createFile(atPath: tempFilePath, contents:data, attributes:nil)

											core?.importThroughFileProvider(url: URL(fileURLWithPath: tempFilePath), to: targetDirectory, bookmark: bookmark, completion: { (_) in
												try? FileManager.default.removeItem(atPath: tempFilePath)
												dispatchGroup.leave()
											})
										} else {
											dispatchGroup.leave()
										}
									} else {
										Log.error("Error loading item: \(String(describing: error))")
										dispatchGroup.leave()
									}
								})
							} else { // Handle local files
								attachment.loadFileRepresentation(forTypeIdentifier: type) { [weak core] (url, error) in
									if error == nil, let url = url {
										core?.importThroughFileProvider(url: url, to: targetDirectory, bookmark: bookmark, completion: { (error) in
											Log.error("Error importing item at \(url.absoluteString) through file provider: \(String(describing: error))")
											dispatchGroup.leave()
										})
									} else {
										Log.error("Error loading item: \(String(describing: error))")
										dispatchGroup.leave()
									}
								}
							}
						}
					}
				}
			}

			dispatchGroup.notify(queue: .main, execute: completion)
		}
	}
}

extension ShareViewController {
	public func utiToFileExtension(_ utiType: String) -> String? {
		guard let ext = UTTypeCopyPreferredTagWithClass(utiType as CFString, kUTTagClassFilenameExtension) else { return nil }

		return ext.takeRetainedValue() as String
	}
}
