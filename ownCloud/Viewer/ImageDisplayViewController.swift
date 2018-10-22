//
//  ImageDisplayViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 17/10/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

class ImageDisplayViewController : DisplayViewController {

	var scrollView: ImageScrollView?
	var imageView: UIImageView?

	override func renderSpecificView() {
		scrollView = ImageScrollView(frame: self.view.bounds)
		scrollView?.translatesAutoresizingMaskIntoConstraints = false
		self.view.addSubview(scrollView!)
		NSLayoutConstraint.activate([
			scrollView!.leftAnchor.constraint(equalTo: view.leftAnchor),
			scrollView!.rightAnchor.constraint(equalTo: view.rightAnchor),
			scrollView!.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			scrollView!.topAnchor.constraint(equalTo: view.topAnchor)
		])

		do {
			let data = try Data(contentsOf: source)
			let image = UIImage(data: data)
			scrollView?.display(image: image!)

		} catch {
			let alert = UIAlertController(with: "Error".localized, message: "Could not get the picture".localized, okLabel: "OK")
			self.parent?.present(alert, animated: true) {
				self.parent?.dismiss(animated: true)
			}
		}
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		self.scrollView?.updateScaleForRotation(size: size)
	}
}

extension ImageDisplayViewController: DisplayExtension {
	static var customMatcher: OCExtensionCustomContextMatcher? = { (context, defaultPriority) in
		do {
			let location = context!.location.identifier.rawValue
			let supportedFormatsRegex = try NSRegularExpression(pattern: "\\A((image/))", options: .caseInsensitive)
			let matches = supportedFormatsRegex.numberOfMatches(in: location, options: .reportCompletion, range: NSRange(location: 0, length: location.count))

			if matches > 0 {
				return OCExtensionPriority.locationMatch
			} else {
				return OCExtensionPriority.noMatch
			}
		} catch {
			return OCExtensionPriority.noMatch
		}
	}
	static var displayExtensionIdentifier: String = "org.owncloud.image"
	static var supportedMimeTypes: [String]?
	static var features: [String : Any]? = [FeatureKeys.canEdit : false]
}
