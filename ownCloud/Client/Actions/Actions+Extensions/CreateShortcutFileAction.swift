//
//  CreateShortcutFileAction.swift
//  ownCloud
//
//  Created by Felix Schwarz on 10.04.24.
//  Copyright © 2024 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2024, ownCloud GmbH.
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

class CreateShortcutFileAction: Action {
	override open class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.createShortcutFile") }
	override open class var category : ActionCategory? { return .normal }
	override open class var name : String? { return "Create shortcut".localized }
	override open class var locations : [OCExtensionLocationIdentifier]? { return [.folderAction, .emptyFolder] }

	// MARK: - Extension matching
	override open class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.items.count > 1 {
			return .none
		}

		if forContext.items.first?.type != .collection {
			return .none
		}

		if forContext.items.first?.permissions.contains(.createFile) == false {
			return .none
		}

		return .middle
	}

	// MARK: - Action implementation
	override open func run() {
		guard context.items.count > 0 else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		OnMainThread {
			let createURLPrompt = UIAlertController(title: "Create shortcut".localized, message: nil, preferredStyle: .alert)

			createURLPrompt.addTextField(configurationHandler: { textField in
				textField.placeholder = "Name of the shortcut".localized
			})

			createURLPrompt.addTextField(configurationHandler: { textField in
				textField.placeholder = "Target URL of shortcut".localized
			})

			createURLPrompt.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
			createURLPrompt.addAction(UIAlertAction(title: "Create".localized, style: .default, handler: { [weak self, weak createURLPrompt] action in
				let name = createURLPrompt?.textFields?.first?.text
				var urlString = createURLPrompt?.textFields?.last?.text

				if let urlStringIn = urlString,
				   urlStringIn.lowercased().hasPrefix("http://") == false,
				   urlStringIn.lowercased().hasPrefix("https://") == false {
				   	urlString = "https://".appending(urlStringIn)
				}

				if let name, let urlString, let url = URL(string: urlString) {
					self?.createURLShortcut(name: name, url: url)
				}
			}))

			self.context.clientContext?.present(createURLPrompt, animated: true)
		}
	}

	func createURLShortcut(name: String, url: URL) {
		guard context.items.count > 0 else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		let item = context.items.first

		guard item != nil, let itemLocation = item?.location else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		guard let core = self.core, let parentItem = try? core.cachedItem(at: itemLocation) else {
			self.completed()
			return
		}

		if let urlFileData = INIFile.URLFile(with: url).data {
			if let temporaryFolderURL = core.vault.temporaryDownloadURL?.appendingPathComponent(UUID().uuidString) {
				let temporaryFileURL = temporaryFolderURL.appendingPathComponent("\(name).url")

				try? FileManager.default.createDirectory(at: temporaryFolderURL, withIntermediateDirectories: true)
				try? urlFileData.write(to: temporaryFileURL)

				core.importFileNamed("\(name).url", at: parentItem, from: temporaryFileURL, isSecurityScoped: false, placeholderCompletionHandler: { [weak self] error, item in
					try? FileManager.default.removeItem(at: temporaryFileURL)
					try? FileManager.default.removeItem(at: temporaryFolderURL)

					self?.completed(with: error)
				})
			} else {
				completed(with: NSError(ocError: .itemInsufficientPermissions))
			}
		} else {
			completed(with: NSError(ocError: .itemInsufficientPermissions))
		}
	}

	override open class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return UIImage(systemName: "arrow.up.forward.square")?.withRenderingMode(.alwaysTemplate)
	}
}
