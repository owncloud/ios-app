//
//  OpenInAction.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 12/11/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import ownCloudSDK

class OpenInAction: Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.openin") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String { return "Open in".localized }

	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.items[0].type == .collection {
			return .none
		}
		return .first
	}

	private var interactionController: UIDocumentInteractionController?

	override func run() {
		guard context.items.count > 0, let viewController = context.viewController else {
			completionHandler?(NSError(ocError: .errorInsufficientParameters))
			return
		}

		beforeRunHandler?()

		let item = context.items[0]

		let controller = DownloadFileProgressHUDViewController()

		OnMainThread {
			controller.present(on: viewController) {
				if let progress = self.core.downloadItem(item, options: nil, resultHandler: { (error, _, _, file) in
					if error != nil {
						Log.log("Error \(String(describing: error)) downloading \(String(describing: item.path)) in openIn function")
						self.completionHandler?(error!)
					} else {

						controller.dismiss(animated: true, completion: {
							self.completionHandler?(nil)
							self.interactionController = UIDocumentInteractionController(url: file!.url)
							self.interactionController?.delegate = self
							OnMainThread {
								self.interactionController?.presentOptionsMenu(from: .zero, in: viewController.view, animated: true)
							}
						})
					}
				}) {
					OnMainThread {
						controller.attach(progress: progress)
					}
				}
			}
		}
	}
}

extension OpenInAction: UIDocumentInteractionControllerDelegate {

	func documentInteractionControllerDidDismissOptionsMenu(_ controller: UIDocumentInteractionController) {
		self.interactionController = nil
	}
}
