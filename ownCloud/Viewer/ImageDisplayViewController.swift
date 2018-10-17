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

	var scrollView: UIScrollView?
	var imageView: UIImageView?

	override func renderSpecificView() {
		scrollView = UIScrollView()

		scrollView?.translatesAutoresizingMaskIntoConstraints = false
		scrollView?.maximumZoomScale = 6.0
		scrollView?.bounces = false
		scrollView?.bouncesZoom = false
		scrollView?.delegate = self
		self.view.addSubview(scrollView!)

		NSLayoutConstraint.activate([
			scrollView!.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
			scrollView!.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
			scrollView!.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
			scrollView!.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)

		])

		imageView = UIImageView()
		do {
			let data = try Data(contentsOf: source)
			let image = UIImage(data: data)
			imageView?.image = image
			imageView?.contentMode = .scaleAspectFit
			imageView?.translatesAutoresizingMaskIntoConstraints = false
			imageView?.backgroundColor = .black
			scrollView!.addSubview(imageView!)
			NSLayoutConstraint.activate([
				imageView!.centerXAnchor.constraint(equalTo: scrollView!.centerXAnchor),
				imageView!.centerYAnchor.constraint(equalTo: scrollView!.centerYAnchor),
				imageView!.leftAnchor.constraint(equalTo: scrollView!.leftAnchor),
				imageView!.rightAnchor.constraint(equalTo: scrollView!.rightAnchor),
				imageView!.bottomAnchor.constraint(equalTo: scrollView!.bottomAnchor),
				imageView!.topAnchor.constraint(equalTo: scrollView!.topAnchor)
				])

		} catch {
			let alert = UIAlertController(with: "Error".localized, message: "Could not get the picture".localized, okLabel: "OK")
			self.parent?.present(alert, animated: true) {
				self.parent?.dismiss(animated: true)
			}
		}
	}
}

extension ImageDisplayViewController: UIScrollViewDelegate {
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return imageView
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
