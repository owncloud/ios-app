//
//  ImageDisplayViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 17/10/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2018, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

class ImageDisplayViewController : DisplayViewController {

	private let max_zoom_divider: CGFloat = 3.0
	private let activityIndicatorHeight: CGFloat = 50.0

	private let serialQueue: DispatchQueue = DispatchQueue(label: "decode queue")

	// MARK: - Instance variables
	var scrollView: ImageScrollView?

	var activityIndicatorView: UIActivityIndicatorView = {
		let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.white)
		activityIndicator.translatesAutoresizingMaskIntoConstraints = false
		return activityIndicator
	}()

	// MARK: - Gesture recognizers
	var tapToZoomGestureRecognizer : UITapGestureRecognizer!
	var tapToHideBarsGestureRecognizer: UITapGestureRecognizer!

	// MARK: - View controller lifecycle

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidAppear(animated)

		scrollView?.setZoomScale(scrollView!.minimumZoomScale, animated: true)
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		scrollView?.updateScaleForRotation(size: self.view!.bounds.size)
	}

	func downSampleImage() {
		if let source = source {
			activityIndicatorView.startAnimating()
			let size: CGSize = self.view.bounds.size
			let scale: CGFloat = UIScreen.main.scale
			let imageSourceOptions = [kCGImageSourceShouldCache: true] as CFDictionary
			if let imageSource = CGImageSourceCreateWithURL(source as CFURL, imageSourceOptions) {
				let maxDimensionInPixels = max(size.width, size.height) * scale
				let downsampleOptions =  [kCGImageSourceCreateThumbnailFromImageAlways: true,
										  kCGImageSourceShouldCacheImmediately: true,
										  kCGImageSourceCreateThumbnailWithTransform: true,
										  kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels] as CFDictionary
				serialQueue.async {
					if let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) {
						let image = UIImage(cgImage: downsampledImage)
						OnMainThread {
							self.activityIndicatorView.stopAnimating()
							self.scrollView?.display(image: image, inSize: self.view.bounds.size)
						}
					} else {
						OnMainThread {
							self.activityIndicatorView.stopAnimating()
						}
					}
				}
			}
		}
	}

	// MARK: - Specific view
	override func renderSpecificView() {
		scrollView = ImageScrollView(frame: .zero)
		scrollView?.translatesAutoresizingMaskIntoConstraints = false

		self.view.addSubview(scrollView!)
		NSLayoutConstraint.activate([
			scrollView!.leftAnchor.constraint(equalTo: view.leftAnchor),
			scrollView!.rightAnchor.constraint(equalTo: view.rightAnchor),
			scrollView!.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			scrollView!.topAnchor.constraint(equalTo: view.topAnchor)
			])

		self.scrollView?.addSubview(activityIndicatorView)
		NSLayoutConstraint.activate([
			activityIndicatorView.centerYAnchor.constraint(equalTo: scrollView!.centerYAnchor),
			activityIndicatorView.centerXAnchor.constraint(equalTo: scrollView!.centerXAnchor),
			activityIndicatorView.heightAnchor.constraint(equalToConstant: activityIndicatorHeight),
			activityIndicatorView.widthAnchor.constraint(equalTo: activityIndicatorView.heightAnchor)
			])

		if source != nil {
			downSampleImage()
			tapToZoomGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapToZoom))
			tapToZoomGestureRecognizer.numberOfTapsRequired = 2
			scrollView?.addGestureRecognizer(tapToZoomGestureRecognizer)

			tapToHideBarsGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapToHideBars))
			scrollView?.addGestureRecognizer(tapToHideBarsGestureRecognizer)

			tapToZoomGestureRecognizer.delegate = self
			tapToHideBarsGestureRecognizer.delegate = self
		} else {
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
			scrollView!.setZoomScale(scrollView!.maximumZoomScale / max_zoom_divider, animated: true)
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

	override var prefersHomeIndicatorAutoHidden: Bool {
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
