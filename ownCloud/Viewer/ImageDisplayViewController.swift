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

	private let MAX_ZOOM_DIVIDER: CGFloat = 3.0

	// MARK: - Instance variables
	var scrollView: ImageScrollView?
	var imageView: UIImageView?

	// MARK: - Gesture recognizers
	var tapToZoomGestureRecognizer : UITapGestureRecognizer!
	var tapToHideBarsGestureRecognizer: UITapGestureRecognizer!

	// MARK: - Specific view
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

			tapToZoomGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapToZoom))
			tapToZoomGestureRecognizer.numberOfTapsRequired = 2
			scrollView?.addGestureRecognizer(tapToZoomGestureRecognizer)

			tapToHideBarsGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapToHideBars))
			scrollView?.addGestureRecognizer(tapToHideBarsGestureRecognizer)

			tapToZoomGestureRecognizer.delegate = self
			tapToHideBarsGestureRecognizer.delegate = self

		} catch {
			let alert = UIAlertController(with: "Error".localized, message: "Could not get the picture".localized, okLabel: "OK")
			self.parent?.present(alert, animated: true) {
				self.parent?.dismiss(animated: true)
			}
		}
	}

	// MARK: - Frame changes
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		self.scrollView?.updateScaleForRotation(size: size)
	}

	// MARK: - Gesture recognizers actions.
	@objc func tapToZoom() {
		if scrollView!.zoomScale != scrollView!.minimumZoomScale {
			scrollView!.setZoomScale(scrollView!.minimumZoomScale, animated: true)
		} else {
			scrollView!.setZoomScale(scrollView!.maximumZoomScale / MAX_ZOOM_DIVIDER, animated: true)
		}

		setNeedsUpdateOfHomeIndicatorAutoHidden()
	}

	@objc func tapToHideBars() {
		guard let navigationController = navigationController else {
			return
		}

		if !navigationController.isNavigationBarHidden {
			navigationController.setNavigationBarHidden(true, animated: true)
		} else {
			navigationController.setNavigationBarHidden(false, animated: true)
		}

		setNeedsUpdateOfHomeIndicatorAutoHidden()
	}

	override func prefersHomeIndicatorAutoHidden() -> Bool {
		guard let navigationController = navigationController else {
			return false
		}

		guard scrollView != nil else {
			return false
		}

		guard navigationController.isNavigationBarHidden else {
			return false
		}

		return true
	}
}

// MARK: - Display Extension.
extension ImageDisplayViewController: DisplayExtension {
	static var customMatcher: OCExtensionCustomContextMatcher? = { (context, defaultPriority) in
		do {
			if let mimeType = context.location?.identifier?.rawValue {
				let supportedFormatsRegex = try NSRegularExpression(pattern: "\\A((image/(?!(gif|svg*))))", options: .caseInsensitive)
				let matches = supportedFormatsRegex.numberOfMatches(in: mimeType, options: .reportCompletion, range: NSRange(location: 0, length: mimeType.count))

				if matches > 0 {
					return OCExtensionPriority.locationMatch
				}
			}

			return OCExtensionPriority.noMatch
		} catch {
			return OCExtensionPriority.noMatch
		}
	}
	static var displayExtensionIdentifier: String = "org.owncloud.image"
	static var supportedMimeTypes: [String]?
	static var features: [String : Any]? = [FeatureKeys.canEdit : false]
}

// MARK: - Gesture recognizer delegete.
extension ImageDisplayViewController: UIGestureRecognizerDelegate {

	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		if gestureRecognizer === tapToZoomGestureRecognizer && otherGestureRecognizer === tapToHideBarsGestureRecognizer {
			return true
		}

		return false
	}

	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		if gestureRecognizer === tapToZoomGestureRecognizer && otherGestureRecognizer === tapToHideBarsGestureRecognizer {
			return false
		}

		if gestureRecognizer === tapToHideBarsGestureRecognizer && otherGestureRecognizer === tapToZoomGestureRecognizer {
			return false
		}

		return true
	}
}
