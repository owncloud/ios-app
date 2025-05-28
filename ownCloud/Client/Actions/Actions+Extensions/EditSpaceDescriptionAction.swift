//
//  EditSpaceDescriptionAction.swift
//  ownCloud
//
//  Created by Felix Schwarz on 25.02.25.
//  Copyright © 2025 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2025, ownCloud GmbH.
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

class EditSpaceDescriptionAction: Action {
	override open class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.editspacedescription") }
	override open class var category : ActionCategory? { return .edit }
	override open class var name : String? { return OCLocalizedString("Edit description", nil) }
	override open class var locations : [OCExtensionLocationIdentifier]? { return [.moreFolder, .spaceAction] }

	// MARK: - Extension matching
	override open class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if let core = forContext.core, core.connectionStatus == .online, let drive = forContext.drive, drive.specialType == .space {
			if let shareActions = core.connection.shareActions(for: drive) {
				if shareActions.contains(.updatePermissions) {
					return .last
				}
			}
		}

		return .none
	}

	// MARK: - Action implementation
	override open func run() {
		guard let drive = context.drive, let clientContext = context.clientContext else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		// Retrieve description item
		clientContext.core?.retrieveDrive(drive, itemForResource: .coverDescription, completionHandler: { err, item in
			if let item {
				// Download existing description file
				clientContext.core?.downloadItem(item, resultHandler: { err, core, item, file in
					// Open editor with existing description file
					guard let fileURL = file?.url else {
						return
					}

					var encoding: String.Encoding = .utf8
					if let markdown = try? String(contentsOf: fileURL, usedEncoding: &encoding) {
						OnMainThread {
							self.editDescription(markdown, name: item?.name, existingItem: item)
						}
					}
				})
			} else {
				// Open editor to pen new file
				self.editDescription()
			}
		})
	}

	func editDescription(_ originalMarkdownText: String? = nil, name inFileName: String? = nil, existingItem: OCItem? = nil) {
		let fileName = inFileName ?? "readme.md"

		let markdownViewController = MarkdownViewController(markdownText: originalMarkdownText, title: fileName, allowEditing: true, completionHandler: { canceled, editedMarkdownText in
			if !canceled {
				// Encode Markdown text to UTF-8 data
				guard let clientContext = self.context.clientContext, let markdownData = editedMarkdownText?.data(using: .utf8) else {
					return
				}

				// Write UTF-8 data to temporary file
				var markdownFileURL: NSURL?
				if let eraser = try? clientContext.core?.vault.createTemporaryUploadFile(from: markdownData, name: fileName, url: &markdownFileURL) {
					if markdownFileURL != nil, let drive = self.context.drive {
						// Retrieve space folder
						clientContext.core?.retrieveDrive(drive, itemForResource: .spaceFolder, completionHandler: { err, spaceFolderItem in
							guard let markdownFileURL = markdownFileURL as? URL, let spaceFolderItem, err == nil else {
								eraser()  // erase temporary file+folder
								return
							}

							if let existingItem {
								// Update existing file
								clientContext.core?.reportLocalModification(of: existingItem, parentItem: spaceFolderItem, withContentsOfFileAt: markdownFileURL, isSecurityScoped: false, options: [
									.importByCopying: true
								], placeholderCompletionHandler: nil, resultHandler: { err, core, item, _ in
									if err == nil {
										clientContext.core?.updateDrive(drive, resourceFor: .coverDescription, with: item, completionHandler: nil)
									}
									eraser() // erase temporary file+folder
								})
							} else {
								// Create new file
								clientContext.core?.importFileNamed(markdownFileURL.lastPathComponent, at: spaceFolderItem, from: markdownFileURL, isSecurityScoped: false, options: [
									.importByCopying: true,
									OCCoreOption(rawValue: OCConnectionOptionKey.forceReplaceKey.rawValue) : true // Replace existing file
								], placeholderCompletionHandler: nil, resultHandler: { err, core, item, _ in
									if err == nil {
										clientContext.core?.updateDrive(drive, resourceFor: .coverDescription, with: item, completionHandler: nil)
									}
									eraser() // erase temporary file+folder
								})
							}
						})
					}
				}
			}
		})

		let navigationViewController = ThemeNavigationController(rootViewController: markdownViewController)
		context.clientContext?.present(navigationViewController, animated: true)
	}

	override open class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return UIImage(systemName: "doc.plaintext")?.withRenderingMode(.alwaysTemplate)
	}
}
