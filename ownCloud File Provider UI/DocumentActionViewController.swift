//
//  DocumentActionViewController.swift
//  ownCloud File Provider UI
//
//  Created by Matthias Hühne on 28.01.21.
//  Copyright © 2021 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2021, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit
import FileProviderUI
import ownCloudApp
import ownCloudAppShared
import ownCloudSDK

class DocumentActionViewController: FPUIActionExtensionViewController {

	private var coreConnectionStatusObservation : NSKeyValueObservation?
	weak var core: OCCore?
	var themeNavigationController : ThemeNavigationController?

	enum ActionExtensionType {
		case undefined, sharing
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		ThemeStyle.registerDefaultStyles()

		// Initially apply theme based on light / dark mode
		ThemeStyle.considerAppearanceUpdate()

		self.cssSelector = .modal

		CollectionViewCellProvider.registerStandardImplementations()
		CollectionViewSupplementaryCellProvider.registerStandardImplementations()

		OCCoreManager.shared.memoryConfiguration = .minimum // Limit memory usage
		OCHTTPPipelineManager.setupPersistentPipelines() // Set up HTTP pipelines

		OCItem.registerIcons()
	}

	func complete(cancelWith error: Error? = nil) {
		let complete = {
			if let error = error {
				self.extensionContext.cancelRequest(withError: error)
			} else {
				self.extensionContext.completeRequest()
			}
		}

		coreConnectionStatusObservation?.invalidate()
		coreConnectionStatusObservation = nil

		if let bookmark = core?.bookmark {
			OCCoreManager.shared.returnCore(for: bookmark, completionHandler: {
				complete()
			})
		} else {
			complete()
		}
	}

	func prepareNavigationController() {
		if themeNavigationController == nil {
			themeNavigationController = ThemeNavigationController()
			if let themeNavigationController = themeNavigationController {
				view.addSubview(themeNavigationController.view)
				addChild(themeNavigationController)
			}
		}
	}

