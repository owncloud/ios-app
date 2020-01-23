//
//  MarkupAction.swift
//  ownCloud
//
//  Created by Matthias Hühne on 21/01/2020.
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

import ownCloudSDK

@available(iOS 13.0, *)
class MarkupAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.markup") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Markup".localized }
	override class var keyCommand : String? { return "E" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command] }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreFolder, .keyboardShortcut] }

	var interactionControllerDispatchGroup : DispatchGroup?
	var interactionController : EditDocumentViewController?

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		let supportedMimeTypes = ["image", "pdf"]
		if forContext.items.contains(where: {$0.type == .collection}) {
			return .none
		} else if forContext.items.count > 1 {
			return .none
		} else if let item = forContext.items.first {
			if let mimeType = item.mimeType {
				if supportedMimeTypes.filter({
					return mimeType.contains($0)
				}).count == 0 {
					return .none
				}
			} else {
				return .none
			}
		}
		// Examine items in context
		return .middle
	}

	// MARK: - Action implementation
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
				if let fileURL = files.first?.url, let item = self.context.items.first {
					// Make sure self is around until interactionControllerDispatchGroup.leave() is called by the documentInteractionControllerDidDismissOptionsMenu delegate method implementation
					self.interactionControllerDispatchGroup = DispatchGroup()
					self.interactionControllerDispatchGroup?.enter()

					self.interactionControllerDispatchGroup?.notify(queue: .main, execute: {
						self.interactionController?.delegate = nil
						self.interactionController = nil
					})

					let editDocumentViewController = EditDocumentViewController(with: fileURL, item: item, core: self.core)
					editDocumentViewController.editDelegte = self
					let navigationController = ThemeNavigationController(rootViewController: editDocumentViewController)
					navigationController.modalPresentationStyle = .overFullScreen
					viewController.present(navigationController, animated: true)
				}
			}
		}

		hudViewController.presentHUDOn(viewController: hostViewController)

		self.completed()
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem || location == .moreFolder {
			if #available(iOS 13.0, *) {
				return UIImage(systemName: "pencil.tip.crop.circle")?.tinted(with: Theme.shared.activeCollection.tintColor)
			} else {
				return UIImage(named: "folder")
			}
		}

		return nil
	}
}

@available(iOS 13.0, *)
extension MarkupAction : EditDocumentViewControllerDelegate {
	func editDocumentViewControllerDidDismiss(_ controller: EditDocumentViewController) {
		interactionControllerDispatchGroup?.leave() // We're done! Trigger notify block and then release last reference to self.
	}
}
