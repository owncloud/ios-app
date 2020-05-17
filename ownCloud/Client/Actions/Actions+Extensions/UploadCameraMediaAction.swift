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

class CameraViewPresenter: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	typealias CameraCaptureCompletionHandler = (_ imageURL:URL?) -> Void

	let imagePickerViewController = UIImagePickerController()
	var completionHandler: CameraCaptureCompletionHandler?

	func present(on viewController:UIViewController, with completion:@escaping CameraCaptureCompletionHandler) {
		self.completionHandler = completion

		guard UIImagePickerController.isSourceTypeAvailable(.camera),
				let cameraMediaTypes = UIImagePickerController.availableMediaTypes(for: .camera) else {
				return
		}

		imagePickerViewController.sourceType = .camera
		imagePickerViewController.mediaTypes = cameraMediaTypes
		imagePickerViewController.delegate = self

		viewController.present(imagePickerViewController, animated: true)
	}

	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		imagePickerViewController.dismiss(animated: true)

		var image: UIImage?
		var outputURL:URL?
		var heic = false

		defer {
			self.completionHandler?(outputURL)
		}

		// Retrieve media type
		guard let type = info[.mediaType] as? String else { return }

		if type == String(kUTTypeImage) {
			// Retrieve UIImage
			image = info[.originalImage] as? UIImage

			// TODO: Get the meta-data
			//let metaData = info[.mediaMetadata]

			let fileName = "camera_shot"
			let ext = heic ? "heic" : "jpg"
			let uti = heic ? AVFileType.heic as CFString : kUTTypeJPEG
			outputURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(fileName).appendingPathExtension(ext)

			guard let url = outputURL else { return }

			// For HEIC use AVFileType.heic as CFString instead of kUTTypeJPEG
			let destination = CGImageDestinationCreateWithURL(url as CFURL, uti, 1, nil)

			guard let dst = destination, let cgImage = image?.cgImage else {
				outputURL = nil
				return
			}

			CGImageDestinationAddImage(dst, cgImage, nil)
			// TODO: Don't loose metadata
			//CGImageDestinationAddImageAndMetadata(destination, cgImage, metaData, nil)

			if !CGImageDestinationFinalize(dst) {
				outputURL = nil
			}

		} else if type == String(kUTTypeMovie) {
			outputURL = info[.mediaURL] as? URL
		}
	}
}

class UploadCameraMediaAction: UploadBaseAction, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.upload.camera_media") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String { return "Take photo".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.folderAction, .keyboardShortcut] }
	override class var keyCommand : String? { return "P" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command] }

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

		cameraPresenter.present(on: viewController) { (localImageURL) in
			if let url = localImageURL, let core = self.core {

				if let progress = url.upload(with: core, at: rootItem, placeholderHandler: { (_, error) in
					try? FileManager.default.removeItem(at: url)
				}) {
					self.publish(progress: progress)
				} else {
					Log.debug("Error setting up upload of \(Log.mask(url.lastPathComponent)) to \(Log.mask(rootItem.path))")
				}
			}
			self.completed()
		}
	}
}
