//
//  PreviewViewController.swift
//  ownCloud
//
//  Created by Michael Neuwert on 27.08.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
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

import UIKit
import ownCloudSDK
import QuickLook
import ownCloudAppShared

class GestureView : UIView {

	override init(frame: CGRect) {
		super.init(frame: .zero)

		self.translatesAutoresizingMaskIntoConstraints = false
		self.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.01)
		self.isHidden = true
	}

	required init(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class PreviewViewController : DisplayViewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate {

	private var qlPreviewController: QLPreviewController?
	var overlayView : GestureView?

	override var isFullScreenModeEnabled: Bool {
		didSet {
			overlayView?.isHidden = !isFullScreenModeEnabled
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		supportsFullScreenMode = true
	}

	override func renderItem(completion: @escaping (Bool) -> Void) {
		if itemDirectURL != nil {
			let previousPreviewController = qlPreviewController

			if let previousPreviewController = previousPreviewController {
				qlPreviewController = nil

				previousPreviewController.view.removeFromSuperview()
				previousPreviewController.dataSource = nil
				previousPreviewController.removeFromParent()
			}

			overlayView = GestureView()
			overlayView?.isHidden = !isFullScreenModeEnabled

			qlPreviewController = QLPreviewController()
			qlPreviewController?.dataSource = self
			view.addSubview(qlPreviewController!.view)
			addChild(qlPreviewController!)

			qlPreviewController!.view.frame = view.bounds
			qlPreviewController!.view.addSubview(overlayView!)
			qlPreviewController!.didMove(toParent: self)

			if #available(iOS 13.0, *) {
				qlPreviewController?.overrideUserInterfaceStyle = Theme.shared.activeCollection.interfaceStyle.userInterfaceStyle
			}

			qlPreviewController!.view.translatesAutoresizingMaskIntoConstraints = false

			NSLayoutConstraint.activate([
				qlPreviewController!.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
				qlPreviewController!.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
				qlPreviewController!.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
				qlPreviewController!.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

				overlayView!.topAnchor.constraint(equalTo: view.topAnchor),
				overlayView!.bottomAnchor.constraint(equalTo: view.bottomAnchor),
				overlayView!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
				overlayView!.trailingAnchor.constraint(equalTo: view.trailingAnchor)
			])

			let showHideBarsTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.showHideBars))
			showHideBarsTapGestureRecognizer.delegate = self
			showHideBarsTapGestureRecognizer.numberOfTapsRequired = 1
			overlayView!.addGestureRecognizer(showHideBarsTapGestureRecognizer)

			completion(true)
		} else {
			completion(false)
		}
	}

	@objc func showHideBars() {
		guard let navigationController = navigationController else {
			return
		}

		if !navigationController.isNavigationBarHidden {
			navigationController.setNavigationBarHidden(true, animated: true)
		} else {
			navigationController.setNavigationBarHidden(false, animated: true)
		}
		overlayView?.isHidden = !navigationController.isNavigationBarHidden

		setNeedsUpdateOfHomeIndicatorAutoHidden()
	}

	// MARK: - QLPreviewControllerDataSource
	func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
		return itemDirectURL != nil ? 1 : 0
	}

	// MARK: - QLPreviewControllerDataSource
	func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
		return itemDirectURL! as QLPreviewItem
	}

	override var canPreviewCurrentItem: Bool {
		guard let url = self.itemDirectURL else { return false }
		return QLPreviewController.canPreview(url as QLPreviewItem)
	}

	// MARK: - Themeable implementation
	override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		super.applyThemeCollection(theme: theme, collection: collection, event: event)

		if #available(iOS 13, *) {
			qlPreviewController?.overrideUserInterfaceStyle = collection.interfaceStyle.userInterfaceStyle
		}
	}
}

// MARK: - GestureRecognizer delegate
extension PreviewViewController: UIGestureRecognizerDelegate {
}

// MARK: - Display Extension.
extension PreviewViewController: DisplayExtension {
	private static let supportedFormatsRegex = try? NSRegularExpression(pattern: "\\A((text/)|(image/svg)|(model/(vnd|usd))|(application/(rtf|x-rtf|doc))|(application/x-iwork*)|(application/(vnd.|ms))(?!(oasis|android))(ms|openxmlformats)?)", options: .caseInsensitive)

	static var customMatcher: OCExtensionCustomContextMatcher? = { (context, defaultPriority) in

		guard let regex = supportedFormatsRegex else { return .noMatch }

		if let mimeType = context.location?.identifier?.rawValue {

			let matches = regex.numberOfMatches(in: mimeType, options: .reportCompletion, range: NSRange(location: 0, length: mimeType.count))

			if matches > 0 {
				return .locationMatch
			}
		}

		return .noMatch
	}

	static var supportedMimeTypes: [String]?
	static var displayExtensionIdentifier: String = "org.owncloud.ql_preview"
	static var features: [String : Any]? = [FeatureKeys.canEdit : false]
}
