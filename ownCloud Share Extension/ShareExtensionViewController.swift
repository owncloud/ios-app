//
//  ShareExtensionViewController.swift
//  ownCloud Share Extension
//
//  Created by Felix Schwarz on 07.12.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import UniformTypeIdentifiers
import ownCloudSDK
import ownCloudApp
import ownCloudAppShared

extension NSErrorDomain {
	static let ShareErrorDomain = "ShareErrorDomain"
}

private let unitCountForImport: Int64 = 50
private let unitCountForUpload: Int64 = 100

@objc(ShareExtensionViewController)
class ShareExtensionViewController: EmbeddingViewController {
	// MARK: - Initialization
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

		ThemeStyle.registerDefaultStyles()
		ShareExtensionViewController.shared = self
		self.cssSelector = .modal

		CollectionViewCellProvider.registerStandardImplementations()
		CollectionViewSupplementaryCellProvider.registerStandardImplementations()
	}

	@available(*, unavailable)
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	// MARK: - Entry point
	override func viewDidLoad() {
		super.viewDidLoad()

		// Setup
		setupServices()
	}

	private static var _servicesHaveBeenSetup = false
	func setupServices() {
		// Make sure to setup services only once
		if ShareExtensionViewController._servicesHaveBeenSetup {
			return
		}
		ShareExtensionViewController._servicesHaveBeenSetup = true

		// Setup services
		OCHTTPPipelineManager.setupPersistentPipelines() // Set up HTTP pipelines

		if AppLockManager.supportedOnDevice {
			AppLockManager.shared.passwordViewHostViewController = self
			AppLockManager.shared.cancelAction = { [weak self] in
				self?.cancel()
			}
		}

		OCExtensionManager.shared.addExtension(CreateFolderAction.actionExtension)
		OCItem.registerIcons()
	}

	func showLocationPicker() {
		let locationPicker = ClientLocationPicker(location: .accounts, selectButtonTitle: OCLocalizedString("Save here", nil), avoidConflictsWith: nil, choiceHandler: { [weak self] folderItem, folderLocation, _, cancelled in
			if cancelled {
				self?.cancel()
				return
			}

			self?.importTo(selectedFolder: folderItem, location: folderLocation)
		})

		contentViewController = locationPicker.pickerViewControllerForPresentation()
	}

	// MARK: - Import
	var fpServiceSession : OCFileProviderServiceSession?
	var asyncQueue : OCAsyncSequentialQueue = OCAsyncSequentialQueue()

	var progressViewController: ProgressIndicatorViewController?
	var uploadCoreProgress: Progress?

	func importTo(selectedFolder: OCItem?, location: OCLocation?) {
		if let targetFolder = selectedFolder, let bookmarkUUID = targetFolder.bookmarkUUID ?? location?.bookmarkUUID?.uuidString {
			if let bookmark = OCBookmarkManager.shared.bookmark(forUUIDString: bookmarkUUID) {
				OnMainThread {
					self.progressViewController = ProgressIndicatorViewController(initialProgressLabel: OCLocalizedString("Preparing…", nil), progress: nil, cancelHandler: { [weak self] in
						self?.uploadCoreProgress?.cancel() // Cancel transfers (!) via Progress instances provided by upload methods
						self?.cancel()
					})
					self.contentViewController = self.progressViewController

					let importCompletionHandler : ((_ error: Error?) -> Void) = { [weak self] (error) in
						self?.finish(with: error)
					}

					if let accountConnection = AccountConnectionPool.shared.connection(for: bookmark) {
						// Account found - connect (just in case it's not)
						accountConnection.connect { error in
							if let error {
								// Error connecting
								Log.error("Share Extension could not connect: \(String(describing: error))")
								self.finish(with: error)
							} else if let core = accountConnection.core {
								// Import files
								OnMainThread {
									self.importFiles(to: targetFolder, core: core, completion: importCompletionHandler)
								}
							} else {
								// Error retrieving core for connection after connect (should never happen)
								Log.error("Share Extension could not retrieve core for connection")
								self.finish(with: NSError(ocError: .internal))
							}
						}
					} else {
						// Account not found - this should not be possible
						self.finish(with: NSError(ocError: .internal))
					}
				}
			}
		}
	}

	func importFiles(to targetDirectory : OCItem, core: OCCore, completion: @escaping (_ error: Error?) -> Void) {
		if let inputItems : [NSExtensionItem] = self.extensionContext?.inputItems as? [NSExtensionItem] {
			var totalItems : Int64 = 0
			var importedItems : Int64 = 0
			var uploadedItems : Int64 = 0
			var importProgress: Progress
			var uploadProgress: Progress
			var totalProgress: Progress
			var uploadError: Error?
			let uploadWaitGroup: DispatchGroup = DispatchGroup()

			for item : NSExtensionItem in inputItems {
				if let attachments = item.attachments {
					totalItems += Int64(attachments.count)
				}
			}

			importProgress = Progress(totalUnitCount: totalItems)
			uploadProgress = Progress(totalUnitCount: totalItems)
			totalProgress = Progress(totalUnitCount: (unitCountForImport + unitCountForUpload) * totalItems)
			totalProgress.addChild(importProgress, withPendingUnitCount: unitCountForImport * totalItems)
			totalProgress.addChild(uploadProgress, withPendingUnitCount: unitCountForUpload * totalItems)
			self.progressViewController?.progress = totalProgress

			uploadCoreProgress = Progress(totalUnitCount: totalItems)

			let incrementImportCounter = {
				// Increment progress
				importedItems += 1

				OnMainThread {
					importProgress.completedUnitCount = importedItems
					totalProgress.localizedDescription = NSString(format: OCLocalizedString("Importing item %ld of %ld", nil) as NSString, importedItems, totalItems) as String
					// self.progressViewController?.update(text: NSString(format: "Importing item %ld of %ld".localized as NSString, importedItems, totalItems) as String)
				}
			}

			let updateUploadMessage = {
				OnMainThread {
					if importedItems == totalItems {
						totalProgress.localizedDescription = OCLocalizedFormat("Uploading {{remainingFileCount}} files…", ["remainingFileCount" : "\(totalItems - uploadedItems)"])
					}
				}
			}

			let handleUploadResult: (_ error: Error?) -> Void = { (error) in
				if let error {
					uploadError = error
				}
				uploadProgress.completedUnitCount += 1
				uploadedItems += 1
				updateUploadMessage()
				uploadWaitGroup.leave()
			}

			for item : NSExtensionItem in inputItems {
				if let attachments = item.attachments {
					for attachment in attachments {
						if progressViewController?.cancelled == true {
							break
						}

						if var type = attachment.registeredTypeIdentifiers.first, attachment.hasItemConformingToTypeIdentifier(UTType.item.identifier) {
							if type == "public.plain-text" || type == "public.url" || attachment.registeredTypeIdentifiers.contains("public.file-url") ||
							   type == "public.image" {
								asyncQueue.async({ (jobDone) in
									if self.progressViewController?.cancelled == true {
										jobDone()
										return
									}

									incrementImportCounter()

									// Workaround for saving attachements from Mail.app. Attachments from Mail.app contains two types e.g. "com.adobe.pdf" AND "public.file-url". For loading the file the type "public.file-url" is needed. Otherwise the resource could not be accessed (NSItemProviderSandboxedResource)
									if attachment.registeredTypeIdentifiers.contains("public.file-url") {
										type = "public.file-url"
									}

									let suggestedTextFileName = attachment.suggestedName ?? OCLocalizedString("Text", nil)

									attachment.loadItem(forTypeIdentifier: type, options: nil, completionHandler: { (item, error) in
										if error == nil {
											var data : Data?
											var tempFilePath : String?
											var tempFileURL : URL?

											if let text = item as? String { // Save plain text content
												let ext = UTType(type)?.preferredFilenameExtension
												tempFilePath = NSTemporaryDirectory() + suggestedTextFileName + "." + (ext ?? type)
												data = Data(text.utf8)
											} else if let url = item as? URL { // Download URL content
												if url.isFileURL {
													tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory() + url.lastPathComponent)
													if let tempFileURL {
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
											} else if let image = item as? UIImage { // Encode image as PNG
												let ext = "png"
												tempFilePath = NSTemporaryDirectory() + suggestedTextFileName + "." + ext
												data = image.pngData()
											}

											if tempFileURL == nil, let data, let tempFilePath {
												FileManager.default.createFile(atPath: tempFilePath, contents:data, attributes:nil)
												tempFileURL = URL(fileURLWithPath: tempFilePath)
											}

											if let tempFileURL {
												uploadWaitGroup.enter()

												if let coreProgress = self.uploadFile(from: tempFileURL, removeAfterImport: true, to: targetDirectory, via: core, schedulingDoneBlock: jobDone, completionHandler: handleUploadResult) {
													self.uploadCoreProgress?.addChild(coreProgress, withPendingUnitCount: 1)
												}
											} else {
												jobDone()
											}
										} else if let error {
											Log.error("Error loading item: \(String(describing: error))")

											self.showAlert(title: OCLocalizedString("Error loading item", nil), error: error, decisionHandler: { [weak self] (doContinue) in
												if !doContinue {
													self?.cancel()
												}

												jobDone()
											})
										} else {
											jobDone()
										}
									})
								})
							} else {
								// Handle local files
								asyncQueue.async({ (jobDone) in
									if self.progressViewController?.cancelled == true {
										jobDone()
										return
									}

									incrementImportCounter()

									attachment.loadFileRepresentation(forTypeIdentifier: type) { (url, error) in
										if error == nil, let url {
											uploadWaitGroup.enter()

											if let coreProgress = self.uploadFile(from: url, removeAfterImport: false, to: targetDirectory, via: core, schedulingDoneBlock: jobDone, completionHandler: handleUploadResult) {
												self.uploadCoreProgress?.addChild(coreProgress, withPendingUnitCount: 1)
											}
										} else if let error {
											Log.error("Error loading item: \(String(describing: error))")

											self.showAlert(title: OCLocalizedString("Error loading item", nil), error: error, decisionHandler: { [weak self] (doContinue) in
												if !doContinue {
													self?.cancel()
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
				OnMainThread {
					updateUploadMessage()
				}

				uploadWaitGroup.notify(queue: .main, execute: {
					self.finish(with: ((self.progressViewController?.cancelled ?? false) ? NSError(ocError: .cancelled) : uploadError))
					jobDone()
				})
			})
		}
	}

	func uploadFile(from sourceURL: URL, removeAfterImport: Bool, to targetItem: OCItem, via core: OCCore, schedulingDoneBlock: @escaping os_block_t, completionHandler: @escaping (Error?) -> Void) -> Progress? {
		let progress = core.importItemNamed(sourceURL.lastPathComponent, at: targetItem, from: sourceURL, isSecurityScoped: false, options: [
			.importByCopying : true,
			.automaticConflictResolutionNameStyle : OCCoreDuplicateNameStyle.bracketed.rawValue
		], placeholderCompletionHandler: { [weak self] error, placeholderItem in
			if removeAfterImport {
				try? FileManager.default.removeItem(at: sourceURL)
			}

			if let error {
				Log.error("Error importing item at \(sourceURL) through share extension: \(String(describing: error))")

				self?.showAlert(title: NSString(format: OCLocalizedString("Error importing %@", nil) as NSString, sourceURL.lastPathComponent) as String, error: error, decisionHandler: { [weak self] (doContinue) in
					if !doContinue {
						completionHandler(error)
						self?.progressViewController?.cancel()
					}

					schedulingDoneBlock()
				})
			} else {
				schedulingDoneBlock()
			}
		}, resultHandler: { error, core, item, parameter in
			completionHandler(error)
			schedulingDoneBlock()
		})

		return progress
	}

	// MARK: - Events
	var willAppearDidInitialRun: Bool = false
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		// Check permission
		if Branding.shared.isImportMethodAllowed(.shareExtension) {
			// Share extension allowed
			if !willAppearDidInitialRun {
				willAppearDidInitialRun = true

				if AppLockManager.supportedOnDevice {
					AppLockManager.shared.showLockscreenIfNeeded()
				}

				// Check for show stoppers
				if !Branding.shared.isImportMethodAllowed(.shareExtension) {
					// Share extension disabled, alert user
					showErrorMessage(title: OCLocalizedString("Share Extension disabled", nil), message: OCLocalizedString("Importing files through the Share Extension is not allowed on this device.", nil))
					return
				}

				if !OCVault.hostHasFileProvider {
					// No file provider -> share extension unavailable
					showErrorMessage(title: OCLocalizedString("Share Extension unavailable", nil), message: OCLocalizedString("The {{app.name}} share extension is not available on this system.", nil))
					return
				}

				if OCBookmarkManager.shared.bookmarks.count == 0 {
					// No account configured
					showErrorMessage(title: OCLocalizedString("No account configured", nil), message: OCLocalizedString("Setup a new account in the app to save to.", nil))
					return
				}

				// Show location picker
				showLocationPicker()
			}

			// Log in to first account if there's only one
			let bookmarks = OCBookmarkManager.shared.bookmarks

			if bookmarks.count == 1, let onlyBookmark = bookmarks.first {
				AccountConnectionPool.shared.connection(for: onlyBookmark)?.connect()
			}
		}
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		AppLockManager.shared.appDidEnterBackground()
	}

	// MARK: - Error message view
	var messageView: UIView? {
		didSet {
			if let messageView {
				let viewController = UIViewController()

				messageView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
				messageView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
				messageView.widthAnchor.constraint(greaterThanOrEqualToConstant: 320).isActive = true

				viewController.view.embed(centered: messageView)

				contentViewController = viewController
			}
		}
	}

	func showErrorMessage(title: String, message: String) {
		let errorMessageView = ComposedMessageView(elements: [
			.title(title, alignment: .centered),
			.spacing(5),
			.subtitle(message, alignment: .centered),
			.spacing(15),
			.button(OCLocalizedString("OK", nil), action: UIAction(handler: { [weak self] action in
				self?.cancel()
			}))
		])

		messageView = errorMessageView
	}

	// MARK: - Alert view
	func showAlert(title: String?, message: String? = nil, error: Error? = nil, decisionHandler: @escaping ((_ continue: Bool) -> Void)) {
		OnMainThread {
			let message = message ?? ((error != nil) ? error?.localizedDescription : nil)
			let alert = ThemedAlertController(title: title, message: message, preferredStyle: .alert)

			alert.addAction(UIAlertAction(title: OCLocalizedString("Cancel", nil), style: .cancel, handler: { (_) in
				decisionHandler(false)
			}))

			if let nsError = error as NSError?, nsError.domain == NSCocoaErrorDomain, nsError.code == NSXPCConnectionInvalid || nsError.code == NSXPCConnectionInterrupted {
				Log.error("XPC connection error: \(String(describing: error))")
			} else {
				alert.addAction(UIAlertAction(title: OCLocalizedString("Continue", nil), style: .default, handler: { (_) in
					decisionHandler(true)
				}))
			}

			(self.presentedViewController ?? self).present(alert, animated: true, completion: nil)
		}
	}

	// MARK: - Actions
	func cancel() {
		finish(with: NSError(domain: NSErrorDomain.ShareErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Canceled by user"]))
	}

	private var _isFinished: Bool = false
	func finish(with error: Error?) {
		var alreadyFinished: Bool = false

		OCSynchronized(self) {
			alreadyFinished = _isFinished
			_isFinished = true
		}

		if alreadyFinished {
			// Already finished
			Log.error("Share Extension already finished. Attempt to finish again with \(String(describing: error))")
			return
		}

		OnMainThread {
			AppLockManager.shared.appDidEnterBackground()

			AccountConnectionPool.shared.disconnectAll { [weak self] in
				if let error {
					self?.extensionContext?.cancelRequest(withError: error)
				} else {
					self?.extensionContext?.completeRequest(returningItems: [])
				}
			}
		}
	}

	// MARK: - Themeable
	override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		super.applyThemeCollection(theme: theme, collection: collection, event: event)
		view.backgroundColor = collection.css.getColor(.fill, for: view)
	}

	// MARK: - UserInterfaceContext glue
	public static weak var shared: ShareExtensionViewController? {
		didSet {
			ThemeStyle.considerAppearanceUpdate()
		}
	}

	// MARK: - Theme change detection
	public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)

		if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
			ThemeStyle.considerAppearanceUpdate()
		}
	}

	// MARK: - Host App Bundle ID
	override func willMove(toParent parent: UIViewController?) {
		super.willMove(toParent: parent)

		OCAppIdentity.shared.hostAppBundleIdentifier = parent?.oc_hostAppBundleIdentifier

		Log.debug("Extension Host App Bundle ID: \(OCAppIdentity.shared.hostAppBundleIdentifier ?? "nil")")
	}
}

extension UserInterfaceContext : ownCloudAppShared.UserInterfaceContextProvider {
	public func provideRootView() -> UIView? {
		return ShareExtensionViewController.shared?.view
	}

	public func provideCurrentWindow() -> UIWindow? {
		return ShareExtensionViewController.shared?.view.window
	}
}