	override func prepare(forAction actionIdentifier: String, itemIdentifiers: [NSFileProviderItemIdentifier]) {
		guard let vfsIdentifier = itemIdentifiers.first else {
			complete(cancelWith: NSError(domain: FPUIErrorDomain, code: Int(FPUIExtensionErrorCode.userCancelled.rawValue), userInfo: nil))
			return
		}

		var identifier: NSFileProviderItemIdentifier?

		if let vaultLocation = OCVaultLocation(vfsItemID: OCVFSItemID(rawValue: vfsIdentifier.rawValue)), let localID = vaultLocation.localID {
			identifier = NSFileProviderItemIdentifier(rawValue: localID)
		} else {
			identifier = vfsIdentifier
		}

		guard let identifier else {
			complete(cancelWith: NSError(domain: FPUIErrorDomain, code: Int(FPUIExtensionErrorCode.userCancelled.rawValue), userInfo: nil))
			return
		}

		let collection = Theme.shared.activeCollection
		view.backgroundColor = collection.css.getColor(.fill, selectors: [.toolbar], for: view)

		prepareNavigationController()

		showCancelLabel(with: "Connecting…".localized)

		var actionTypeLabel = ""
		var actionExtensionType : ActionExtensionType = .undefined
		if actionIdentifier == "com.owncloud.FileProviderUI.Share" {
			actionExtensionType = .sharing
			actionTypeLabel = "Share".localized
		}

		OCCoreManager.shared.requestCoreForBookmarkWithItem(withLocalID: identifier.rawValue, setup: nil) { [weak self] (error, core, databaseItem) in
			guard let self = self else {
				// DocumentActionViewController vanished - and .complete() with it - return core immediately
				if let bookmark = core?.bookmark {
					OCCoreManager.shared.returnCore(for: bookmark, completionHandler: nil)
				}
				return
			}

			if let error = error {
				self.complete(cancelWith: error)
			} else {
				self.core = core
				guard let item = databaseItem else { return }
				guard let core = self.core else { return }
				var triedConnecting = false

				core.vault.resourceManager?.add(ResourceSourceItemIcons(core: core))

				self.coreConnectionStatusObservation = core.observe(\OCCore.connectionStatus, options: [.initial, .new]) { [weak self] (_, _) in
					guard let self = self else { return }

					OnMainThread {
						if actionExtensionType == .sharing, core.connection.capabilities?.sharingAPIEnabled == false || item.isShareable == false {
							self.showCancelLabel(with: String(format: "%@ is not available for this item.".localized, actionTypeLabel))
						} else if core.connectionStatus == .online {
							self.coreConnectionStatusObservation?.invalidate()
							self.coreConnectionStatusObservation = nil

							if actionExtensionType == .sharing {
								let clientContext = ClientContext(core: core)

								let sharingViewController = SharingViewController(clientContext: clientContext, item: item)
								sharingViewController.navigationItem.navigationContent.add(items: [
									NavigationContentItem(identifier: "done", area: .right, priority: .standard, position: .trailing, items: [
										UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.dismissView))
									])
								])
								self.themeNavigationController?.viewControllers = [sharingViewController]
							}
						} else if core.connectionStatus == .connecting {
							triedConnecting = true
							self.showCancelLabel(with: "Connecting…".localized)
						} else if core.connectionStatus == .offline || core.connectionStatus == .unavailable {
							// Display error if `.connecting` isn't reached within 2 seconds
							OnMainThread(after: 2) {
								if !triedConnecting {
									self.showCancelLabel(with: String(format: "%@ is not available, when this account is offline. Please open the app and log into your account before you can do this action.".localized, actionTypeLabel))
								}
							}

							// Display error if `.connecting` has already been reached
							if triedConnecting {
								self.showCancelLabel(with: String(format: "%@ is not available, when this account is offline. Please open the app and log into your account before you can do this action.".localized, actionTypeLabel))
							}
						}
					}
				}
			}
		}
	}

	override func prepare(forError error: Error) {
		if !OCFileProviderSettings.browseable {
			prepareNavigationController()
			showCancelLabel(with: "File Provider access has been disabled by the administrator.\n\nPlease use the app to access your files.".localized)
			return
		}

		if AppLockManager.supportedOnDevice {
			AppLockManager.shared.passwordViewHostViewController = self
			AppLockManager.shared.biometricCancelLabel = "Cancel".localized
			AppLockManager.shared.cancelAction = { [weak self] in
				self?.complete(cancelWith: NSError(domain: FPUIErrorDomain, code: Int(FPUIExtensionErrorCode.userCancelled.rawValue), userInfo: nil))
			}
			AppLockManager.shared.successAction = { [weak self] in
				self?.complete()
			}

			AppLockManager.shared.showLockscreenIfNeeded()
		} else {
			prepareNavigationController()
			showCancelLabel(with: "Passcode protection is not supported on this device.\nPlease disable passcode lock in the app settings.".localized)
		}
	}

	func showCancelLabel(with message: String) {
		OnMainThread {
			if let currentController = self.themeNavigationController?.viewControllers.first as? CancelLabelViewController {
				currentController.updateCancelLabels(with: message)
			} else if let cancelLabelViewController = UIStoryboard.init(name: "MainInterface", bundle: nil).instantiateViewController(withIdentifier: "CancelLabelViewController") as? CancelLabelViewController {
				cancelLabelViewController.updateCancelLabels(with: message)
				cancelLabelViewController.cancelAction = { [weak self] in
					self?.complete(cancelWith: NSError(domain: FPUIErrorDomain, code: Int(FPUIExtensionErrorCode.userCancelled.rawValue), userInfo: nil))
				}
				self.themeNavigationController?.viewControllers = [ cancelLabelViewController ]
			}
		}
	}

	@objc func dismissView() {
		self.dismiss(animated: true) {
			self.complete()
		}
	}
}
