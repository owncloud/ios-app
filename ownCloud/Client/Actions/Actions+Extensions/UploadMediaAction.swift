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
class PhotoPickerPresenter: NSObject, PHPickerViewControllerDelegate, PHPhotoLibraryChangeObserver {

	typealias AssetSelectionHandler = ([PHAsset]) -> Void

	var completionHandler: AssetSelectionHandler?
	var parentViewController: UIViewController?

	private var assetIdentifiers = [String]()

	override init() {
		super.init()
		PHPhotoLibrary.shared().register(self)
	}

	var pickerViewController: UIViewController {
		var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
		configuration.preferredAssetRepresentationMode = .automatic
		configuration.selectionLimit = 0
		let pickerViewController = PHPickerViewController(configuration: configuration)
		pickerViewController.delegate = self

		return pickerViewController
	}

	// MARK: - PHPickerViewControllerDelegate

	func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {

		picker.dismiss(animated: true)

		OnBackgroundQueue {

			// Get asset identifiers
			for result in results {
				if let identifier = result.assetIdentifier {
					self.assetIdentifiers.append(identifier)
				}
			}

			// Fetch corresponding assets
			let assets = self.attemptAssetsFetch()

			OnMainThread {
				if results.count == assets.count{
					self.completionHandler?(assets)
				} else {
					self.presentLimitedLibraryPicker()
				}
			}
		}
	}

	private func presentLimitedLibraryPicker() {
		guard let viewController = self.parentViewController else { return }
		let library = PHPhotoLibrary.shared()

		let alert = ThemedAlertController(title: "Limited Photo Access".localized, message: "Access for the media selected for upload is limited".localized, preferredStyle: .alert)

		alert.addAction(UIAlertAction(title: "Change".localized, style: .default, handler: {_ in
			library.presentLimitedLibraryPicker(from: viewController)
		}))
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
			self.assetIdentifiers.removeAll()
		}))

		self.parentViewController?.present(alert, animated: true)

	}

	private func attemptAssetsFetch() -> [PHAsset] {
		// Fetch corresponding assets
		var assets = [PHAsset]()

		let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: assetIdentifiers, options: nil)
		fetchResult.enumerateObjects({ (asset, _, _) in
			assets.append(asset)
		})

		return assets
	}

	func present(in viewController:UIViewController, with completion:@escaping AssetSelectionHandler) {
		self.parentViewController = viewController
		self.completionHandler = completion
		viewController.present(self.pickerViewController, animated: true)
	}

	// MARK: - PHPhotoLibraryChangeObserver

	func photoLibraryDidChange(_ changeInstance: PHChange) {
		OnMainThread {
			let assets = self.attemptAssetsFetch()
			if assets.count > 0 {
				self.completionHandler?(assets)
			} else {
				let alert = ThemedAlertController(title: "Limited Photo Access".localized, message: "No Access to the media selected for upload".localized, preferredStyle: .alert)

				alert.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: nil))

				self.parentViewController?.present(alert, animated: true)
			}
		}
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
