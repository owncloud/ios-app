//
//  MediaUploadManager.swift
//  ownCloud
//
//  Created by Michael Neuwert on 31.10.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2019, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit

class MediaUploadManager {
	static let shared = MediaUploadManager()

	var hud: ProgressHUDViewController?
	var importedMediaCount: NSNumber?

	let uploadQueue = MediaUploadQueue()

	deinit {
		NotificationCenter.default.removeObserver(self, name: MediaUploadQueue.AssetImportStarted.name, object: nil)
		NotificationCenter.default.removeObserver(self, name: MediaUploadQueue.AssetImportFinished.name, object: nil)
		NotificationCenter.default.removeObserver(self, name: MediaUploadQueue.AssetImported.name, object: nil)
	}

	func setup() {
		// Subscribe to media upload queue notifications
		NotificationCenter.default.addObserver(self, selector: #selector(handleAssetImportStarted(notification:)), name: MediaUploadQueue.AssetImportStarted.name, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleAssetImportFinished), name: MediaUploadQueue.AssetImportFinished.name, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleSingleAssetImport), name: MediaUploadQueue.AssetImported.name, object: nil)
	}

	private func updateImportMediaHUD() {
		let countText = self.importedMediaCount != nil ? "\(self.importedMediaCount!.intValue)" : ""
		let message = String(format: "Importing %@ media files for upload".localized, countText)
		hud?.updateLabel(with: message)
	}

	@objc func handleAssetImportStarted(notification:Notification) {
		if let window = UIApplication.shared.delegate?.window as? UIWindow {
			if let visibleViewController = window.rootViewController?.topMostViewController {
				self.importedMediaCount = notification.object as? NSNumber
				hud = ProgressHUDViewController(on: visibleViewController, label: nil)
				updateImportMediaHUD()
			}
		}
	}

	@objc func handleSingleAssetImport(notification:Notification) {
		if let count = self.importedMediaCount {
			self.importedMediaCount = NSNumber(value: count.intValue - 1)
			updateImportMediaHUD()
		}
	}

	@objc func handleAssetImportFinished(notification:Notification) {
		hud?.dismiss()
	}

}
