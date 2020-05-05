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

class OpenInAction: Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.openin") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String { return "Open in".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .toolbar, .keyboardShortcut] }
	override class var keyCommand : String? { return "O" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command] }

	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.items.contains(where: {$0.type == .collection}) {
			return .none
		}
		return .first
	}

	var interactionControllerDispatchGroup : DispatchGroup?
	var interactionController : UIDocumentInteractionController?

	override func run() {
		guard context.items.count > 0, let hostViewController = context.viewController, let core = self.core else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let hudViewController = DownloadItemsHUDViewController(core: core, downloadItems: context.items) { [weak hostViewController] (error, downloadedItems) in
			if let error = error {
				if (error as NSError).isOCError(withCode: .cancelled) {
					return
				}

				let appName = OCAppIdentity.shared.appName ?? "ownCloud"
				let alertController = ThemedAlertController(with: "Cannot connect to ".localized + appName, message: appName + " couldn't download file(s)".localized, okLabel: "OK".localized, action: nil)

				hostViewController?.present(alertController, animated: true)
			} else {
				guard let downloadedItems = downloadedItems, downloadedItems.count > 0, let viewController = hostViewController else { return }
				// UIDocumentInteractionController can only be used with a single file
				if downloadedItems.count == 1 {
					if let fileURL = downloadedItems.first?.file.url {
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

						if let sender = self.context.sender as? UITabBarController {
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
					let urls = downloadedItems.map { (item) -> URL in
						return item.file.url!
					}
					let activityController = UIActivityViewController(activityItems: urls, applicationActivities: nil)

					if UIDevice.current.isIpad() {
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
		if location == .moreItem || location == .moreFolder {
			return UIImage(named: "open-in")
		}

		return nil
	}
}

extension OpenInAction : UIDocumentInteractionControllerDelegate {
	func documentInteractionControllerDidDismissOptionsMenu(_ controller: UIDocumentInteractionController) {
		interactionControllerDispatchGroup?.leave() // We're done! Trigger notify block and then release last reference to self.
	}
}
