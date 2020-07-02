//
//  UploadCameraMediaAction.swift
//  ownCloud
//
//  Created by Michael Neuwert on 15.05.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2020, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit
import ownCloudSDK
import MobileCoreServices
import ImageIO
import AVFoundation

extension AVAsset {

     func exportVideo(targetURL:URL, type:AVFileType) -> Bool {
          if self.isExportable {
               let group = DispatchGroup()
               let preset = AVAssetExportPresetHighestQuality
               var compatiblePreset = false
               var exportSuccess = false

               group.enter()
               AVAssetExportSession.determineCompatibility(ofExportPreset: preset, with: self, outputFileType: type, completionHandler: { (isCompatible) in
                    compatiblePreset = isCompatible
                    group.leave()
               })

               group.wait()

               if compatiblePreset {
                    guard let export = AVAssetExportSession(asset: self, presetName: preset) else {
                         return false
                    }

                    // Configure export session
                    export.outputFileType = type
                    export.outputURL = targetURL

                    // Start export
                    group.enter()
                    export.exportAsynchronously {
                         exportSuccess = (export.status == .completed)
                         group.leave()
                    }

                    group.wait()
               }

               return exportSuccess
          }

          return false
     }
}

class CameraViewPresenter: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	typealias CameraCaptureCompletionHandler = (_ imageURL:URL?, _ alternativeName:String?, _ deleteImportedFile:Bool) -> Void

	let imagePickerController = UIImagePickerController()
	var completionHandler: CameraCaptureCompletionHandler?
	var parentViewController: UIViewController?

	static private let dateFormatter: DateFormatter = {
		let dateFormatter: DateFormatter =  DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
		dateFormatter.locale = Locale(identifier:"enUSPOSIX")
		return dateFormatter
	}()

	func present(on viewController:UIViewController, with completion:@escaping CameraCaptureCompletionHandler) {
		self.completionHandler = completion
		self.parentViewController = viewController

		// Check if camera is available
		guard UIImagePickerController.isSourceTypeAvailable(.camera),
			let cameraMediaTypes = UIImagePickerController.availableMediaTypes(for: .camera) else {
				return
		}

		// Setup UIImagePickerController
		imagePickerController.sourceType = .camera
		imagePickerController.mediaTypes = cameraMediaTypes
		imagePickerController.delegate = self
		imagePickerController.videoQuality = .typeHigh

		viewController.present(imagePickerController, animated: true)
	}

	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

		imagePickerController.dismiss(animated: true)

		let hud = ProgressHUDViewController(on: self.parentViewController, label: "Saving".localized)

		var image: UIImage?
		var outputURL: URL?
		var alternativeName: String?
		var preferHEIC = false
		var preferMP4 = false
		var deleteImportedFile = true

		// Check user settings concerning preferred media export formats
		if let userDefaults = OCAppIdentity.shared.userDefaults {
			preferHEIC = !userDefaults.convertHeic
			preferMP4 = userDefaults.convertVideosToMP4
		}

		// Check if HEIC is supported on this device if it is preferred output format
		if preferHEIC {
			let supportedOutputImageUTIs = CGImageDestinationCopyTypeIdentifiers() as NSArray
			preferHEIC = supportedOutputImageUTIs.contains(AVFileType.heic)
			if preferHEIC == false {
				Log.warning(tagged: ["CAMERA_UPLOAD"], "CGImageDestination doesn't support HEIC")
			}
		}

		// Perform media export on a background queue
		OnBackgroundQueue {
			defer {
				OnMainThread {
					hud.dismiss()
					self.completionHandler?(outputURL, alternativeName, deleteImportedFile)
				}
			}

			// Retrieve media type
			guard let type = info[.mediaType] as? String else { return }

			Log.debug(tagged: ["CAMERA_UPLOAD"], "UIImagePickerController info dictionary: \(info.debugDescription)")

			// Generate a timestamp string which will be used in the name of uploaded media
			let timeStamp = CameraViewPresenter.dateFormatter.string(from: Date())

			if type == String(kUTTypeImage) {
				// Retrieve UIImage
				image = info[.originalImage] as? UIImage

				let fileName = "Photo-\(timeStamp)"

				let ext = preferHEIC ? "heic" : "jpg"
				let uti = preferHEIC ? AVFileType.heic : AVFileType.jpg
				outputURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(fileName).appendingPathExtension(ext)

				guard let url = outputURL else { return }

				Log.debug(tagged: ["CAMERA_UPLOAD"], "Creating CGImageDestination with URL \(url)")

				let destination = CGImageDestinationCreateWithURL(url as CFURL, uti as CFString, 1, nil)

				guard let cgImage = image?.cgImage else {
					Log.error(tagged: ["CAMERA_UPLOAD"], "Image is not valid")
					outputURL = nil
					return
				}

				guard let dst = destination else {
					Log.error(tagged: ["CAMERA_UPLOAD"], "Destination is not valid")
					outputURL = nil
					return
				}

				let metaData = info[.mediaMetadata] as? NSDictionary

				CGImageDestinationAddImage(dst, cgImage, metaData)

				if !CGImageDestinationFinalize(dst) {
					Log.error(tagged: ["CAMERA_UPLOAD"], "Couldn't finish writing image")
					outputURL = nil
				} else {
					Log.log(tagged: ["CAMERA_UPLOAD"], "Finalized writing image with UTI \(uti) to disk")
				}

			} else if type == String(kUTTypeMovie) {
				guard let videoURL = info[.mediaURL] as? URL else { return }

				let fileName = "Video-\(timeStamp)"

				if preferMP4 {
					// Convert video clip to MPEG4 first
					outputURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(fileName).appendingPathExtension("mp4")
					guard let url = outputURL else { return }

					Log.debug(tagged: ["CAMERA_UPLOAD"], "Exporting video to \(url)")

					let avAsset = AVAsset(url: videoURL)
					if !avAsset.exportVideo(targetURL: url, type: .mp4) {
						Log.error(tagged: ["CAMERA_UPLOAD"], "Failed to export video as MP4")
						outputURL = nil
					} else {
						Log.debug(tagged: ["CAMERA_UPLOAD"], "Video export finished")
					}

				} else {
					// Upload video clip as is
					deleteImportedFile = false
					outputURL = videoURL
					alternativeName = "\(fileName).\(videoURL.pathExtension)"
					Log.debug(tagged: ["CAMERA_UPLOAD"], "Use video directly from URL: \(videoURL)")
				}
			}
		}
	}
}

