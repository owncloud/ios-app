//
//  OpenInAction.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 12/11/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2018, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import ownCloudSDK
import ownCloudAppShared

class OpenInAction: Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.openin") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String { return "Open in".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .toolbar, .keyboardShortcut, .contextMenuItem] }
	override class var keyCommand : String? { return "O" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command] }

	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.items.contains(where: {$0.type == .collection}) {
			return .none
		}
		return .nearFirst
	}

	var interactionControllerDispatchGroup : DispatchGroup?
	var interactionController : UIDocumentInteractionController?

	var temporaryExportURL : URL?

	override func run() {
		guard context.items.count > 0, let hostViewController = context.viewController, let core = self.core else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let hudViewController = DownloadItemsHUDViewController(core: core, downloadItems: context.items) { [weak hostViewController] (error, files) in
			if let error = error {
				if (error as NSError).isOCError(withCode: .cancelled) {
					return
				}

				let appName = VendorServices.shared.appName
				let alertController = ThemedAlertController(with: "Cannot connect to ".localized + appName, message: appName + " couldn't download file(s)".localized, okLabel: "OK".localized, action: nil)

				hostViewController?.present(alertController, animated: true)
			} else {
				guard let files = files, files.count > 0, let viewController = hostViewController else { return }

				// Create clones of the files with the item's name (which can differ from the file name on disk while a move or rename action is in progress)
				guard let temporaryExportFolderURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("export-\(UUID().uuidString)", isDirectory: true) else { return }

				var exportURLs : [URL] = []

				do {
					try FileManager.default.createDirectory(at: temporaryExportFolderURL, withIntermediateDirectories: true, attributes: [
						.protectionKey : FileProtectionType.completeUntilFirstUserAuthentication
					])

					for file in files {
						if let fileURL = file.url, let fileName = file.item?.name {
							let temporaryItemSubFolderURL = temporaryExportFolderURL.appendingPathComponent("\(UUID().uuidString)", isDirectory: true)
							let temporaryItemURL = temporaryItemSubFolderURL.appendingPathComponent(fileName)

							try FileManager.default.createDirectory(at: temporaryItemSubFolderURL, withIntermediateDirectories: true, attributes: [
								.protectionKey : FileProtectionType.completeUntilFirstUserAuthentication
							])

							try FileManager.default.copyItem(at: fileURL, to: temporaryItemURL)

							exportURLs.append(temporaryItemURL)
						}
					}

					Log.debug("Exporting \(exportURLs)")
				} catch {
					Log.error("Error preparing export for \(files) to temporary location \(temporaryExportFolderURL): \(error.localizedDescription)")
					try? FileManager.default.removeItem(at: temporaryExportFolderURL)
					return
				}

				// Store reference to temporary export root URL for later deletion
				self.temporaryExportURL = temporaryExportFolderURL

				// UIDocumentInteractionController can only be used with a single file
				if exportURLs.count == 1 {
					if let fileURL = exportURLs.first {
						// Make sure self is around until interactionControllerDispatchGroup.leave() is called by the documentInteractionControllerDidDismissOptionsMenu delegate method implementation
						self.interactionControllerDispatchGroup = DispatchGroup()
						self.interactionControllerDispatchGroup?.enter()

						self.interactionControllerDispatchGroup?.notify(queue: .main, execute: {
							self.interactionController?.delegate = nil
							self.interactionController = nil
						})

						// Present UIDocumentInteractionController
						self.interactionController = UIDocumentInteractionController(url: fileURL)
						self.interactionController?.delegate = self

						if let _ = self.context.sender as? UIKeyCommand, let hostViewController = hostViewController {
							var sourceRect = hostViewController.view.frame
							sourceRect.origin.x = viewController.view.center.x
							sourceRect.origin.y = viewController.navigationController?.navigationBar.frame.size.height ?? 0.0
							sourceRect.size.width = 0.0
							sourceRect.size.height = 0.0

							self.interactionController?.presentOptionsMenu(from: sourceRect, in: hostViewController.view, animated: true)
						} else if let sender = self.context.sender as? UITabBarController {
							var sourceRect = sender.view.frame
							sourceRect.origin.y = viewController.view.frame.size.height
							sourceRect.size.width = 0.0
							sourceRect.size.height = 0.0

							self.interactionController?.presentOptionsMenu(from: sourceRect, in: sender.view, animated: true)
						} else if let barButtonItem = self.context.sender as? UIBarButtonItem {
							self.interactionController?.presentOptionsMenu(from: barButtonItem, animated: true)
						} else if let cell = self.context.sender as? UITableViewCell, let clientQueryViewController = viewController as? ClientQueryViewController {
							if let indexPath = clientQueryViewController.tableView.indexPath(for: cell) {
								let cellRect = clientQueryViewController.tableView.rectForRow(at: indexPath)
								self.interactionController?.presentOptionsMenu(from: cellRect, in: clientQueryViewController.tableView, animated: true)
							}
						} else {
							self.interactionController?.presentOptionsMenu(from: viewController.view.frame, in: viewController.view, animated: true)
						}
					}
				} else {
					// Handle multiple files with a fallback solution
					let activityController = UIActivityViewController(activityItems: exportURLs, applicationActivities: nil)
					activityController.completionWithItemsHandler = { (_, _, _, _) in
						// Remove temporary export root URL with contents
						try? FileManager.default.removeItem(at: temporaryExportFolderURL)
					}

					if UIDevice.current.isIpad {
						if let sender = self.context.sender as? UITabBarController {
							var sourceRect = sender.view.frame
							sourceRect.origin.y = viewController.view.frame.size.height
							sourceRect.size.width = 0.0
							sourceRect.size.height = 0.0

							activityController.popoverPresentationController?.sourceView = sender.view
							activityController.popoverPresentationController?.sourceRect = sourceRect
						} else {
							activityController.popoverPresentationController?.sourceView = viewController.view
							activityController.popoverPresentationController?.sourceRect = viewController.view.frame
						}
					}

					viewController.present(activityController, animated: true, completion: nil)
				}
			}
		}

		hudViewController.presentHUDOn(viewController: hostViewController)

		self.completed()
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem || location == .moreFolder || location == .contextMenuItem {
			if #available(iOS 13.0, *) {
				return UIImage(systemName: "square.and.arrow.up")?.withRenderingMode(.alwaysTemplate)
			}

			return UIImage(named: "open-in")
		}

		return nil
	}
}

extension OpenInAction : UIDocumentInteractionControllerDelegate {
	func documentInteractionControllerDidDismissOptionsMenu(_ controller: UIDocumentInteractionController) {
		if let temporaryExportURL = temporaryExportURL {
			DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
				// Remove temporary export root URL with contents
				// (wait 2 seconds since documentation is not clear about whether the file still needs to be around after this call)
				try? FileManager.default.removeItem(at: temporaryExportURL)
			})
		}

		self.interactionControllerDispatchGroup?.leave() // We're done! Trigger notify block and then release last reference to self.
	}
}
