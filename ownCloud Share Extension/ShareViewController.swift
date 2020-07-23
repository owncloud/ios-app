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
		}

		setupAccountSelection()
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
							self.importFiles(to: targetDirectory, bookmark: bookmark, core: core)
						}
					})

					directoryPickerViewController.cancelAction = { [weak self] in
						self?.returnCores(completion: {
							self?.extensionContext?.cancelRequest(withError: NSError(domain: NSErrorDomain.ShareViewErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Canceled by user"]))
						})
					}

					if !withBackButton {
						directoryPickerViewController.navigationItem.setHidesBackButton(true, animated: false)
					}
					self.navigationController?.pushViewController(directoryPickerViewController, animated: withBackButton)
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
				self.returnCore(for: bookmark, completionHandler: {
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

		core?.acquireFileProviderServicesHost(completionHandler: { (error, serviceHost, doneHandler) in
			let completeImport : (Error?) -> Void = { (error) in
				completion(error)
				doneHandler?()
			}

			if error != nil {
				Log.debug("Error acquiring file provider host: \(error?.localizedDescription ?? "" )")
				completeImport(error)
			} else {
				if let shareFilesRootURL = core?.vault.rootURL?.appendingPathComponent("share-extension", isDirectory: true) {
					// Copy file into shared location
					let tempFileFolderURL = shareFilesRootURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
					let tempFileURL = tempFileFolderURL.appendingPathComponent("file")

					try? FileManager.default.createDirectory(at: tempFileFolderURL, withIntermediateDirectories: true, attributes: [ .protectionKey : FileProtectionType.completeUntilFirstUserAuthentication])
					try? FileManager.default.copyItem(at: importItemURL, to: tempFileURL)

					// Upload file from shared location
					if serviceHost?.importItemNamed(name, at: targetDirectory, from: tempFileURL, isSecurityScoped: false, importByCopying: true, automaticConflictResolutionNameStyle: .bracketed, placeholderCompletionHandler: { (error) in
						// Remove file from shared location
						try? FileManager.default.removeItem(at: tempFileFolderURL)

						if error != nil {
							Log.debug("Error uploading \(Log.mask(name)) to \(Log.mask(targetDirectory.path)), error: \(error?.localizedDescription ?? "" )")
						}

						completeImport(error)
					}) == nil {
						Log.debug("Error setting up upload of \(Log.mask(name)) to \(Log.mask(targetDirectory.path))")
						let error = NSError(domain: NSErrorDomain.ShareViewErrorDomain, code: 1, userInfo: [NSLocalizedDescriptionKey: "Error setting up upload of \(Log.mask(name)) to \(Log.mask(targetDirectory.path))"])

						// Remove file from shared location
						try? FileManager.default.removeItem(at: tempFileFolderURL)

						completeImport(error)
					}
				}
			}
		})
	}
}

extension ShareViewController {
	public func utiToFileExtension(_ utiType: String) -> String? {
		guard let ext = UTTypeCopyPreferredTagWithClass(utiType as CFString, kUTTagClassFilenameExtension) else { return nil }

		return ext.takeRetainedValue() as String
	}
}
