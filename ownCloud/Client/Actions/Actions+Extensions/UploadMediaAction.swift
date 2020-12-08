//
//  UploadMediaAction.swift
//  ownCloud
//
//  Created by Felix Schwarz on 09.04.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
*/

import UIKit
import ownCloudSDK
import ownCloudAppShared
import Photos
import PhotosUI

@available(iOS 14, *)
class PhotoPickerPresenter: PHPickerViewControllerDelegate {

	typealias AssetSelectionHandler = ([PHAsset]) -> Void

	var completionHandler: AssetSelectionHandler?
	var parentViewController: UIViewController?

	var pickerViewController: UIViewController {
		var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
		configuration.preferredAssetRepresentationMode = .automatic
		configuration.selectionLimit = 0
		let pickerViewController = PHPickerViewController(configuration: configuration)
		pickerViewController.delegate = self

		return pickerViewController
	}

	func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {

		picker.dismiss(animated: true)

		OnBackgroundQueue {

			var assets = [PHAsset]()

			// Get asset identifiers
			var identifiers = [String]()
			for result in results {
				if let identifier = result.assetIdentifier {
					identifiers.append(identifier)
				}
			}

			// Fetch corresponding assets
			let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
			fetchResult.enumerateObjects({ (asset, _, _) in
				assets.append(asset)
			})

			OnMainThread {
				self.completionHandler?(assets)
			}
		}
	}

	func present(in viewController:UIViewController, with completion:@escaping AssetSelectionHandler) {
		self.parentViewController = viewController
		self.completionHandler = completion
		viewController.present(self.pickerViewController, animated: true)
	}
}

class UploadMediaAction: UploadBaseAction {

	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.uploadphotos") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String { return "Upload from your photo library".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.folderAction, .keyboardShortcut] }
	override class var keyCommand : String? { return "M" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command] }

	// We need this to keep PhotoPickerPresenter alive in iOS14. Type is 'Any' since it is iOS14 only and you can't add @available() to stored properties
	private var picker: Any?

	private struct AssociatedKeys {
		static var actionKey = "action"
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count == 1, context.items.first?.type == .collection, let viewController = context.viewController else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		PHPhotoLibrary.requestAccess { (granted) in
			if granted {
				self.presentImageGalleryPicker()
			} else {
				let alert = UIAlertController.alertControllerForPhotoLibraryAuthorizationInSettings()
				viewController.present(alert, animated: true)
				self.completed()
			}
		}
	}

	private func presentImageGalleryPicker() {

		func addAssetsToQueue(assets:[PHAsset]) {
			guard let path = self.context.items.first?.path else { return }
			guard let bookmark = self.core?.bookmark else { return }

			MediaUploadQueue.shared.addUploads(assets, for: bookmark, at: path)
		}

		if let viewController = self.context.viewController {

			if #available(iOS 14, *) {
				picker = PhotoPickerPresenter()
				(picker as? PhotoPickerPresenter)?.present(in: viewController, with: { [weak self] (assets) in
					self?.completed()
					addAssetsToQueue(assets: assets)
					self?.picker = nil
				})
			} else {
				let photoAlbumViewController = PhotoAlbumTableViewController()
				photoAlbumViewController.selectionCallback = {(assets) in
					self.completed()
					addAssetsToQueue(assets: assets)
				}
				let navigationController = ThemeNavigationController(rootViewController: photoAlbumViewController)

				viewController.present(navigationController, animated: true)
			}
		} else {
			self.completed(with: NSError(ocError: .internal))
		}
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .folderAction {
			Theme.shared.add(tvgResourceFor: "image")
			return Theme.shared.image(for: "image", size: CGSize(width: 30.0, height: 30.0))!.withRenderingMode(.alwaysTemplate)
		}

		return nil
	}
}
