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

	private let uploadSerialQueue = DispatchQueue(label: "com.owncloud.upload.queue", target: DispatchQueue.global(qos: .background))

	private struct AssociatedKeys {
		static var actionKey = "action"
	}

	private enum OutputImageFormat { case HEIF, JPEG}

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

	private func presentImageGalleryPicker() {
		OnMainThread {
			if let viewController = self.context.viewController {
				let photoAlbumViewController = PhotoAlbumTableViewController()
				photoAlbumViewController.selectionCallback = { (assets) in

					DispatchQueue.global(qos: .userInitiated).async {
						let uploadGroup = DispatchGroup()
						var uploadFailed = false

						for asset in assets {
							if uploadFailed == false {
								// Upload image on a background queue
								uploadGroup.enter()

								self.upload(asset: asset, completion: { (success) in
									if !success {
										uploadFailed = true
									}
									uploadGroup.leave()
								})

								_ = uploadGroup.wait(timeout: .now() + 0.5)

							} else {
								// Escape on first failed download
								break
							}
						}

						uploadGroup.notify(queue: DispatchQueue.main, execute: {
							self.completed( with: uploadFailed ? NSError(ocError: .internal) : nil)
						})
					}
				}
				let navigationController = ThemeNavigationController(rootViewController: photoAlbumViewController)

				viewController.present(navigationController, animated: true)
			} else {
				self.completed(with: NSError(ocError: .internal))
			}
		}
	}

	private func convertImage(_ sourceURL:URL, targetURL:URL, outputFormat:OutputImageFormat) -> Bool {
		// Conversion to JPEG required
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		var ciContext = CIContext()
		var imageData : Data?

		var image = CIImage(contentsOf: sourceURL)

		func cleanUpCoreImageRessources() {
			// Release memory consuming resources
			imageData = nil
			image = nil
			ciContext.clearCaches()
		}

		if image != nil {
			switch outputFormat {
			case .JPEG:
				imageData = ciContext.jpegRepresentation(of: image!, colorSpace: colorSpace)
			case .HEIF:
				imageData = ciContext.heifRepresentation(of: image!, format: CIFormat.RGBA8, colorSpace: colorSpace)
			}

			if imageData != nil {
				do {
					// First write an image to a file stored in temporary directory
					try imageData!.write(to: targetURL)
					cleanUpCoreImageRessources()
					return true
				} catch {
					cleanUpCoreImageRessources()
				}
			}
		}

		return false
	}

	private func upload(asset:PHAsset, completion:@escaping (_ success:Bool) -> Void ) {
		guard let userDefaults = OCAppIdentity.shared.userDefaults else { return }

		guard let rootItem = context.items.first else { return }

		// Prepare progress object for importing full size asset from photo library
		let progress = Progress(totalUnitCount: 100)
		progress.localizedDescription = "Importing from photo library".localized
		self.publish(progress: progress)

		// Setup import options, allow download asset from network if necessary
		let contentInputOptions = PHContentEditingInputRequestOptions()
		contentInputOptions.isNetworkAccessAllowed = true
		contentInputOptions.progressHandler = { (percentage:Double, _) in
			progress.completedUnitCount = Int64(percentage * 100)
		}

		// Import full size asset
		asset.requestContentEditingInput(with: contentInputOptions) { (input, _) in
			self.unpublish(progress: progress)

			self.uploadSerialQueue.async {
				if let input = input, let url = input.fullSizeImageURL {
					let fileName = url.lastPathComponent

					if !userDefaults.convertHeic || input.uniformTypeIdentifier == "public.jpeg" {
						// No conversion of the image data, upload as is
						self.upload(itemURL: url, to: rootItem, name:fileName, completionHandler: { (actionPerformed, _) in
							// Delete the temporary asset file
							completion(actionPerformed)
						}, importByCopy: true)
					} else {
						let localURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName).deletingPathExtension().appendingPathExtension("jpg")
						if self.convertImage(url, targetURL: localURL, outputFormat: .JPEG) {
							// Upload to the cloud
							self.upload(itemURL: localURL, to: rootItem, name: localURL.lastPathComponent, completionHandler: { (actionPerformed, error) in
								// Delete the temporary asset file in case of critical error
								do {
									if error != nil {
										try FileManager.default.removeItem(at: localURL)
									}
									completion(actionPerformed)
								} catch {
									completion(false)
								}
							})
						} else {
							completion(false)
						}
					}
				} else {
					completion(false)
				}
			}
		}
	}
}
