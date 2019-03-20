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
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .toolbar] }

	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.items.contains(where: {$0.type == .collection}) {
			return .none
		}
		return .first
	}

	private var interactionController: UIDocumentInteractionController?
	private var downloadProgressController: DownloadFileProgressHUDViewController?
	private var downloadedFiles: [OCFile] = [OCFile]()
	var downloadError: Error?

	override func run() {
		guard context.items.count > 0, let viewController = context.viewController else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		downloadProgressController = DownloadFileProgressHUDViewController()

		downloadProgressController?.present(on: viewController) { [weak self] in

			let downloadGroup = DispatchGroup()

			if let items = self?.context.items {
				for item in items {
					downloadGroup.enter()
					if let progress = self?.core?.downloadItem(item, options: [ .returnImmediatelyIfOfflineOrUnavailable : true ], resultHandler: { (error, _, _, file) in
						if error != nil {
							Log.log("Error \(String(describing: error)) downloading \(String(describing: item.path)) in openIn function")
							self?.downloadError = error
						} else {
							self?.downloadedFiles.append(file!)
						}
						downloadGroup.leave()
					}) {
						self?.downloadProgressController?.attach(progress: progress)
						self?.publish(progress: progress)
					}

					if self?.downloadError != nil {
						break
					}
				}
			}

			downloadGroup.notify(queue: .main) { [weak self] in
				self?.downloadProgressController?.dismiss(animated: true, completion: {
					if let error = self?.downloadError {
						self?.showDownloadError()
						self?.completed(with: error)
					} else {
						self?.presentSharingViewController()
						self?.completed()
					}
				})
			}
		}
	}

	fileprivate func showDownloadError() {

		guard let viewController = context.viewController else { return }

		let appName = OCAppIdentity.shared.appName ?? "ownCloud"
		let alertController = UIAlertController(with: "Cannot connect to ".localized + appName, message: appName + " couldn't download file(s)".localized, okLabel: "OK".localized, action: nil)
		viewController.present(alertController, animated: true)
	}

	fileprivate func presentSharingViewController() {

		guard downloadedFiles.count > 0, let viewController = context.viewController else { return }

		// UIDocumentInteractionController can deal only with single file
		if self.context.items.count == 1 {
			if let fileURL = self.downloadedFiles.first?.url {
				self.interactionController = UIDocumentInteractionController(url: fileURL)
				self.interactionController?.delegate = self
				self.interactionController?.presentOptionsMenu(from: .zero, in: viewController.view, animated: true)
			}

		} else {
			// TODO: Handle multiple files with a fallback solution
		}
	}
}

extension OpenInAction: UIDocumentInteractionControllerDelegate {

	func documentInteractionControllerDidDismissOptionsMenu(_ controller: UIDocumentInteractionController) {
		self.interactionController = nil
	}
}
