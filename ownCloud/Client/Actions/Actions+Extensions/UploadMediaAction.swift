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

class UploadMediaAction: UploadBaseAction {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.uploadphotos") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String { return "Upload from your photo library".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.plusButton] }

	private let uploadSerialQueue = DispatchQueue(label: "com.owncloud.upload.queue", target: DispatchQueue.global(qos: .background))

	private struct AssociatedKeys {
		static var actionKey = "action"
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count == 1, context.items.first?.type == .collection, let viewController = context.viewController else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		PHPhotoLibrary.requestAccess { [weak self] (granted) in
			if granted {
				self?.presentImageGalleryPicker()
			} else {
				let alert = UIAlertController.alertControllerForPhotoLibraryAuthorizationInSettings()
				viewController.present(alert, animated: true)
				self?.completed()
			}
		}
	}

	private func presentImageGalleryPicker() {
		OnMainThread {
			if let viewController = self.context.viewController {
				let photoAlbumViewController = PhotoAlbumTableViewController()
				photoAlbumViewController.selectionCallback = { (assets) in

					self.completed()

					let queue = DispatchQueue.global(qos: .userInitiated)

					queue.async {

						self.core?.perform(inRunningCore: { (runningCoreCompletion) in

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

									// Avoid submitting to many jobs simultaneously to reduce memory pressure
									_ = uploadGroup.wait(timeout: .now() + 0.5)

								} else {
									// Escape on first failed download
									break
								}
							}

							uploadGroup.notify(queue: queue, execute: {
								runningCoreCompletion()
							})

						}, withDescription: "Uploading \(assets.count) photo assets")
					}
				}
				let navigationController = ThemeNavigationController(rootViewController: photoAlbumViewController)

				viewController.present(navigationController, animated: true)
			} else {
				self.completed(with: NSError(ocError: .internal))
			}
		}
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

			var assetURL: URL?
			switch asset.mediaType {
			case .image:
				assetURL = input?.fullSizeImageURL
			case .video:
				assetURL = (input?.audiovisualAsset as? AVURLAsset)?.url
			default:
				break
			}

			self.uploadSerialQueue.async {
				if let input = input, let url = assetURL {

					func performUpload(sourceURL:URL, copySource:Bool) {

						@discardableResult func removeSourceFile() -> Bool {
							do {
								try FileManager.default.removeItem(at: sourceURL)
								return true
							} catch {
								return false
							}
						}

						let fileName = sourceURL.lastPathComponent
						self.upload(itemURL: sourceURL, to: rootItem, name:fileName, placeholderHandler: { (_, error) in
							if !copySource && error != nil {
								// Delete the temporary asset file in case of critical error
								removeSourceFile()
							}
							completion(error == nil)
						}, importByCopy: copySource)
					}

					if asset.mediaType == .image {
						if !userDefaults.convertHeic || input.uniformTypeIdentifier == "public.jpeg" {
							// No conversion of the image data, upload as is
							performUpload(sourceURL: url, copySource: true)
						} else {
							let fileName = url.lastPathComponent
							let localURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName).deletingPathExtension().appendingPathExtension("jpg")
							// Convert to JPEG
							var imageConverted = false
							if let image = CIImage(contentsOf: url) {
								imageConverted = image.convert(targetURL: localURL, outputFormat: .JPEG)
							}

							if imageConverted {
								// Upload to the cloud
								performUpload(sourceURL: localURL, copySource: false)
							} else {
								completion(false)
							}
						}
					} else if asset.mediaType == .video {
						if userDefaults.convertVideosToMP4 {
							let fileName = url.lastPathComponent
							let localURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName).deletingPathExtension().appendingPathExtension("mp4")
							if let asset = input.audiovisualAsset {
								asset.exportVideo(targetURL: localURL, type: .mp4, completion: { (exportSuccess) in
									if exportSuccess {
										performUpload(sourceURL: localURL, copySource: false)
									} else {
										completion(false)
									}
								})
							} else {
								completion(false)
							}

						} else {
							performUpload(sourceURL: url, copySource: true)
						}
					}

				} else {
					completion(false)
				}
			}
		}
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .plusButton {
			Theme.shared.add(tvgResourceFor: "image")
			return Theme.shared.image(for: "image", size: CGSize(width: 30.0, height: 30.0))!.withRenderingMode(.alwaysTemplate)
		}

		return nil
	}
}
