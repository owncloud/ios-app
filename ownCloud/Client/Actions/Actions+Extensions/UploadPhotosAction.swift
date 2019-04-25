//
//  UploadPhotosAction.swift
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
import Photos

class UploadPhotosAction: UploadBaseAction {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.uploadphotos") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String { return "Upload from your photo library".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.plusButton] }

	private struct AssociatedKeys {
		static var actionKey = "action"
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count == 1, context.items.first?.type == .collection, let viewController = context.viewController else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let permisson = PHPhotoLibrary.authorizationStatus()

		switch permisson {
			case .authorized:
				presentImageGalleryPicker()

			case .notDetermined:
				PHPhotoLibrary.requestAuthorization({ newStatus in
					if newStatus == .authorized {
						self.presentImageGalleryPicker()
					} else {
						self.completed()
					}
				})

			default:
				PHPhotoLibrary.requestAuthorization({ newStatus in
					if newStatus == .denied {
						let alert = UIAlertController(title: "Missing permissions".localized, message: "This permission is needed to upload photos and videos from your photo library.".localized, preferredStyle: .alert)

						let settingAction = UIAlertAction(title: "Settings".localized, style: .default, handler: { _ in
							UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
						})
						let notNowAction = UIAlertAction(title: "Not now".localized, style: .cancel)

						alert.addAction(settingAction)
						alert.addAction(notNowAction)

						OnMainThread {
							viewController.present(alert, animated: true)

							self.completed()
						}
					}
				})
		}
	}

	func presentImageGalleryPicker() {
		OnMainThread {
			if let viewController = self.context.viewController {
				let photoAlbumViewController = PhotoAlbumTableViewController()
				photoAlbumViewController.selectionCallback = { (assets) in
					for asset in assets {
						self.upload(asset: asset)
					}

					self.completed()
				}
				let navigationController = ThemeNavigationController(rootViewController: photoAlbumViewController)

				viewController.present(navigationController, animated: true)
			} else {
				self.completed(with: NSError(ocError: .internal))
			}
		}
	}

	func upload(asset:PHAsset) {

		guard let userDefaults = OCAppIdentity.shared.userDefaults else { return }

		let ressources = PHAssetResource.assetResources(for: asset)

		if let ressource = ressources.first, let rootItem = context.items.first {
			let filename = ressource.originalFilename

			let progress = Progress(totalUnitCount: 100)
			progress.localizedDescription = String(format: "Importing '%@' from photo library".localized, filename)

			let options = PHAssetResourceRequestOptions()
			options.isNetworkAccessAllowed = true
			options.progressHandler = { (completed:Double) in
				progress.completedUnitCount = Int64(completed * 100)
			}

			self.publish(progress: progress)

			func finishUpload(_ error:Error?, url:URL) {
				self.unpublish(progress: progress)
				if error == nil {
					self.upload(itemURL: url, to: rootItem, name: url.lastPathComponent, completionHandler: { (_) in
						// Delete the temporary asset file
						try? FileManager.default.removeItem(at: url)
					})
				} else {
					progress.cancel()
				}
			}

			if ressource.uniformTypeIdentifier == "public.heic" && userDefaults.convertHeic {
				// Convert HEIC to JPEG using CoreImage APIs
				var imageData = Data()
				let localURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename).deletingPathExtension().appendingPathExtension("jpg")

				PHAssetResourceManager.default().requestData(for: ressource, options: options, dataReceivedHandler: { (data) in
					imageData.append(data)
				}, completionHandler: { (error) in
					if error == nil {
						if let ciImage = CIImage(data: imageData) {
							let jpegData = CIContext().jpegRepresentation(of: ciImage, colorSpace: CGColorSpaceCreateDeviceRGB())
							try? jpegData?.write(to: localURL)
						}
					}
					finishUpload(error, url:localURL)
				})
			} else {
				// No conversion
				let localURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)

				PHAssetResourceManager.default().writeData(for: ressource, toFile: localURL, options: options) { (error) in
					finishUpload(error, url:localURL)
				}
			}

		} else {
			self.completed(with: NSError(ocError: .internal))
		}
	}
}