class UploadCameraMediaAction: UploadBaseAction, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.upload.camera_media") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String { return "Take photo or video".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.folderAction, .keyboardShortcut] }
	override class var keyCommand : String? { return "3" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command, .shift] }

	var cameraPresenter = CameraViewPresenter()

	// MARK: - Action implementation

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .folderAction {
			let image = UIImage(named: "camera")?.withRenderingMode(.alwaysTemplate)
			return image
		}

		return nil
	}

	override func run() {
		guard context.items.count == 1, let rootItem = context.items.first, rootItem.type == .collection, let viewController = context.viewController else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		cameraPresenter.present(on: viewController) { (localMediaURL, alternativeName, shallDelete) in
			if let url = localMediaURL, let core = self.core {
				if let progress = url.upload(with: core, at: rootItem, alternativeName: alternativeName, placeholderHandler: { (_, error) in
					if error != nil {
						Log.error(tagged: ["CAMERA_UPLOAD"], "Failed to import media with error: \(String(describing: error))")
					}

					// Delete the media file if it was temporarily generated (this action was responsible for creating it)
					if shallDelete {
						do {
							try FileManager.default.removeItem(at: url)
						} catch {
							Log.error(tagged: ["CAMERA_UPLOAD"], "Failed to delete temporary media filed")
						}
					}
				}) {
					self.publish(progress: progress)
				} else {
					Log.error(tagged: ["CAMERA_UPLOAD"], "Error setting up upload of \(Log.mask(url.lastPathComponent)) to \(Log.mask(rootItem.path))")
				}
			}
			self.completed()
		}
	}
}
