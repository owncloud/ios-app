//
//  ImportFilesController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 10.07.19.
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
import ownCloudSDK
import ownCloudApp
import ownCloudAppShared

extension Array where Element: Equatable {
    mutating func remove(object: Element) {
		guard let index = firstIndex(of: object) else { return }
        remove(at: index)
    }

}

struct ImportFile: Equatable {
	var url: URL
	var fileIsLocalCopy: Bool
}

class ImportFilesController: NSObject {

	// MARK: - Instance variables

	static var shared = ImportFilesController()
	//var url: URL?
	var localCopyContainerURL: URL?
	var localCopyURL: URL?
	//var fileIsLocalCopy: Bool
	var importFiles: [ImportFile] = []
	var isVisible: Bool = false

	var fileCoordinator : NSFileCoordinator?

	public func importAllowed(alertUserOtherwise: Bool) -> Bool {
		let importAllowed = Branding.shared.isImportMethodAllowed(.openWith)

		if !importAllowed, alertUserOtherwise {
			// Open with disabled, alert user
			OnMainThread {
				let alertController = ThemedAlertController(title: OCLocalizedString("Opening not allowed", nil), message: OCLocalizedString("Importing files through opening is not allowed on this device.", nil), preferredStyle: .alert)
				alertController.addAction(UIAlertAction(title: OCLocalizedString("OK", nil), style: .default, handler: nil))

				UserInterfaceContext.shared.currentViewControllerForPresenting?.present(alertController, animated: true, completion: nil)
			}
		}

		return importAllowed
	}

	public func importFile(_ importFile: ImportFile) {
		if self.importAllowed(alertUserOtherwise: true) {
			// Import file
			importFiles.append(importFile)

			prepareInputFileForImport(file: importFile, completion: { (error) in
				guard error == nil else {
					Log.error("Couldn't import file \(importFile.url.absoluteString) because of error: \(String(describing: error))")

					return
				}

				self.showAccountUI()
			})
		}
	}

	// MARK: - User Interface
	var locationPicker: ClientLocationPicker?

	func showAccountUI() {
		let headerTitle = importFiles.count == 1 ?
		OCLocalizedFormat("Import \"{{itemName}}\"", ["itemName" : "\(importFiles.first!.url.lastPathComponent)"]) :
		OCLocalizedFormat("Import {{itemCount}} files", ["itemCount" : "\(importFiles.count)"])
		let headerSubTitle = OCLocalizedString("Select target.", nil) /* importFiles.count == 1 ?
			fileNames.joined(separator: ", ") */

		if !isVisible {
			// Create new picker
			isVisible = true

			OnMainThread {
				self.locationPicker = ClientLocationPicker(location: .accounts, selectButtonTitle: OCLocalizedString("Save here", nil), headerTitle: headerTitle, headerSubTitle: headerSubTitle, avoidConflictsWith: nil, choiceHandler: { [weak self] (chosenItem, location, _, cancelled) in
					self?.handlePickerDecision(parentItem: chosenItem, location: location, cancelled: cancelled)
				})

				if let window = UserInterfaceContext.shared.currentWindow {
					let viewController = window.rootViewController
					var presentationViewController: UIViewController? = viewController

					if let navigationController = viewController as? UINavigationController, let viewController = navigationController.visibleViewController {
						presentationViewController = viewController
					}

					self.locationPicker?.present(in: ClientContext(originatingViewController: presentationViewController))
				}
			}
		} else {
			// Update existing picker
			locationPicker?.headerTitle = headerTitle
			locationPicker?.headerSubTitle = headerSubTitle
		}
	}

	func handlePickerDecision(parentItem: OCItem?, location: OCLocation?, cancelled: Bool) {
		isVisible = false
		locationPicker = nil

		if cancelled {
			// Remove all local copies of files queued for import
			for importFile in importFiles {
				removeLocalCopy(importFile: importFile)
			}

			importFiles = []
		}

		if !cancelled, let targetDirectory = parentItem, let bookmarkUUID = location?.bookmarkUUID, let bookmark = OCBookmarkManager.shared.bookmark(for: bookmarkUUID) {
			// Schedule uploads
			let waitGroup = DispatchGroup()

			OCCoreManager.shared.requestCore(for: bookmark, setup: nil, completionHandler: { core, error in
				OnMainThread {
					for importFile in self.importFiles {
						let name = importFile.url.lastPathComponent

						waitGroup.enter()
						if core?.importItemNamed(name,
									 at: targetDirectory,
									 from: importFile.url,
									 isSecurityScoped: false,
									 options: [OCCoreOption.importByCopying : true,
										   OCCoreOption.automaticConflictResolutionNameStyle : OCCoreDuplicateNameStyle.bracketed.rawValue],
									 placeholderCompletionHandler: { (error, item) in
										if error != nil {
											Log.debug("Error uploading \(Log.mask(name)) to \(Log.mask(targetDirectory.path)), error: \(error?.localizedDescription ?? "" )")
										}

										waitGroup.leave()
									 },
									 resultHandler: { (error, _ core, _ item, _) in
										if error != nil {
											Log.debug("Error uploading \(Log.mask(name)) to \(Log.mask(targetDirectory.path)), error: \(error?.localizedDescription ?? "" )")
										} else {
											Log.debug("Success uploading \(Log.mask(name)) to \(Log.mask(targetDirectory.path))")

											self.removeLocalCopy(importFile: importFile)
										}
									}
						) == nil {
							Log.debug("Error setting up upload of \(Log.mask(name)) to \(Log.mask(targetDirectory.path))")
						}
					}
				}

				waitGroup.notify(queue: .main, execute: {
					OnBackgroundQueue(after: 2) {
						// Return OCCore after 2 seconds, giving the core a chance to schedule the uploads with a NSURLSession
						OCCoreManager.shared.returnCore(for: bookmark, completionHandler: {

						})
					}
				})
			})
		}
	}

