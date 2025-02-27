//
//  EditSpaceImageAction.swift
//  ownCloud
//
//  Created by Felix Schwarz on 27.02.25.
//  Copyright © 2025 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2025, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import PhotosUI
import ownCloudSDK
import ownCloudAppShared
import ImagePlayground

class EditSpaceImageAction: Action, PHPickerViewControllerDelegate {
	override open class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.editspaceimage") }
	override open class var category : ActionCategory? { return .edit }
	override open class var name : String? { return OCLocalizedString("Edit image", nil) }
	override open class var locations : [OCExtensionLocationIdentifier]? { return [.moreFolder, .spaceAction] }

	// MARK: - Extension matching
	override open class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if let core = forContext.core, core.connectionStatus == .online, let drive = forContext.drive, drive.specialType == .space {
			if let shareActions = core.connection.shareActions(for: drive) {
				if shareActions.contains(.updatePermissions) {
					return .last
				}
			}
		}

		return .none
	}

	// MARK: - Action implementation
	override open func run() {
		guard context.drive != nil, let clientContext = context.clientContext else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		// Retrieve description item
		let alertController = UIAlertController(
			title: OCLocalizedString("Choose an image for the space", nil),
			message: nil,
			preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: OCLocalizedString("Pick a photo", nil), style: .default, handler: { _ in
			self.pickPhoto()
		}))
		alertController.addAction(UIAlertAction(title: OCLocalizedString("Text/Emoji", nil), style: .default, handler: { _ in
			self.createFromText()
		}))
		if #available(iOS 18.1, *) {
			if ImagePlaygroundViewController.isAvailable {
				alertController.addAction(UIAlertAction(title: OCLocalizedString("Image Playground", nil), style: .default, handler: { _ in
					self.createWithImagePlayground()
				}))
			}
		}
		alertController.addAction(UIAlertAction(title: OCLocalizedString("Cancel", nil), style: .cancel))

		clientContext.present(alertController, animated: true)
	}

	var picker: PHPickerViewController?

	func pickPhoto() {
		var config = PHPickerConfiguration(photoLibrary: .shared())
		config.selectionLimit = 1
		config.filter = .images
		config.preferredAssetRepresentationMode = .compatible

		picker = PHPickerViewController(configuration: config)
		picker?.delegate = self

		if let picker {
			picker.setValue(self, forAnnotatedProperty: "action") // prevent instance deallocation
			context.clientContext?.present(picker, animated: true)
		}
	}

	func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
		if let imageProvider = results.first?.itemProvider, imageProvider.canLoadObject(ofClass: UIImage.self) {
			imageProvider.loadObject(ofClass: UIImage.self, completionHandler: { obj, error in
				if let image = obj as? UIImage,
				   let scaledImage = image.scaledImageFitting(in: CGSize(width: 600, height: 400), scale: 1),
				   let scaledImageData = scaledImage.jpegData(compressionQuality: 0.6) {
					self.editImage(scaledImageData, fileName: "image.jpg")
				}
			})
		}

		picker.dismiss(animated: true)
		picker.setValue(nil, forAnnotatedProperty: "action")  // allow instance deallocation
	}

	func createFromText() {
		let textPrompt = UIAlertController(title: OCLocalizedString("Enter a emoji or text", nil), message: nil, preferredStyle: .alert)

		textPrompt.addTextField(configurationHandler: { textField in
			textField.placeholder = OCLocalizedString("Emoji or text", nil)
			textField.text = ""
		})

		textPrompt.addAction(UIAlertAction(title: OCLocalizedString("Cancel", nil), style: .cancel))
		textPrompt.addAction(UIAlertAction(title: OCLocalizedString("Create image", nil), style: .default, handler: { [weak textPrompt] action in
			let text = (textPrompt?.textFields?.first?.text ?? "") as NSString

			let imageSize = CGSize(width: 720, height: 405) // This is the size used by ocis Web when setting an image from an emoji ("icon")

			// Render text
			let font = UIFont.systemFont(ofSize: imageSize.height - 5, weight: .bold)
			let attributes: [ NSAttributedString.Key : Any ] = [
				.font : font,
				.foregroundColor : UIColor.black
			]
			let size = text.size(withAttributes: attributes)

			let renderFormat = UIGraphicsImageRendererFormat()
			renderFormat.scale = 1.0
			let textImageRenderer = UIGraphicsImageRenderer(size: size, format: renderFormat)
			let textImage = textImageRenderer.image(actions: { context in
				text.draw(at: .zero, withAttributes: attributes)
			})

			// Scale the rendered image to fit into imageSize, then pad it to imageSize
			let image = textImage.scaledImageFitting(in: imageSize, scale: 1).paddedTo(width: imageSize.width, height: imageSize.height)

			// Encode image as PNG
			if let pngData = image?.pngData() {
				// Upload image
				self.editImage(pngData, fileName: "emoji.png")
			}
		}))

		context.clientContext?.present(textPrompt, animated: true)
	}

	func createWithImagePlayground() {
		if #available(iOS 18.1, *) {
			let imagePlaygroundViewController = ImagePlaygroundViewController()
			imagePlaygroundViewController.delegate = self
			if let driveName = context.drive?.name {
				imagePlaygroundViewController.concepts = [.extracted(from: driveName, title: nil)]
			}

			imagePlaygroundViewController.setValue(self, forAnnotatedProperty: "action") // prevent instance deallocation
			context.clientContext?.present(imagePlaygroundViewController, animated: true)
		}
	}

	func editImage(_ imageData: Data, fileName: String) {
		guard let clientContext = self.context.clientContext else {
			return
		}

		var imageFileURL: NSURL?

		if let eraser = try? clientContext.core?.vault.createTemporaryUploadFile(from: imageData, name: fileName, url: &imageFileURL) {
			if imageFileURL != nil, let drive = self.context.drive {
				// Retrieve space folder
				clientContext.core?.retrieveDrive(drive, itemForResource: .spaceFolder, completionHandler: { err, spaceFolderItem in
					guard let imageFileURL = imageFileURL as? URL, let spaceFolderItem, err == nil else {
						eraser()  // erase temporary file+folder
						return
					}

					// Upload
					clientContext.core?.importFileNamed(imageFileURL.lastPathComponent, at: spaceFolderItem, from: imageFileURL, isSecurityScoped: false, options: [
						.importByCopying: true,
						OCCoreOption(rawValue: OCConnectionOptionKey.forceReplaceKey.rawValue) : true // Replace existing file
					], placeholderCompletionHandler: nil, resultHandler: { err, core, item, _ in
						if err == nil {
							clientContext.core?.updateDrive(drive, resourceFor: .coverImage, with: item, completionHandler: nil)
						}
						eraser() // erase temporary file+folder
					})
				})
			}
		}
	}

	override open class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return UIImage(systemName: "photo")?.withRenderingMode(.alwaysTemplate)
	}

}

@available(iOS 18.1, *)
extension EditSpaceImageAction: ImagePlaygroundViewController.Delegate {
	func imagePlaygroundViewController(_ imagePlaygroundViewController: ImagePlaygroundViewController, didCreateImageAt imageURL: URL) {
		imagePlaygroundViewController.dismiss(animated: true)

		// Image Playground returns a HEIC image, so load it, scale it down and save it as JPEG
		if let image = UIImage(contentsOfFile: imageURL.path)?.scaledImageFitting(in: CGSize(width: 400, height: 400)) {
			if let imageData = image.jpegData(compressionQuality: 0.6) {
				editImage(imageData, fileName: "aiGenerated.jpg")
			}
		}

		imagePlaygroundViewController.setValue(nil, forAnnotatedProperty: "action") // allow instance deallocation
	}

	func imagePlaygroundViewControllerDidCancel(_ imagePlaygroundViewController: ImagePlaygroundViewController) {
		imagePlaygroundViewController.dismiss(animated: true)
		imagePlaygroundViewController.setValue(nil, forAnnotatedProperty: "action") // allow instance deallocation
	}
}
