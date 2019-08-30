//
//  PreviewViewController.swift
//  ownCloud
//
//  Created by Michael Neuwert on 27.08.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK
import QuickLook

class PreviewViewController : DisplayViewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate {

	private var qlPreviewController: QLPreviewController?

	override func viewSafeAreaInsetsDidChange() {
		super.viewSafeAreaInsetsDidChange()

		if let qlPreviewController = self.qlPreviewController {
			qlPreviewController.view.translatesAutoresizingMaskIntoConstraints = false

			NSLayoutConstraint.activate([
				qlPreviewController.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
				qlPreviewController.view.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
				qlPreviewController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
				qlPreviewController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
				])
		}

		self.view.layoutIfNeeded()
	}

	override func renderSpecificView(completion: @escaping (Bool) -> Void) {
		if source != nil {
			qlPreviewController = QLPreviewController()
			addChild(qlPreviewController!)
			qlPreviewController!.view.frame = self.view.bounds
			self.view.addSubview(qlPreviewController!.view)
			qlPreviewController!.didMove(toParent: self)

			qlPreviewController?.dataSource = self

			qlPreviewController?.reloadData()

			completion(true)
		} else {
			completion(false)
		}
	}

	// MARK: - QLPreviewControllerDataSource
	func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
		return source != nil ? 1 : 0
	}

	// MARK: - QLPreviewControllerDelegate
	func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
		return source! as QLPreviewItem
	}

	@available(iOS 13.0, *)
	func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
		// Return .updateContents so QLPreviewController takes care of updating the contents of the provided QLPreviewItems whenever users save changes.
		return .updateContents
	}
}

// MARK: - Display Extension.
extension PreviewViewController: DisplayExtension {
	static var supportedMimeTypes: [String]? {
		return ["application/pdf", "image/jpeg", "application/vnd.apple.keynote", "application/x-iwork-pages-sffpages", "application/x-iwork-numbers-sffnumbers", "application/x-iwork-keynote-sffkey"]
	}

	static var customMatcher: OCExtensionCustomContextMatcher?
	static var displayExtensionIdentifier: String = "org.owncloud.ql_preview"
	static var features: [String : Any]? = [FeatureKeys.canEdit : false]
}
