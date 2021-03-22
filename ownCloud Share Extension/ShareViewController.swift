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
import ownCloudApp
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

		if AppLockManager.supportedOnDevice {
			AppLockManager.shared.passwordViewHostViewController = self
			AppLockManager.shared.cancelAction = { [weak self] in
				self?.returnCores(completion: {
					self?.extensionContext?.cancelRequest(withError: NSError(domain: NSErrorDomain.ShareViewErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Canceled by user"]))
				})
			}
		}

		OCExtensionManager.shared.addExtension(CreateFolderAction.actionExtension)
		OCItem.registerIcons()
		setupNavigationBar()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if !willAppearInitial {
			willAppearInitial = true

			if AppLockManager.supportedOnDevice {
				AppLockManager.shared.showLockscreenIfNeeded()
			}

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
		self.navigationItem.title = VendorServices.shared.appName

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
					let directoryPickerViewController = ClientDirectoryPickerViewController(core: core, path: "/", selectButtonTitle: "Save here".localized, avoidConflictsWith: [], choiceHandler: { [weak core] (selectedDirectory, _) in
						if let targetDirectory = selectedDirectory {
							if let vault = core?.vault {
								self.fpServiceSession = OCFileProviderServiceSession(vault: vault)

								self.returnCores(completion: {
									OnMainThread {
										self.navigationController?.popToViewController(self, animated: false)

										let progressViewController = ProgressIndicatorViewController(initialProgressLabel: "Preparing…".localized, cancelHandler: {})

										self.present(progressViewController, animated: false)

										if let fpServiceSession = self.fpServiceSession {
											self.importFiles(to: targetDirectory, serviceSession: fpServiceSession, progressViewController: progressViewController, completion: { [weak self] (error) in
												OnMainThread {
													if let error = error {
														self?.extensionContext?.cancelRequest(withError: error)
														progressViewController.dismiss(animated: false)
													} else {
														self?.extensionContext?.completeRequest(returningItems: [], completionHandler: { (_) in
															OnMainThread {
																progressViewController.dismiss(animated: false)
															}
														})
													}
												}
											})
										}
									}
								})
							}
						}
					})

					directoryPickerViewController.cancelAction = { [weak self] in
						self?.returnCores(completion: {
							OnMainThread {
								self?.extensionContext?.cancelRequest(withError: NSError(domain: NSErrorDomain.ShareViewErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Canceled by user"]))
							}
						})
					}
					if !withBackButton {
						directoryPickerViewController.navigationItem.setHidesBackButton(true, animated: false)
						directoryPickerViewController.navigationItem.title = VendorServices.shared.appName
					}
					self.navigationController?.pushViewController(directoryPickerViewController, animated: withBackButton)
				}
			}
		})
	}

	var fpServiceSession : OCFileProviderServiceSession?
	var asyncQueue : OCAsyncSequentialQueue = OCAsyncSequentialQueue()

	func showAlert(title: String?, message: String? = nil, error: Error? = nil, decisionHandler: @escaping ((_ continue: Bool) -> Void)) {
		OnMainThread {
			let message = message ?? ((error != nil) ? error?.localizedDescription : nil)
			let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

			alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: { (_) in
				decisionHandler(false)
			}))

			if let nsError = error as NSError?, nsError.domain == NSCocoaErrorDomain, nsError.code == NSXPCConnectionInvalid || nsError.code == NSXPCConnectionInterrupted {
				Log.error("XPC connection error: \(String(describing: error))")
			} else {
				alert.addAction(UIAlertAction(title: "Continue".localized, style: .default, handler: { (_) in
					decisionHandler(true)
				}))
			}

			(self.presentedViewController ?? self).present(alert, animated: true, completion: nil)
		}
	}

	func importFiles(to targetDirectory : OCItem, serviceSession: OCFileProviderServiceSession, progressViewController: ProgressIndicatorViewController?, completion: @escaping (_ error: Error?) -> Void) {
		if let inputItems : [NSExtensionItem] = self.extensionContext?.inputItems as? [NSExtensionItem] {
			var totalItems : Int = 0
			var importedItems : Int = 0
			var importError : Error?

			for item : NSExtensionItem in inputItems {
				if let attachments = item.attachments {
					totalItems += attachments.count
				}
			}

			let incrementImportedFile : () -> Void = { [weak progressViewController] in
				importedItems += 1

				OnMainThread {
					progressViewController?.update(progress: Float(importedItems)/Float(totalItems), text: NSString(format: "Importing item %ld of %ld".localized as NSString, importedItems, totalItems) as String)
				}
			}

			// Keep session open
			serviceSession.acquireFileProviderServicesHost(completionHandler: { (_, _, doneHandler) in
				serviceSession.incrementSessionUsage()
				doneHandler?()
			}, errorHandler: { (_) in })

			for item : NSExtensionItem in inputItems {
				if let attachments = item.attachments {
					for attachment in attachments {
						if progressViewController?.cancelled == true {
							break
						}

						if var type = attachment.registeredTypeIdentifiers.first, attachment.hasItemConformingToTypeIdentifier(kUTTypeItem as String) {
							if type == "public.plain-text" || type == "public.url" || attachment.registeredTypeIdentifiers.contains("public.file-url") {
								asyncQueue.async({ (jobDone) in
									if progressViewController?.cancelled == true {
										jobDone()
										return
									}
									// Workaround for saving attachements from Mail.app. Attachments from Mail.app contains two types e.g. "com.adobe.pdf" AND "public.file-url". For loading the file the type "public.file-url" is needed. Otherwise the resource could not be accessed (NSItemProviderSandboxedResource)
									if attachment.registeredTypeIdentifiers.contains("public.file-url") {
										type = "public.file-url"
									}

									attachment.loadItem(forTypeIdentifier: type, options: nil, completionHandler: { (item, error) -> Void in

										if error == nil {
											var data : Data?
											var tempFilePath : String?
											var tempFileURL : URL?

											if let text = item as? String { // Save plain text content
												let ext = self.utiToFileExtension(type)
												tempFilePath = NSTemporaryDirectory() + (attachment.suggestedName ?? "Text".localized) + "." + (ext ?? type)
												data = Data(text.utf8)
											} else if let url = item as? URL { // Download URL content
												if url.isFileURL {
													tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory() + url.lastPathComponent)
													if let tempFileURL = tempFileURL {
														try? FileManager.default.copyItem(at: url, to: tempFileURL)
													}
												} else {
													do {
														tempFilePath = NSTemporaryDirectory() + url.lastPathComponent
														data = try Data(contentsOf: url)
													} catch {
														jobDone()
													}
												}
											}

											if tempFileURL == nil, let data = data, let tempFilePath = tempFilePath {
												FileManager.default.createFile(atPath: tempFilePath, contents:data, attributes:nil)
												tempFileURL = URL(fileURLWithPath: tempFilePath)
											}

											if let tempFileURL = tempFileURL {
												serviceSession.importThroughFileProvider(url: tempFileURL, to: targetDirectory, completion: { (error) in
													try? FileManager.default.removeItem(at: tempFileURL)

													if let error = error {
														Log.error("Error importing item at \(tempFileURL) through file provider: \(String(describing: error))")

														self.showAlert(title: NSString(format: "Error importing %@".localized as NSString, tempFileURL.lastPathComponent) as String, error: error, decisionHandler: { (doContinue) in
															if !doContinue {
																importError = error
																progressViewController?.cancel()
															}

															jobDone()
														})
													} else {
														incrementImportedFile()

														jobDone()
													}
												})
											} else {
												jobDone()
											}
										} else {
											Log.error("Error loading item: \(String(describing: error))")

											self.showAlert(title: "Error loading item".localized, error: error, decisionHandler: { (doContinue) in
												if !doContinue {
													importError = error
													progressViewController?.cancel()
												}

												jobDone()
											})
										}
									})
								})
							} else {
								// Handle local files
								asyncQueue.async({ (jobDone) in
									if progressViewController?.cancelled == true {
										jobDone()
										return
									}

									attachment.loadFileRepresentation(forTypeIdentifier: type) { (url, error) in
										if error == nil, let url = url {
											serviceSession.importThroughFileProvider(url: url, to: targetDirectory, completion: { (error) in
												if let error = error {
													Log.error("Error importing item at \(url.absoluteString) through file provider: \(String(describing: error))")

													self.showAlert(title: NSString(format: "Error importing %@", url.lastPathComponent) as String, error: error, decisionHandler: { (doContinue) in
														if !doContinue {
															importError = error
															progressViewController?.cancel()
														}

														jobDone()
													})
												} else {
													incrementImportedFile()

													jobDone()
												}
											})
										} else if let error = error {
											Log.error("Error loading item: \(String(describing: error))")

											self.showAlert(title: "Error loading item".localized, error: error, decisionHandler: { (doContinue) in
												if !doContinue {
													importError = error
													progressViewController?.cancel()
												}

												jobDone()
											})
										} else {
											jobDone()
										}
									}
								})
							}
						}
					}
				}
			}

			asyncQueue.async({ (jobDone) in
				// Balance previous retainSession() call and allow session to close
				serviceSession.decrementSessionUsage()

				OnMainThread {
					completion(importError ?? ((progressViewController?.cancelled ?? false) ? NSError(ocError: .cancelled) : nil))
					jobDone()
				}
			})
		}
	}
}

extension ShareViewController {
	public func utiToFileExtension(_ utiType: String) -> String? {
		guard let ext = UTTypeCopyPreferredTagWithClass(utiType as CFString, kUTTagClassFilenameExtension) else { return nil }

		return ext.takeRetainedValue() as String
	}
}
