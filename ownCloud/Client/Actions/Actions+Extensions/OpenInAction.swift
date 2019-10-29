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

		let hudViewController = DownloadItemsHUDViewController(core: core, downloadItems: context.items) { [weak hostViewController] (error, files) in
			if let error = error {
				if (error as NSError).isOCError(withCode: .cancelled) {
					return
				}

				let appName = OCAppIdentity.shared.appName ?? "ownCloud"
				let alertController = ThemedAlertController(with: "Cannot connect to ".localized + appName, message: appName + " couldn't download file(s)".localized, okLabel: "OK".localized, action: nil)

				hostViewController?.present(alertController, animated: true)
			} else {
				guard let files = files, files.count > 0, let viewController = hostViewController else { return }

				// UIDocumentInteractionController can only be used with a single file
				if files.count == 1 {
					if let fileURL = files.first?.url {
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
						self.interactionController?.presentOptionsMenu(from: .zero, in: viewController.view, animated: true)
					}
				} else {
					// Handle multiple files with a fallback solution
					let urls = files.map { (file) -> URL in
						return file.url!
					}
					let activityController = UIActivityViewController(activityItems: urls, applicationActivities: nil)

					if UIDevice.current.isIpad() {
						activityController.popoverPresentationController?.sourceView = viewController.view
					}

					viewController.present(activityController, animated: true, completion: nil)
				}
			}
		}

		hudViewController.presentHUDOn(viewController: hostViewController)

		self.completed()
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem {
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
