//
//  ShareNavigationController.swift
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

@objc(ShareNavigationController)
class ShareNavigationController: AppExtensionNavigationController {

	override func viewDidLoad() {
		super.viewDidLoad()

		AppLockManager.shared.passwordViewHostViewController = self
		AppLockManager.shared.cancelAction = { [weak self] in
			self?.extensionContext?.cancelRequest(withError: NSError(domain: NSErrorDomain.ShareViewErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Canceled by user"]))
		}

		OCExtensionManager.shared.addExtension(CreateFolderAction.actionExtension)
		OCItem.registerIcons()
	}

	override func setupViewControllers() {
		OCBookmarkManager.shared.loadBookmarks()

		let bookmarks : [OCBookmark] = OCBookmarkManager.shared.bookmarks as [OCBookmark]
		if bookmarks.count == 0 || bookmarks.count > 1 {
			self.setViewControllers([ShareViewController(style: .grouped)], animated: false)
		} else if bookmarks.count == 1, let bookmark = bookmarks.first {
			OCCoreManager.shared.requestCore(for: bookmark, setup: nil, completionHandler: { (core, error) in
				if let core = core, error == nil {
					let directoryPickerViewController = ShareViewClientDirectoryPickerViewController(core: core, bookmark: bookmark, path: "/", selectButtonTitle: "Save here".localized, avoidConflictsWith: [], appearedInitial: true, choiceHandler: { (selectedDirectory, controller) in
						if let targetDirectory = selectedDirectory {
							controller.importFiles(to: targetDirectory, bookmark: bookmark, core: core)
						}
					})
					OnMainThread {
						self.setViewControllers([directoryPickerViewController], animated: false)
					}
				}
			})
		}
	}
}

extension UserInterfaceContext : UserInterfaceContextProvider {
	public func provideRootView() -> UIView? {
		return AppExtensionNavigationController.mainNavigationController?.view
	}

	public func provideCurrentWindow() -> UIWindow? {
		return AppExtensionNavigationController.mainNavigationController?.view.window
	}
}
