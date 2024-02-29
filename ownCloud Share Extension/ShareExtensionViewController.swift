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

@objc(ShareExtensionViewController)
class ShareExtensionViewController: EmbeddingViewController, Themeable {
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
		OCCoreManager.shared.memoryConfiguration = .minimum // Limit memory usage
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
		let locationPicker = ClientLocationPicker(location: .accounts, selectButtonTitle: "Save here".localized, avoidConflictsWith: nil, choiceHandler: { [weak self] folderItem, folderLocation, _, cancelled in
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

	func importTo(selectedFolder: OCItem?, location: OCLocation?) {
		if let targetFolder = selectedFolder, let bookmarkUUID = targetFolder.bookmarkUUID {
			if let bookmark = OCBookmarkManager.shared.bookmark(forUUIDString: bookmarkUUID) {
				let vault = OCVault(bookmark: bookmark)
				self.fpServiceSession = OCFileProviderServiceSession(vault: vault)

				OnMainThread {
					let progressViewController = ProgressIndicatorViewController(initialProgressLabel: "Preparing…".localized, progress: nil, cancelHandler: {})

					self.contentViewController = progressViewController

					AccountConnectionPool.shared.disconnectAll {
						OnMainThread {
							if let fpServiceSession = self.fpServiceSession {
								self.importFiles(to: targetFolder, serviceSession: fpServiceSession, progressViewController: progressViewController, completion: { [weak self] (error) in
									OnMainThread {
										if let error = error {
											self?.extensionContext?.cancelRequest(withError: error)
										} else {
											self?.extensionContext?.completeRequest(returningItems: [])
										}
									}
								})
							}
						}
					}
				}
			}
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

						if var type = attachment.registeredTypeIdentifiers.first, attachment.hasItemConformingToTypeIdentifier(UTType.item.identifier) {
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
												let ext = UTType(type)?.preferredFilenameExtension
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
												serviceSession.importThroughFileProvider(url: tempFileURL, to: targetDirectory, completion: { (error, _) in
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
											serviceSession.importThroughFileProvider(url: url, to: targetDirectory, completion: { (error, _) in
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

	// MARK: - Events
	var willAppearDidInitialRun: Bool = false
	private var _registered = false
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		// Register for theme
		if !_registered {
			_registered = true
			Theme.shared.register(client: self, applyImmediately: true)
		}

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
					showErrorMessage(title: "Share Extension disabled".localized, message: "Importing files through the Share Extension is not allowed on this device.".localized)
					return
				}

				if !OCVault.hostHasFileProvider {
					// No file provider -> share extension unavailable
					showErrorMessage(title: "Share Extension unavailable".localized, message: "The {{app.name}} share extension is not available on this system.".localized)
					return
				}

				if OCBookmarkManager.shared.bookmarks.count == 0 {
					// No account configured
					showErrorMessage(title: "No account configured".localized, message: "Setup a new account in the app to save to.".localized)
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
			.button("OK".localized, action: UIAction(handler: { [weak self] action in
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

	// MARK: - Actions
	func completed() {
		AppLockManager.shared.appDidEnterBackground()

		AccountConnectionPool.shared.disconnectAll {
			self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
		}
	}

	func cancel() {
		AppLockManager.shared.appDidEnterBackground()

		AccountConnectionPool.shared.disconnectAll {
			self.extensionContext?.cancelRequest(withError: NSError(domain: NSErrorDomain.ShareErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Canceled by user"]))
		}
	}

	// MARK: - Themeable
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
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

extension UserInterfaceContext : UserInterfaceContextProvider {
	public func provideRootView() -> UIView? {
		return ShareExtensionViewController.shared?.view
	}

	public func provideCurrentWindow() -> UIWindow? {
		return ShareExtensionViewController.shared?.view.window
	}
}
