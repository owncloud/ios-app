//
//  OCBookmarkManager+Management.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 22.11.22.
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
import ownCloudSDK

public extension OCBookmarkManager {
	func delete(withAlertOn hostViewController: UIViewController, bookmark: OCBookmark, completion: (() -> Void)? = nil) {
		var presentationStyle: UIAlertController.Style = .actionSheet
		if UIDevice.current.isIpad {
			presentationStyle = .alert
		}

		var alertTitle = OCLocalizedString("Really delete '%@'?", nil)
		var destructiveTitle = OCLocalizedString("Delete", nil)
		var failureTitle = OCLocalizedString("Deletion of '%@' failed", nil)
		if VendorServices.shared.isBranded {
			alertTitle = OCLocalizedString("Do you want to log out from '%@'?", nil)
			destructiveTitle = OCLocalizedString("Log out", nil)
			failureTitle = OCLocalizedString("Log out of '%@' failed", nil)
		}

		let alertController = ThemedAlertController(title: NSString(format: alertTitle as NSString, bookmark.shortName) as String,
													message: OCLocalizedString("This will also delete all locally stored file copies.", nil),
													preferredStyle: presentationStyle)

		alertController.addAction(UIAlertAction(title: OCLocalizedString("Cancel", nil), style: .cancel, handler: { _ in
			completion?()
		}))

		alertController.addAction(UIAlertAction(title: destructiveTitle, style: .destructive, handler: { (_) in
			if !OCBookmarkManager.attemptLock(bookmark: bookmark, presentErrorOn: hostViewController, action: { bookmark, lockActionCompletion in
				OCCoreManager.shared.scheduleOfflineOperation({ (bookmark, offlineOperationCompletion) in
					let vault : OCVault = OCVault(bookmark: bookmark)

					vault.erase(completionHandler: { (_, error) in
						OnMainThread {
							if error != nil {
								// Inform user if vault couldn't be erased
								let alertController = ThemedAlertController(title: NSString(format: failureTitle as NSString, bookmark.shortName as NSString) as String,
																			message: error?.localizedDescription,
																			preferredStyle: .alert)

								alertController.addAction(UIAlertAction(title: OCLocalizedString("OK", nil), style: .default, handler: nil))

								hostViewController.present(alertController, animated: true)
							} else {
								// Success! We can now remove the bookmark
								OCMessageQueue.global.dequeueAllMessages(forBookmarkUUID: bookmark.uuid)

								if let bookmark = OCBookmarkManager.shared.bookmark(for: bookmark.uuid) {
									OCBookmarkManager.shared.removeBookmark(bookmark)
								}
							}

							completion?() // delete(withAlertOn:) completion Handler
							offlineOperationCompletion() // OCCoreManager.scheduleOfflineOperation completion handler
							lockActionCompletion() // OCBookmarkManager.attemptLock completion handler
						}
					})
				}, for: bookmark)
			}) {
				completion?()
			}
		}))

		hostViewController.present(alertController, animated: true, completion: nil)
	}
}
