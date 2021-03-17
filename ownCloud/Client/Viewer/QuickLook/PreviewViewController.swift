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
	var showHideBarsTapGestureRecognizer: UITapGestureRecognizer!
	var overlayView = GestureView()

	override var isFullScreenModeEnabled: Bool {
		didSet {
			if isFullScreenModeEnabled {
				overlayView.isHidden = false
			} else {
				overlayView.isHidden = true
			}
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		qlPreviewController = QLPreviewController()
		addChild(qlPreviewController!)
		qlPreviewController!.view.frame = self.view.bounds
		self.view.addSubview(qlPreviewController!.view)
		qlPreviewController!.didMove(toParent: self)
		qlPreviewController?.view.isHidden = true
		qlPreviewController!.view.addSubview(overlayView)
		if #available(iOS 13.0, *) {
			qlPreviewController?.overrideUserInterfaceStyle = Theme.shared.activeCollection.interfaceStyle.userInterfaceStyle
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}

	override func viewSafeAreaInsetsDidChange() {
		super.viewSafeAreaInsetsDidChange()

		if let qlPreviewController = self.qlPreviewController {
			qlPreviewController.view.translatesAutoresizingMaskIntoConstraints = false

			NSLayoutConstraint.activate([
				qlPreviewController.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
				qlPreviewController.view.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
				qlPreviewController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
				qlPreviewController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),

				overlayView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
				overlayView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
				overlayView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
				overlayView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
				])
		}

		self.view.layoutIfNeeded()
	}

	override func renderSpecificView(completion: @escaping (Bool) -> Void) {
		if source != nil {
			if self.qlPreviewController?.dataSource === self {
				// Reload
				self.qlPreviewController?.reloadData()
			} else {
				// First display
				self.showHideBarsTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.showHideBars))
				self.showHideBarsTapGestureRecognizer.delegate = self
				self.showHideBarsTapGestureRecognizer.numberOfTapsRequired = 1
				overlayView.addGestureRecognizer(self.showHideBarsTapGestureRecognizer)

				self.qlPreviewController?.dataSource = self
				self.qlPreviewController?.view.isHidden = false
				supportsFullScreenMode = true
			}

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
		overlayView.isHidden = !navigationController.isNavigationBarHidden

		setNeedsUpdateOfHomeIndicatorAutoHidden()
	}

	// MARK: - QLPreviewControllerDataSource
	func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
		return source != nil ? 1 : 0
	}

	// MARK: - QLPreviewControllerDataSource
	func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
		return source! as QLPreviewItem
	}

	override func canPreviewCurrentItem() -> Bool {
		guard let url = self.source else { return false }
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