	// MARK: - File import
	func prepareInputFileForImport(file: ImportFile, completion: @escaping (_ error: Error?) -> Void) {
		let securityScopedURL = file.url
		var isAccessingSecurityScopedResource = false

		if !file.fileIsLocalCopy {
			isAccessingSecurityScopedResource = securityScopedURL.startAccessingSecurityScopedResource()
		}

		let uploadIntent = NSFileAccessIntent.readingIntent(with: file.url, options: .forUploading)

		fileCoordinator = NSFileCoordinator(filePresenter: nil)
		fileCoordinator?.coordinate(with: [uploadIntent], queue: OperationQueue.main, byAccessor: { (error) in
			let readURL = uploadIntent.url

			Log.log("Read from \(readURL)")

			self.makeLocalCopy(of: readURL, completion: { (error) in
				if isAccessingSecurityScopedResource {
					securityScopedURL.stopAccessingSecurityScopedResource()
				}

				completion(error)
			})
		})
	}

	func makeLocalCopy(of itemURL: URL, completion: (_ error: Error?) -> Void) {
		if let appGroupURL = OCAppIdentity.shared.appGroupContainerURL {
			let fileManager = FileManager.default

			var inboxURL = appGroupURL.appendingPathComponent("File-Import")
			if !fileManager.fileExists(atPath: inboxURL.path) {
				do {
					try fileManager.createDirectory(at: inboxURL, withIntermediateDirectories: false, attributes: [ .protectionKey : FileProtectionType.completeUntilFirstUserAuthentication])
				} catch let error as NSError {
					Log.debug("Error creating directory \(inboxURL) \(error.localizedDescription)")

					completion(error)
					return
				}
			}

			let uuid = UUID().uuidString
			inboxURL = inboxURL.appendingPathComponent(uuid)
			if !fileManager.fileExists(atPath: inboxURL.path) {
				do {
					try fileManager.createDirectory(at: inboxURL, withIntermediateDirectories: false, attributes: [ .protectionKey : FileProtectionType.completeUntilFirstUserAuthentication])
				} catch let error as NSError {
					Log.debug("Error creating directory \(inboxURL) \(error.localizedDescription)")

					completion(error)
					return
				}
			}
			self.localCopyContainerURL = inboxURL

			inboxURL = inboxURL.appendingPathComponent(itemURL.lastPathComponent)
			do {
				try fileManager.copyItem(at: itemURL, to: inboxURL)
				//self.url = inboxURL
				self.localCopyURL = inboxURL
				//self.fileIsLocalCopy = true
			} catch let error as NSError {
				Log.debug("Error copying file \(inboxURL) \(error.localizedDescription)")

				completion(error)
				return
			}
		}

		completion(nil)
	}

	func removeLocalCopy(importFile: ImportFile) {
		if importFile.fileIsLocalCopy {
			let fileManager = FileManager.default

			if fileManager.fileExists(atPath: importFile.url.path) {
				do {
					try fileManager.removeItem(at: importFile.url)
				} catch {
				}
			}

			if let localCopyContainerURL = localCopyContainerURL {
				if fileManager.fileExists(atPath: importFile.url.path) {
					do {
						try fileManager.removeItem(at: localCopyContainerURL)
					} catch {
					}
				}
			}
		}
		importFiles.remove(object: importFile)
	}

	// MARK: - Cleanup on startup
	class func removeImportDirectory() {
		if let appGroupURL = OCAppIdentity.shared.appGroupContainerURL {
			let fileManager = FileManager.default
			let inboxUrl = URL(fileURLWithPath: appGroupURL.appendingPathComponent("File-Import").path)

			if fileManager.fileExists(atPath: inboxUrl.path) {
				do {
					try fileManager.removeItem(at: inboxUrl)
				} catch {

				}
			}
		}
	}
}
