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
	var header : MoreViewHeader?

	// MARK: - Init & Deinit

	override init() {
		//self.url = url
		//importFiles?.append(url)
		//fileIsLocalCopy = copyBeforeUsing
	}
	/*
	init(url: URL, copyBeforeUsing: Bool) {
		self.url = url
		//importFiles?.append(url)
		fileIsLocalCopy = copyBeforeUsing
	}*/

	deinit {
		//removeLocalCopy()
	}

}

extension ImportFilesController {

	public func importFile(_ importFile: ImportFile) {
		importFiles.append(importFile)

		prepareInputFileForImport(file: importFile, completion: { (error) in
			guard error == nil else {
				Log.error("Couldn't import file \(importFile.url.absoluteString) because of error: \(String(describing: error))")

				return
			}

			self.showAccountUI()
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

	func showAccountUI() {
		if !isVisible {
			let bookmarks : [OCBookmark] = OCBookmarkManager.shared.bookmarks as [OCBookmark]
			if bookmarks.count > 0, let url = importFiles.first?.url {
				let moreViewController = self.cardViewController(for: self.localCopyURL ?? url)
				if let window = UserInterfaceContext.shared.currentWindow, let moreViewController = moreViewController {
					let viewController = window.rootViewController
					if let navigationController = viewController as? UINavigationController, let viewController = navigationController.visibleViewController {
						OnMainThread {
							self.isVisible = true
							viewController.present(asCard: moreViewController, animated: true)
						}
					} else {
						OnMainThread {
							self.isVisible = true
							viewController?.present(asCard: moreViewController, animated: true)
						}
					}
				}
			}
		} else {

			let fileNames = importFiles.map { (importFile) -> String in
				return importFile.url.lastPathComponent
			}

			header?.updateHeader(title: "\(importFiles.count) Files", subtitle: fileNames.joined(separator: ", "))
		}
	}

	func importItemsWithDirectoryPicker(into bookmark: OCBookmark) {
		OCCoreManager.shared.requestCore(for: bookmark, setup: { (_, _) in
		}, completionHandler: { (core, error) in
			if let core = core, error == nil {
				OnMainThread { [weak core] in
					let waitGroup = DispatchGroup()
					let directoryPickerViewController = ClientDirectoryPickerViewController(core: core!, path: "/", selectButtonTitle: "Save here".localized, avoidConflictsWith: [], choiceHandler: { (selectedDirectory, _) in
						if let targetDirectory = selectedDirectory {
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

							waitGroup.notify(queue: .main, execute: {
								OnBackgroundQueue(after: 2) {
									// Return OCCore after 2 seconds, giving the core a chance to schedule the uploads with a NSURLSession
									OCCoreManager.shared.returnCore(for: bookmark, completionHandler: {

									})
								}
							})
							self.isVisible = false
						}
					})

					let pickerNavigationController = ThemeNavigationController(rootViewController: directoryPickerViewController)
					pickerNavigationController.modalPresentationStyle = .formSheet

					if let window = UserInterfaceContext.shared.currentWindow {
						let viewController = window.rootViewController
						if let navCon = viewController as? UINavigationController, let viewController = navCon.visibleViewController {
							viewController.present(pickerNavigationController, animated: true)
						} else {
							viewController?.present(pickerNavigationController, animated: true)
						}
					}
				}
			}
		})
	}

	func cardViewController(for url: URL) -> FrameViewController? {
		let tableViewController = MoreStaticTableViewController(style: .grouped)
		header = MoreViewHeader(url: url)
		guard let header = header else { return nil }

		let moreViewController = FrameViewController(header: header, viewController: tableViewController)

		let title = NSAttributedString(string: "Save File".localized, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .heavy)])

		var actionsRows: [StaticTableViewRow] = []
		let bookmarks : [OCBookmark] = OCBookmarkManager.shared.bookmarks as [OCBookmark]

		let rowDescription = StaticTableViewRow(label: "Choose an account and folder to import the file into.\n\nOnly one file can be imported at once.".localized, alignment: .center)
		actionsRows.append(rowDescription)

		for (bookmark) in bookmarks {
			let row = StaticTableViewRow(buttonWithAction: { (_ row, _ sender) in
				moreViewController.dismiss(animated: true, completion: {
					self.importItemsWithDirectoryPicker(into: bookmark)
				})
				}, title: bookmark.shortName, style: .plain, image: Theme.shared.image(for: "owncloud-logo", size: CGSize(width: 25, height: 25)), imageWidth: 25, alignment: .left)
			actionsRows.append(row)
		}

		let row = StaticTableViewRow(buttonWithAction: { (_ row, _ sender) in
			self.isVisible = false
			moreViewController.dismiss(animated: true, completion: nil)
		}, title: "Cancel".localized, style: .destructive, alignment: .center)
		actionsRows.append(row)

		tableViewController.addSection(MoreStaticTableViewSection(headerAttributedTitle: title, identifier: "actions-section", rows: actionsRows))

		return moreViewController
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
