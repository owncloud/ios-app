//
//  SaveMarkupAction.swift
//  ownCloud
//
//  Created by Matthias Hühne on 16/09/2019.
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

import ownCloudSDK
import PencilKit

@available(iOS 13.0, *)
class SaveMarkupAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.savemarkup") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Save Markup".localized }
	override class var keyCommand : String? { return "#" }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreFolder] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		guard let viewController = forContext.viewController as? PreviewViewController, let window = viewController.view.window, let toolPicker = PKToolPicker.shared(for: window) else {
			return .none
		}

		if !toolPicker.isVisible {
			return .none
		}

		// Examine items in context
		return .middle
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0, let viewController = context.viewController as? PreviewViewController else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let alertController = UIAlertController(title: "Save Markup".localized,
												message: nil,
												preferredStyle: .alert)

		alertController.addAction(UIAlertAction(title: "Replace File".localized, style: .default, handler: { (_) in
			self.finishMarkup(context: self.context)
			self.prepareSaving(context: self.context, copy: false)
		}))
		alertController.addAction(UIAlertAction(title: "Save as Copy".localized, style: .default, handler: { (_) in
			self.finishMarkup(context: self.context)
			self.prepareSaving(context: self.context, copy: true)
		}))
		alertController.addAction(UIAlertAction(title: "Discard changes".localized, style: .destructive, handler: { (_) in
			self.finishMarkup(context: self.context)
		}))
		alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler:nil))

		viewController.present(alertController, animated: true, completion: nil)
	}

	func finishMarkup(context: ActionContext) {
		guard let viewController = context.viewController as? PreviewViewController, let window = viewController.view.window, let toolPicker = PKToolPicker.shared(for: window)  else {
			return
		}

		toolPicker.setVisible(false, forFirstResponder: viewController.canvasView)
		toolPicker.removeObserver(viewController.canvasView)

		guard let displayViewController = viewController.parent as? DisplayHostViewController else {
			return
		}

		displayViewController.isPagingEnabled = true
	}

	func saveMarkup(file: OCFile, context: ActionContext, copy: Bool) {
		guard context.items.count > 0, let viewController = context.viewController as? PreviewViewController, let core = self.core, let item = context.items.first else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		if let url = file.url, let nsdata = NSData(contentsOf: url), let parentItem = item.parentItem(from: core), let displayViewController = viewController.parent as? DisplayHostViewController, let qlPreviewController = viewController.qlPreviewController {
			let data = Data(referencing: nsdata)
			if let orgImage = UIImage(data: data), let scrollView = displayViewController.scrollView {
				let visibleRect = scrollView.convert(scrollView.bounds, to: viewController.canvasView)
				print("--> visibleRect \(visibleRect)")
				let image = viewController.canvasView.drawing.image(from: qlPreviewController.view.bounds, scale: scrollView.zoomScale)
				//let image = viewController.canvasView.drawing.image(from: visibleRect, scale: 1.0)
				print("--> image \(image)")
				let newImage = UIImage.imageByMergingImages(topImage: image, bottomImage: orgImage)
				let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
				let fileName = "image.jpg"
				let fileURL = documentsDirectory.appendingPathComponent(fileName)

				OnMainThread {
					viewController.canvasView.removeFromSuperview()
				}

				if let newData = newImage.jpegData(compressionQuality:  1.0) {
					do {
						try newData.write(to: fileURL)

						if copy {
							self.saveAsCopy(core: core, fileURL: fileURL, filename: String(format:"Markup.jpg"), targetItem: parentItem)
						} else {
							self.saveByReplacing(item: item, fileURL: fileURL, core: core, parentItem: parentItem)
						}
					} catch {
						print("error saving file:", error)
						self.completed(with: NSError(ocError: .internal))
					}
				}
			}
		}
	}

	func prepareSaving(context: ActionContext, copy: Bool) {
		guard context.items.count > 0, let core = self.core, let item = context.items.first else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		if core.localCopy(of: item) == nil {
			core.downloadItem(item, options: [ .returnImmediatelyIfOfflineOrUnavailable : true ], resultHandler: { (error, core, item, file) in
				if error == nil {
					if let item = item, let file = item.file(with: core) {
						self.saveMarkup(file: file, context: context, copy: copy)
					}
				} else {
				}
			})
		} else {
			if let file = item.file(with: core) {
				saveMarkup(file: file, context: context, copy: copy)
			}
		}
	}

	func saveByReplacing(item: OCItem, fileURL: URL, core: OCCore, parentItem: OCItem) {
		core.reportLocalModification(of: item, parentItem: parentItem, withContentsOfFileAt: fileURL, isSecurityScoped: false, options: nil, placeholderCompletionHandler: { (error, item) in
			if error != nil {
				self.completed(with: NSError(ocError: .internal))
			}
		}) { (error, _, _, _) in
			print("--> completion \(error)")
			if error != nil {
				self.completed(with: NSError(ocError: .internal))
			}
		}
	}

	func saveAsCopy(core: OCCore, fileURL: URL, filename: String, targetItem: OCItem) {
		core.importFileNamed(filename,
							 at: targetItem,
							 from: fileURL,
							 isSecurityScoped: true,
							 options: [OCCoreOption.importByCopying : true],
							 placeholderCompletionHandler: { (error, item) in
		},
							 resultHandler: { (error, _ core, _ item, _) in
		}
		)
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem || location == .moreFolder {
			return UIImage(named: "folder")
		}

		return nil
	}
}

extension UIImage {
	static func imageByMergingImages(topImage: UIImage, bottomImage: UIImage, scaleForTop: CGFloat = 1.0) -> UIImage {
		let size = bottomImage.size
		let container = CGRect(x: 0, y: 0, width: size.width, height: size.height)
		UIGraphicsBeginImageContextWithOptions(size, false, 2.0)
		UIGraphicsGetCurrentContext()!.interpolationQuality = .high
		bottomImage.draw(in: container)

		let topWidth = size.width / scaleForTop
		let topHeight = size.height / scaleForTop
		let topX = (size.width / 2.0) - (topWidth / 2.0)
		let topY = (size.height / 2.0) - (topHeight / 2.0)

		topImage.draw(in: CGRect(x: topX, y: topY, width: topWidth, height: topHeight), blendMode: .normal, alpha: 1.0)

		return UIGraphicsGetImageFromCurrentImageContext()!
	}
}
