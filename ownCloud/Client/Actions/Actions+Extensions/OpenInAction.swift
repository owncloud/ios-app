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
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem] }

	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.items.contains(where: {$0.type == .collection}) {
			return .none
		}

		if forContext.items.count > 1 {
 			return .none
 		}
		return .first
	}

	private var interactionController: UIDocumentInteractionController?

	override func run() {
		guard context.items.count > 0, let viewController = context.viewController else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let item = context.items[0]

		let controller = DownloadFileProgressHUDViewController()

		controller.present(on: viewController) {
			if let progress = self.core?.downloadItem(item, options: [ .returnImmediatelyIfOfflineOrUnavailable : true ], resultHandler: { (error, _, _, file) in
				if error != nil {
					Log.log("Error \(String(describing: error)) downloading \(String(describing: item.path)) in openIn function")

					self.completionHandler = { error in

						let appName = OCAppIdentity.shared.appName ?? "ownCloud"
						let alertController = UIAlertController(with: "Cannot connect to ".localized + appName, message: appName + " couldn't download this file".localized, okLabel: "OK".localized, action: nil)
						viewController.present(alertController, animated: true)
					}

					controller.dismiss(animated: true, completion: {
						self.completed(with: error)
					})
				} else {
					OnMainThread {
						controller.dismiss(animated: true, completion: {
							if let fileURL = file?.url {
								self.interactionController = UIDocumentInteractionController(url: fileURL)
								self.interactionController?.delegate = self
								self.interactionController?.presentOptionsMenu(from: .zero, in: viewController.view, animated: true)
							}
						})
					}
				}
			}) {
				controller.attach(progress: progress)
				self.publish(progress: progress)
			}
		}
	}
}

extension OpenInAction: UIDocumentInteractionControllerDelegate {

	func documentInteractionControllerDidDismissOptionsMenu(_ controller: UIDocumentInteractionController) {
		self.interactionController = nil
	}
}
